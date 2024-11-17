`timescale 1 ns / 1 ns

`include "defines.vh"

import SPARQ_PKG::*;

module PE #(
		parameter ID_V        = 0,
		parameter ID_H        = 0
	) (
		input  logic					clk,	

    input PE_A_Input     Aside_in_input,
    output PE_A_Input    Aside_in_output,

    input PE_B_Input     Bside_in_input,
    output PE_B_Input    Bside_in_output,

    input PE_C_Result    Cside_out_input0,
    input PE_C_Result    Cside_out_input1,
    output PE_C_Result   Cside_out_output0,    
    output PE_C_Result   Cside_out_output1,

    output PE_C_Inter_Req Cside_inter_req_output
    
	);
  
  typedef struct packed {
    logic [FLOAT_SIZE-1:0] stationary_register;
    logic loaded;

    PE_A_Input Aside_in_buf;
    PE_B_Input Bside_in_buf;

    logic Aside_in_to_next;
    logic Bside_in_to_next;

    logic [1:0] phase;
  } Registers;
  
  Registers reg_current,reg_next;
  
  logic multiplier_in_valid;
  logic multiplier_out_valid_next;
  logic multiplier_out_valid;
  logic [FLOAT_SIZE-1:0] multiplier_output_next;
  logic [FLOAT_SIZE-1:0] multiplier_output;

  fsize_multiplier multiplier (
    .aclk(clk),
    .s_axis_a_tvalid(multiplier_in_valid),
    .s_axis_a_tdata(reg_current.stationary_register),
    .s_axis_b_tvalid(multiplier_in_valid),
    .s_axis_b_tdata(Aside_in_input.data),
    .m_axis_result_tvalid(multiplier_out_valid_next),
    .m_axis_result_tdata(multiplier_output_next)
  );

  logic [FLOAT_SIZE-1:0] adder_output_next;
  logic [FLOAT_SIZE-1:0] adder_output;
  
  logic [FLOAT_SIZE-1:0] Cside_out_input0_data_buffered;

  logic adder_out_valid_next;
  logic adder_out_valid;
  fsize_adder adder (
    .aclk(clk),
    .s_axis_a_tvalid(multiplier_out_valid),
    .s_axis_a_tdata(multiplier_output),
    .s_axis_b_tvalid(multiplier_out_valid),
    .s_axis_b_tdata(Cside_out_input0_data_buffered),
    .m_axis_result_tvalid(adder_out_valid_next),
    .m_axis_result_tdata(adder_output_next)
  );

  logic [FLOAT_SIZE-1:0] cside_out_output1_data_delayed;
  FifoBuffer #(.DATA_SIZE(FLOAT_SIZE), .CYCLES(ADDER_DELAY+1) )    cside_out_output1_data_fifo (.clk(clk), .in(Cside_out_input1.data), .out(cside_out_output1_data_delayed));

  logic [PE_COMMAND_WIDTH-1:0] Aside_in_buf_command_delayed;
  logic Aside_in_buf_phase_delayed;
  logic [1:0] Aside_in_buf_id_delayed;
  logic [1:0] Aside_in_buf_skip_id_delayed;

  logic [1:0] meta_id;
  logic [1:0] meta_skip_id;
  FifoBuffer #(.DATA_SIZE(PE_COMMAND_WIDTH), .CYCLES(MULTIPLIER_DELAY-1) )    Aside_in_buf_command_fifo (.clk(clk), .in(Aside_in_input.command), .out(Aside_in_buf_command_delayed));
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(MULTIPLIER_DELAY-1) )    Aside_in_buf_phase_fifo (.clk(clk), .in(reg_current.phase[1]), .out(Aside_in_buf_phase_delayed));
  FifoBuffer #(.DATA_SIZE(2), .CYCLES(MULTIPLIER_DELAY-1) )    Aside_in_buf_id_fifo (.clk(clk), .in(meta_id), .out(Aside_in_buf_id_delayed));
  FifoBuffer #(.DATA_SIZE(2), .CYCLES(MULTIPLIER_DELAY-1) )    Aside_in_buf_skip_id_fifo (.clk(clk), .in(meta_skip_id), .out(Aside_in_buf_skip_id_delayed));
  
  logic Aside_in_buf_phase_delayed2;
  logic [1:0] Aside_in_buf_id_delayed2;
  logic [1:0] Aside_in_buf_skip_id_delayed2;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(ADDER_DELAY+3) )    Aside_in_buf_phase_fifo2 (.clk(clk), .in(Aside_in_buf_phase_delayed), .out(Aside_in_buf_phase_delayed2));
  FifoBuffer #(.DATA_SIZE(2), .CYCLES(ADDER_DELAY+3) )    Aside_in_buf_id_fifo2 (.clk(clk), .in(Aside_in_buf_id_delayed), .out(Aside_in_buf_id_delayed2));
  FifoBuffer #(.DATA_SIZE(2), .CYCLES(ADDER_DELAY+3) )    Aside_in_buf_skip_id_fifo2 (.clk(clk), .in(Aside_in_buf_skip_id_delayed), .out(Aside_in_buf_skip_id_delayed2));


  always_comb begin
    reg_next = reg_current;

    reg_next.Aside_in_buf = Aside_in_input;
    reg_next.Bside_in_buf = Bside_in_input;

    Cside_out_output0 = Cside_out_input0;    
    Cside_out_output1 = Cside_out_input1;    
    Cside_out_output0.command = PE_COMMAND_IDLE;
    Cside_out_output1.command = PE_COMMAND_IDLE;

    reg_next.Aside_in_to_next = 0;
    reg_next.Bside_in_to_next = 0;
    
    if(Bside_in_input.command == PE_COMMAND_RESET) begin
      reg_next.loaded = 0;
      reg_next.stationary_register = 0;
      reg_next.Bside_in_to_next = 1;      
      reg_next.phase = 0;      
    end

    if(Bside_in_input.command == PE_COMMAND_LOAD) begin      
      if(reg_current.loaded) begin
        reg_next.Bside_in_to_next = 1;
      end
      else begin
        reg_next.loaded = 1;
        reg_next.stationary_register = Bside_in_input.data;        
      end
    end  

    multiplier_in_valid = 1'b0;
    if(Aside_in_input.command == PE_COMMAND_NORMAL) begin
      multiplier_in_valid = 1;            
      reg_next.Aside_in_to_next = 1;     

      reg_next.phase = reg_current.phase+1;
    end
   
    ///outputs    
    Aside_in_output = reg_current.Aside_in_buf;
    if(!reg_current.Aside_in_to_next)
      Aside_in_output.command = PE_COMMAND_IDLE;
    
    Bside_in_output = reg_current.Bside_in_buf;
    if(!reg_current.Bside_in_to_next)
      Bside_in_output.command = PE_COMMAND_IDLE;

    Cside_out_output0.data = adder_output;
    Cside_out_output1.data = cside_out_output1_data_delayed;
    if(adder_out_valid) begin
      Cside_out_output0.command = PE_COMMAND_NORMAL;
      Cside_out_output1.command = PE_COMMAND_NORMAL;
    end

    Cside_out_output0.phase = Aside_in_buf_phase_delayed2;
    Cside_out_output1.phase = Aside_in_buf_phase_delayed2;
    Cside_out_output0.id = Aside_in_buf_id_delayed2;
    Cside_out_output1.id = Aside_in_buf_skip_id_delayed2;

    Cside_inter_req_output.phase = Aside_in_buf_phase_delayed;
    Cside_inter_req_output.id = Aside_in_buf_id_delayed;
    Cside_inter_req_output.skip_id = Aside_in_buf_skip_id_delayed;
    Cside_inter_req_output.valid = 1'b0;
    if(Aside_in_buf_command_delayed == PE_COMMAND_NORMAL) begin
      Cside_inter_req_output.valid = 1'b1;
    end

    case({Aside_in_input.meta,reg_current.phase[0]})
      0: begin  meta_id = 0; meta_skip_id = 2;  end
      1: begin  meta_id = 1; meta_skip_id = 3;  end
      2: begin  meta_id = 0; meta_skip_id = 1;  end
      3: begin  meta_id = 2; meta_skip_id = 3;  end
      4: begin  meta_id = 0; meta_skip_id = 1;  end
      5: begin  meta_id = 3; meta_skip_id = 2;  end
      6: begin  meta_id = 1; meta_skip_id = 0;  end
      7: begin  meta_id = 2; meta_skip_id = 3;  end
      8: begin  meta_id = 1; meta_skip_id = 0;  end
      9: begin  meta_id = 3; meta_skip_id = 2;  end
      10: begin  meta_id = 2; meta_skip_id = 0;  end
      11: begin  meta_id = 3; meta_skip_id = 1;  end
      default: begin  meta_id = 0; meta_skip_id = 2;  end
    endcase

  end
        
    
  always @ (posedge clk) begin
    reg_current <= reg_next;

    multiplier_output <= multiplier_output_next;
    multiplier_out_valid <= multiplier_out_valid_next;
    
    adder_output <= adder_output_next;
    adder_out_valid <= adder_out_valid_next;

    Cside_out_input0_data_buffered <= Cside_out_input0.data;
	end

endmodule
