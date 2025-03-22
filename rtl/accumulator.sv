`timescale 1 ns / 1 ns 

`include "defines.vh"
import SPARQ_PKG::*;



module accumulator_array #(
		parameter NUM_DATA = ARRAY_DIMENSION
	) (	
    input logic	                        clk,	
    input logic [ACCUM_COMMAND_WIDTH-1:0]  command_array [0:NUM_DATA-1],
    input logic [FLOAT_SIZE*NUM_DATA-1:0]    in_A,
    input logic [FLOAT_SIZE*NUM_DATA-1:0]    in_B,
    output logic [FLOAT_SIZE*NUM_DATA-1:0]   out    
  );
  
  genvar gi;
  generate
    for(gi = 0; gi < NUM_DATA; gi ++) begin : gen_accum
      logic[FLOAT_SIZE-1:0] in_a;
      logic[FLOAT_SIZE-1:0] in_a_reg;
      logic[FLOAT_SIZE-1:0] in_b;
      logic[FLOAT_SIZE-1:0] in_b_reg;
      logic[FLOAT_SIZE-1:0] out_comb;
      logic[FLOAT_SIZE-1:0] out_reg;
      logic valid_in;
      logic valid_out;

      always @( posedge clk ) begin
        in_a_reg <= in_a;
        in_b_reg <= in_b;
        out_reg <= out_comb;
      end 

      always_comb begin
        in_a = in_A[FLOAT_SIZE*gi +: FLOAT_SIZE];
        in_b = in_B[FLOAT_SIZE*gi +: FLOAT_SIZE];
        if(command_array[gi] == ACCUMULATOR_COMMAND_NEW_ACCUM) in_b = 0;

        valid_in = 0;
        if(command_array[gi] == ACCUMULATOR_COMMAND_ACCUM || command_array[gi] == ACCUMULATOR_COMMAND_NEW_ACCUM ) 
          valid_in = 1;
      end

      fsize_adder adder (
        .aclk(clk),
        .s_axis_a_tvalid(valid_in),
        .s_axis_a_tdata(in_a_reg),
        .s_axis_b_tvalid(valid_in),
        .s_axis_b_tdata(in_b_reg),
        .m_axis_result_tvalid(valid_out),
        .m_axis_result_tdata(out_comb)
      );

      assign out[FLOAT_SIZE*gi +: FLOAT_SIZE] = out_reg;
    end
  endgenerate
endmodule
