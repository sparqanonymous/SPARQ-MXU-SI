`timescale 1 ns / 1 ns

`include "defines.vh"
import SPARQ_PKG::*;

(* use_dsp = "no" *) module GEMM_Controller  (
    input rstn,
    input clk,

    input CommandDataPort commanddataport,    
    
    output logic[PE_COMMAND_WIDTH-1:0] Aside_command,
    output logic[PE_COMMAND_WIDTH-1:0] Bside_command,
    output PE_C_Inter_Req Cside_inter_req,
    output logic[ACCUM_COMMAND_WIDTH-1:0] accumulator_command,

    output logic[$clog2(IN_BUFFER_SIZE)-1:0]  buffer_A_raddr,
    output logic[$clog2(IN_BUFFER_SIZE)-1:0]  buffer_B_raddr,
        
    output logic[$clog2(OUT_BUFFER_SIZE)-1:0] accumulator_raddr,
    output logic[$clog2(OUT_BUFFER_SIZE)-1:0] accumulator_waddr,
    output logic                              accumulator_wren,

    input logic[PE_COMMAND_WIDTH-1:0] Cside_out_command,
    input logic[PE_COMMAND_WIDTH-1:0] pre_Cside_out_command,
    input logic[PE_COMMAND_WIDTH-1:0] Aside_last_in_command,

    output logic pein_in_progress,
    output logic accum_in_progress    
);
  (* keep = "true" , max_fanout = 32 *) logic rstn_b;
  
  typedef struct packed{
    CommandDataPort commanddataport;

    logic [COMMAND_WIDTH-1:0] command;        
    logic [FSIZE-1:0]  command_data0;
    logic [FSIZE-1:0]  command_data1;

    logic [$clog2(IN_BUFFER_SIZE)-1:0] A_in_offset;  
    logic [$clog2(OUT_BUFFER_SIZE)-1:0] C_out_offset;
    logic [$clog2(ARRAY_DIMENSION)-1:0] B_load_offset;

    logic [$clog2(IN_BUFFER_SIZE)-1:0] A_base_addr;
    logic [$clog2(IN_BUFFER_SIZE)-1:0] B_base_addr;
    logic [$clog2(OUT_BUFFER_SIZE)-1:0] C_base_addr;

    logic [$clog2(IN_BUFFER_SIZE)-1:0] dim1_size;

    logic reset_accumulator;

    logic pe_reset;

    logic pein_state;
    logic accum_state;    
    
    logic B_loaded;

    PE_C_Inter_Req Cside_inter_req;

    logic [PE_COMMAND_WIDTH-1:0] pre_Cside_out_command;

    logic[1:0] accum_in_progress_mode;
  } Registers;
    
  Registers reg_current,reg_next;

  logic[PE_COMMAND_WIDTH-1:0] Aside_command_fifo_in;
  logic[PE_COMMAND_WIDTH-1:0] Bside_command_fifo_in;
  logic[ACCUM_COMMAND_WIDTH-1:0] accumulator_command_fifo_in;
  FifoBuffer #(.DATA_SIZE(PE_COMMAND_WIDTH), .CYCLES(BUFFER_READ_LATENCY+1) )  Aside_command_delay (.clk(clk), .in(Aside_command_fifo_in), .out(Aside_command));
  FifoBuffer #(.DATA_SIZE(PE_COMMAND_WIDTH), .CYCLES(BUFFER_READ_LATENCY+1) )  Bside_command_delay (.clk(clk), .in(Bside_command_fifo_in), .out(Bside_command));
  FifoBuffer #(.DATA_SIZE(ACCUM_COMMAND_WIDTH), .CYCLES(1) )  accumulator_command_delay (.clk(clk), .in(accumulator_command_fifo_in), .out(accumulator_command));
  
  logic[$clog2(OUT_BUFFER_SIZE)-1:0] accumulator_waddr_fifo_in;
  logic accumulator_wren_fifo_in;
  FifoBuffer #(.DATA_SIZE($clog2(OUT_BUFFER_SIZE)), .CYCLES(ARRAY_DIMENSION+ADDER_DELAY+3) )  accumulator_waddr_delay (.clk(clk), .in(accumulator_waddr_fifo_in), .out(accumulator_waddr));
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(ARRAY_DIMENSION+ADDER_DELAY+3) )    accumulator_wren_delay (.clk(clk), .in(accumulator_wren_fifo_in), .out(accumulator_wren));
  
  logic[$clog2(IN_BUFFER_SIZE)-1:0]  buffer_A_raddr_fifo_in;
  logic[$clog2(IN_BUFFER_SIZE)-1:0]  buffer_B_raddr_fifo_in;
  logic[$clog2(OUT_BUFFER_SIZE)-1:0]  accumulator_raddr_fifo_in;
  FifoBuffer #(.DATA_SIZE($clog2(IN_BUFFER_SIZE)), .CYCLES(1) )   buffer_A_raddr_delay (.clk(clk), .in(buffer_A_raddr_fifo_in), .out(buffer_A_raddr));
  FifoBuffer #(.DATA_SIZE($clog2(IN_BUFFER_SIZE)), .CYCLES(1) )      buffer_B_raddr_dealy (.clk(clk), .in(buffer_B_raddr_fifo_in), .out(buffer_B_raddr));
  FifoBuffer #(.DATA_SIZE($clog2(OUT_BUFFER_SIZE)), .CYCLES(ARRAY_DIMENSION-BUFFER_READ_LATENCY+1) )    accumulator_raddr_dealy (.clk(clk), .in(accumulator_raddr_fifo_in), .out(accumulator_raddr));

  logic pein_in_progress_fifo_in;
  logic accum_in_progress_fifo_in;
  logic accum_in_progress_delayed;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(1) )    pein_in_progress_delay (.clk(clk), .in(pein_in_progress_fifo_in), .out(pein_in_progress));
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(ARRAY_DIMENSION+ADDER_DELAY+3) )    accum_in_progress_delay (.clk(clk), .in(accum_in_progress_fifo_in), .out(accum_in_progress_delayed));
  
  logic Cside_inter_req_valid_in;
  logic Cside_inter_req_valid_delayed;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(MULTIPLIER_DELAY+1+ADDER_DELAY+1) )    Cside_inter_req_valid_fifo (.clk(clk), .in(Cside_inter_req_valid_in), .out(Cside_inter_req_valid_delayed));
  logic [1:0] Cside_inter_req_id_delayed;
  FifoBuffer #(.DATA_SIZE(2), .CYCLES(MULTIPLIER_DELAY+1+ADDER_DELAY+1) )    Cside_inter_req_id_fifo (.clk(clk), .in(reg_current.Cside_inter_req.id), .out(Cside_inter_req_id_delayed));
  logic [1:0] Cside_inter_req_skip_id_delayed;
  FifoBuffer #(.DATA_SIZE(2), .CYCLES(MULTIPLIER_DELAY+1+ADDER_DELAY+1) )    Cside_inter_req_skip_id_fifo (.clk(clk), .in(reg_current.Cside_inter_req.skip_id), .out(Cside_inter_req_skip_id_delayed));
  logic Cside_inter_req_phase_delayed;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(MULTIPLIER_DELAY+1+ADDER_DELAY+1) )    Cside_inter_req_phase_fifo (.clk(clk), .in(reg_current.Cside_inter_req.phase), .out(Cside_inter_req_phase_delayed));

  always_comb begin
    reg_next = reg_current;
  
    pein_in_progress_fifo_in = 0;
    accum_in_progress_fifo_in = 0;

    Aside_command_fifo_in = 0;
    Bside_command_fifo_in = 0;
    accumulator_command_fifo_in = 0;

    accumulator_waddr_fifo_in = 0;
    accumulator_wren_fifo_in = 0;
    
    reg_next.command = 0;
    if(commanddataport.valid) begin
      reg_next.command = commanddataport.command;       
      reg_next.command_data0 = commanddataport.data0;       
      reg_next.command_data1 = commanddataport.data1;       
    end
   
    if(reg_current.command == COMMAND_PE_RESET) begin
      Bside_command_fifo_in = PE_COMMAND_RESET;
    end
    if( reg_current.command == COMMAND_GEMM0) begin 
      reg_next.A_base_addr = reg_current.command_data0;              
      reg_next.B_base_addr = reg_current.command_data1;              
    end    
    if( reg_current.command == COMMAND_GEMM1) begin 
      reg_next.C_base_addr = reg_current.command_data0;              
      reg_next.reset_accumulator = reg_current.command_data1;              
    end    
    if( reg_current.command == COMMAND_GEMM2) begin 
      reg_next.dim1_size= reg_current.command_data0;              

      reg_next.pein_state = STATE_WORKING;
      reg_next.accum_state = STATE_WORKING;
      reg_next.accum_in_progress_mode = 1;

      reg_next.B_load_offset = 0;
      reg_next.A_in_offset = 0;
      reg_next.C_out_offset = 0;  

      reg_next.pe_reset = 1;

      reg_next.Cside_inter_req.valid = 0;
      reg_next.Cside_inter_req.id = 0;
      reg_next.Cside_inter_req.skip_id = 1;
      reg_next.Cside_inter_req.phase = 0;
    end    


    buffer_A_raddr_fifo_in = 0;
    buffer_B_raddr_fifo_in = 0;
    if(reg_current.pein_state == STATE_WORKING) begin
      pein_in_progress_fifo_in = 1;
      if( reg_current.pe_reset ) begin
        reg_next.pe_reset = 0;
        reg_next.B_loaded = 0;
        Bside_command_fifo_in = PE_COMMAND_RESET;
      end
      else if (reg_current.B_loaded == 0) begin
        Bside_command_fifo_in = PE_COMMAND_LOAD;

        reg_next.B_load_offset = reg_current.B_load_offset + 1;
        if(reg_current.B_load_offset == ARRAY_DIMENSION-1) begin 
          reg_next.B_load_offset = 0;          
          reg_next.B_loaded = 1;          
        end        

        buffer_B_raddr_fifo_in = reg_current.B_base_addr + 
                reg_current.B_load_offset 
                ;     
      end
      else begin
        Aside_command_fifo_in = PE_COMMAND_NORMAL;

        reg_next.A_in_offset = reg_current.A_in_offset + 1;

        if(reg_current.A_in_offset == reg_current.dim1_size/2 -1) begin 
          reg_next.A_in_offset = 0;
          reg_next.pein_state = STATE_IDLE;                         
        end

        buffer_A_raddr_fifo_in = 
                reg_current.A_base_addr + 
                reg_current.A_in_offset
                ;
      end
    end

    reg_next.pre_Cside_out_command = pre_Cside_out_command;

    accumulator_raddr_fifo_in = 0;
    if(reg_current.accum_state == STATE_WORKING) begin
      accum_in_progress_fifo_in = 1;
      if(reg_current.pre_Cside_out_command == PE_COMMAND_NORMAL) begin        

        if(reg_current.reset_accumulator ) 
          accumulator_command_fifo_in = ACCUMULATOR_COMMAND_NEW_ACCUM;
        else
          accumulator_command_fifo_in = ACCUMULATOR_COMMAND_ACCUM;

        reg_next.C_out_offset = reg_current.C_out_offset + 2;

        if(reg_current.C_out_offset == reg_current.dim1_size -2) begin 
          reg_next.C_out_offset = 0;
          reg_next.accum_state = STATE_IDLE;                         
        end
            
        accumulator_raddr_fifo_in = 
                reg_current.C_base_addr + 
                reg_current.C_out_offset
                ;

        accumulator_waddr_fifo_in = accumulator_raddr_fifo_in;
        accumulator_wren_fifo_in = 1;
      end
    end
    if(reg_current.accum_in_progress_mode==1) begin
      if (accum_in_progress_delayed == 1) begin
        reg_next.accum_in_progress_mode = 2;
      end
    end
    if(reg_current.accum_in_progress_mode==2) begin
      if (accum_in_progress_delayed == 0) begin
        reg_next.accum_in_progress_mode = 0;
      end
    end
    accum_in_progress = reg_current.accum_in_progress_mode >= 1 ? 1:0;


    Cside_inter_req.valid   = Cside_inter_req_valid_delayed;
    Cside_inter_req.id      = Cside_inter_req_id_delayed;
    Cside_inter_req.skip_id = Cside_inter_req_skip_id_delayed;
    Cside_inter_req.phase   = Cside_inter_req_phase_delayed;

    Cside_inter_req_valid_in = 1'b0;
    if(Aside_last_in_command == PE_COMMAND_NORMAL) begin        
      Cside_inter_req_valid_in = 1'b1;

      if(reg_current.Cside_inter_req.id == 0) begin
        reg_next.Cside_inter_req.id = 2;
        reg_next.Cside_inter_req.skip_id = 3;
      end
      else begin
        reg_next.Cside_inter_req.id = 0;
        reg_next.Cside_inter_req.skip_id = 1;
        reg_next.Cside_inter_req.phase = ~reg_current.Cside_inter_req.phase;
      end
    end


    if(rstn_b == 0) begin
      reg_next.commanddataport = '{default:'0};
      reg_next.pein_state = 0;
      reg_next.accum_state = 0;
      reg_next.accum_in_progress_mode = 0;
    end
  end
    
	always @( posedge clk ) begin
    rstn_b <= rstn;
    reg_current <= reg_next;
	end 
  
endmodule
