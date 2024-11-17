`timescale 1 ns / 1 ns

`include "defines.vh"


import SPARQ_PKG::*;


module pe_in_pipe #(
		parameter DATA_SIZE     = FLOAT_SIZE,
		parameter integer CYCLES        = 2
	) (	
	  input logic	                        clk,	
    input logic   [DATA_SIZE-1:0]       in_data,
    output logic  [DATA_SIZE-1:0]       out_data
  );

  typedef struct packed {   
    logic [CYCLES-1:0][DATA_SIZE-1:0] data;
  } Registers;
  
  Registers reg_current,reg_next;
  
  always_comb begin
    reg_next = reg_current;

    reg_next.data[0] = in_data;

    for(int i = 0; i < CYCLES-1; i ++) begin
      reg_next.data[i+1] = reg_current.data[i];
    end
  end

  assign out_data = reg_current.data[CYCLES-1];
            
  always @ (posedge clk) begin
    reg_current <= reg_next;
	end
endmodule

module pe_out_pipe #(
		parameter integer CYCLES        = 2
	) (	
	  input logic	                        clk,	
    input PE_C_Result                   in_data,
    output PE_C_Result                  out_data
  );

  typedef struct packed {   
    PE_C_Result [CYCLES-1:0] data;
  } Registers;
  
  Registers reg_current,reg_next;
  
  always_comb begin
    reg_next = reg_current;

    reg_next.data[0] = in_data;
    
    for(int i = 0; i < CYCLES-1; i++) begin
      reg_next.data[i+1] = reg_current.data[i];
    end    
  end

  assign out_data = reg_current.data[CYCLES-1];
            
  always @ (posedge clk) begin
    reg_current <= reg_next;
	end
endmodule



module data_skew_in_A #(
		parameter NUM_DATA     = ARRAY_DIMENSION,
		parameter SKEW_DEGREE  = 1,
		parameter DATA_SIZE    = FLOAT_SIZE
	) (	
	  input logic			                      clk,	
    input logic[PE_COMMAND_WIDTH-1:0]     command_in,
    input logic[NUM_DATA*DATA_SIZE-1:0]   flat_data,
    input logic[NUM_DATA*META_SIZE-1:0]   flat_meta_data,
    output PE_A_Input pe_in [0:NUM_DATA-1] 
  );
  
  typedef struct packed {   
    logic [NUM_DATA*SKEW_DEGREE-1:0][PE_COMMAND_WIDTH-1:0] command;
  } Registers;
  
  Registers reg_current,reg_next;

  genvar gi;
  generate 
    for(gi = 0; gi < NUM_DATA; gi++) begin : pe_in_pipe_gen
      logic[DATA_SIZE-1:0] pe_in_data;
      logic[META_SIZE-1:0] pe_in_meta_data;

      pe_in_pipe #(.CYCLES(gi*SKEW_DEGREE+1), .DATA_SIZE(DATA_SIZE)) pe_in_pipe(
        .clk(clk),
        .in_data(flat_data[DATA_SIZE*gi +: DATA_SIZE]),
        .out_data(pe_in_data)
      );

      pe_in_pipe #(.CYCLES(gi*SKEW_DEGREE+1), .DATA_SIZE(META_SIZE)) pe_in_pipe_meta (
        .clk(clk),
        .in_data(flat_meta_data[META_SIZE*gi +: META_SIZE]),
        .out_data(pe_in_meta_data)
      );

      always_comb begin
        pe_in[gi].command = reg_current.command[gi*SKEW_DEGREE];
        pe_in[gi].data = pe_in_data;
        pe_in[gi].meta = pe_in_meta_data;
      end
    end
  endgenerate

  always_comb begin
    reg_next = reg_current;

    reg_next.command[0] = command_in;
    for(int i = 0; i < NUM_DATA*SKEW_DEGREE-1; i ++) begin
      reg_next.command[i+1] = reg_current.command[i];
    end
  end
            
  always @ (posedge clk) begin
    reg_current <= reg_next;
	end

endmodule

module data_skew_in_B #(
		parameter NUM_DATA     = ARRAY_DIMENSION,
		parameter SKEW_DEGREE  = 1,
		parameter DATA_SIZE    = FLOAT_SIZE
	) (	
	  input logic			                      clk,	
    input logic[PE_COMMAND_WIDTH-1:0]     command_in,
    input logic[NUM_DATA*DATA_SIZE-1:0]   flat_data,
    output PE_B_Input pe_in [0:NUM_DATA-1] 
  );
  
  typedef struct packed {   
    logic [NUM_DATA*SKEW_DEGREE-1:0][PE_COMMAND_WIDTH-1:0] command;
  } Registers;
  
  Registers reg_current,reg_next;

  genvar gi;
  generate 
    for(gi = 0; gi < NUM_DATA; gi++) begin : pe_in_pipe_gen
      logic[DATA_SIZE-1:0] pe_in_data;

      pe_in_pipe #(.CYCLES(gi*SKEW_DEGREE+1),.DATA_SIZE(DATA_SIZE)) pe_in_pipe(
        .clk(clk),
        .in_data(flat_data[DATA_SIZE*gi +: DATA_SIZE]),
        .out_data(pe_in_data)
      );

      always_comb begin
        pe_in[gi].command = reg_current.command[gi*SKEW_DEGREE];
        pe_in[gi].data = pe_in_data;
      end
    end
  endgenerate

  always_comb begin
    reg_next = reg_current;

    reg_next.command[0] = command_in;
    for(int i = 0; i < NUM_DATA*SKEW_DEGREE-1; i ++) begin
      reg_next.command[i+1] = reg_current.command[i];
    end
  end
            
  always @ (posedge clk) begin
    reg_current <= reg_next;
	end

endmodule

module data_skew_C_Inter_Req_in #(
		parameter NUM_DATA     = ARRAY_DIMENSION
	) (	
	  input logic			                     clk,	
    input PE_C_Inter_Req                    req_in,
    output PE_C_Inter_Req                   req_out [0:NUM_DATA-1] 
  );
  
  typedef struct packed {   
    PE_C_Inter_Req [NUM_DATA-1:0] req;
  } Registers;
  
  Registers reg_current,reg_next;

  always_comb begin
    for(int i = 0; i < NUM_DATA; i++) begin
      req_out[i] = reg_current.req[i];
    end
  end

  always_comb begin
    reg_next = reg_current;

    reg_next.req[0] = req_in;
    for(int i = 0; i < NUM_DATA-1; i ++) begin
      reg_next.req[i+1] = reg_current.req[i];
    end
  end
            
  always @ (posedge clk) begin
    reg_current <= reg_next;
	end

endmodule


module data_skew_out #(
		parameter NUM_DATA        = ARRAY_DIMENSION,
    parameter CYCLE_OFFSET    = 0
	) (	
	  input  logic			                  clk,	    
    input PE_C_Result                   pe_out[0:NUM_DATA-1] ,
    input logic[ACCUM_COMMAND_WIDTH-1:0] accum_command_in,
    output logic[NUM_DATA*FLOAT_SIZE-1:0]    flat_data,
    output logic[PE_COMMAND_WIDTH-1:0]  command_out,
    output logic[PE_COMMAND_WIDTH-1:0]  pre_command_out,
    output logic[ACCUM_COMMAND_WIDTH-1:0] accum_commands_out[0:NUM_DATA-1]
  );
  
  logic [NUM_DATA-1:0][PE_COMMAND_WIDTH-1:0]  out_command; // other than out_command[0], the others are for debugging only?

  typedef struct packed {   
    logic [NUM_DATA-1:0][ACCUM_COMMAND_WIDTH-1:0] accum_command;
  } Registers;
  
  Registers reg_current,reg_next;

  genvar gi;
  generate 
    for(gi = 0; gi < NUM_DATA; gi++) begin : pe_out_pipe_gen
      PE_C_Result out_data;
      
      pe_out_pipe #(.CYCLES(NUM_DATA+2-gi-CYCLE_OFFSET)) pe_out_pipe(
        .clk(clk),
        .in_data(pe_out[gi]),
        .out_data(out_data)
      );

      assign out_command[gi] = out_data.command;
      assign flat_data[FLOAT_SIZE*gi +: FLOAT_SIZE] = out_data.data;

      if(gi != NUM_DATA-1)
        FifoBuffer #(.DATA_SIZE(ACCUM_COMMAND_WIDTH),.CYCLES(NUM_DATA-1-gi)) accum_command_fifo (.clk(clk),.in(reg_current.accum_command[gi]),.out(accum_commands_out[gi]));
      else
        assign accum_commands_out[gi] = reg_current.accum_command[gi];
    end
  endgenerate

  assign command_out = out_command[0];
  assign pre_command_out = pe_out[0].command;

  always_comb begin
    reg_next = reg_current;

    reg_next.accum_command[0] = accum_command_in;
    for(int i = 0; i < NUM_DATA-1; i ++) begin
      reg_next.accum_command[i+1] = reg_current.accum_command[i];
    end
  end
            
  always @ (posedge clk) begin
    reg_current <= reg_next;
	end


endmodule