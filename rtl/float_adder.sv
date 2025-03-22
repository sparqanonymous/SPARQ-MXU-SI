`timescale 1 ns / 1 ns 

`include "defines.vh"

import SPARQ_PKG::*;

module count_leading_zeros_add(
    input [MANT_SIZE+1:0] vector,
    output reg [$clog2(MANT_SIZE+1)-1:0] num_zeros
);
  generate
    if (MANT_SIZE == 23) begin
      always @(*) begin
          casez(vector)
              25'b1????????????????????????: num_zeros = 0;
              25'b01???????????????????????: num_zeros = 1;
              25'b001??????????????????????: num_zeros = 2;
              25'b0001?????????????????????: num_zeros = 3;
              25'b00001????????????????????: num_zeros = 4;
              25'b000001???????????????????: num_zeros = 5;
              25'b0000001??????????????????: num_zeros = 6;
              25'b00000001?????????????????: num_zeros = 7;
              25'b000000001????????????????: num_zeros = 8;
              25'b0000000001???????????????: num_zeros = 9;
              25'b00000000001??????????????: num_zeros = 10;
              25'b000000000001?????????????: num_zeros = 11;
              25'b0000000000001????????????: num_zeros = 12;
              25'b00000000000001???????????: num_zeros = 13;
              25'b000000000000001??????????: num_zeros = 14;
              25'b0000000000000001?????????: num_zeros = 15;
              25'b00000000000000001????????: num_zeros = 16;
              25'b000000000000000001???????: num_zeros = 17;
              25'b0000000000000000001??????: num_zeros = 18;
              25'b00000000000000000001?????: num_zeros = 19;
              25'b000000000000000000001????: num_zeros = 20;
              25'b0000000000000000000001???: num_zeros = 21;
              25'b00000000000000000000001??: num_zeros = 22;
              25'b000000000000000000000001?: num_zeros = 23;
              25'b0000000000000000000000001: num_zeros = 24;
              25'b0000000000000000000000000: num_zeros = 25;
              default: num_zeros = 25;
          endcase
      end
    end
    else if (MANT_SIZE == 10) begin
      always @(*) begin
          casez(vector)
              12'b1???????????: num_zeros = 0;
              12'b01??????????: num_zeros = 1;
              12'b001?????????: num_zeros = 2;
              12'b0001????????: num_zeros = 3;
              12'b00001???????: num_zeros = 4;
              12'b000001??????: num_zeros = 5;
              12'b0000001?????: num_zeros = 6;
              12'b00000001????: num_zeros = 7;
              12'b000000001???: num_zeros = 8;
              12'b0000000001??: num_zeros = 9;
              12'b00000000001?: num_zeros = 10;
              12'b000000000001: num_zeros = 11;
              12'b000000000000: num_zeros = 12;
              default: num_zeros = 12;
          endcase
      end
    end
    else if (MANT_SIZE == 7) begin
      always @(*) begin
          casez(vector)
              9'b1????????: num_zeros = 0;
              9'b01???????: num_zeros = 1;
              9'b001??????: num_zeros = 2;
              9'b0001?????: num_zeros = 3;
              9'b00001????: num_zeros = 4;
              9'b000001???: num_zeros = 5;
              9'b0000001??: num_zeros = 6;
              9'b00000001?: num_zeros = 7;
              9'b000000001: num_zeros = 8;
              9'b000000000: num_zeros = 9;
              default: num_zeros = 9;
          endcase
      end
    end
  endgenerate
endmodule



module float_adder (
  input [FLOAT_SIZE-1:0] in_A,
  input [FLOAT_SIZE-1:0] in_B,
  output reg [FLOAT_SIZE-1:0] out
);

  logic sign_A, sign_B;
  logic [EXP_SIZE-1:0] exp_A, exp_B;
  logic signed [EXP_SIZE:0] exponent_A, exponent_B;
  logic [MANT_SIZE-1:0] mant_A, mant_B;
  
  logic [MANT_SIZE:0] frac_A, frac_B;
  
  logic is_A_larger;
  logic [EXP_SIZE-1:0] exp_diff;  

  logic [MANT_SIZE+1:0] frac_add;
  
  //hard-coded length!
  /* verilator lint_off UNOPTFLAT */
  logic [$clog2(MANT_SIZE+1)-1:0] frac_add_lzc;
  /* verilator lint_on UNOPTFLAT */
  count_leading_zeros_add count_leading_zeros_add(frac_add,frac_add_lzc);

  logic signed [EXP_SIZE:0] res_exponent;

  logic [MANT_SIZE+1:0] res_frac;
  logic [EXP_SIZE-1:0] res_exp;
  logic [MANT_SIZE-1:0] res_mant;
  logic res_sign;

  logic signed [EXP_SIZE-1:0] shift_amount;

  always_comb begin
    sign_A = in_A[EXP_SIZE+MANT_SIZE];
    sign_B = in_B[EXP_SIZE+MANT_SIZE];
    exp_A = in_A[EXP_SIZE+MANT_SIZE-1:MANT_SIZE];
    exp_B = in_B[EXP_SIZE+MANT_SIZE-1:MANT_SIZE];
    mant_A = in_A[MANT_SIZE-1:0];
    mant_B = in_B[MANT_SIZE-1:0];

    if (exp_A == '0) begin  //subnormal case
      frac_A = {1'b0,mant_A};
      exponent_A = - (BIAS-1);
    end
    else begin  //normal case
      frac_A = {1'b1,mant_A};
      exponent_A = exp_A - BIAS;
    end

    if (exp_B == '0) begin  //subnormal case
      frac_B = {1'b0,mant_B};
      exponent_B = - (BIAS-1);
    end
    else begin  //normal case
      frac_B = {1'b1,mant_B};
      exponent_B = exp_B - BIAS;
    end

    //Determine which input is larger
    if( exponent_A > exponent_B ) begin
      is_A_larger = 1;
    end
    else if( exponent_A < exponent_B ) begin
      is_A_larger = 0;
    end
    else begin
      if( frac_A >= frac_B ) begin
        is_A_larger = 1;
      end
      else begin
        is_A_larger = 0;
      end
    end

    if(is_A_larger) begin
      exp_diff = exponent_A - exponent_B;
      frac_B = frac_B >> exp_diff;
    end
    else begin
      exp_diff = exponent_B - exponent_A;
      frac_A = frac_A >> exp_diff;
    end

    if (sign_A == sign_B) begin
      res_sign = sign_A;
      frac_add = frac_A + frac_B; //main adder
    end
    else begin
      if(is_A_larger) begin
        res_sign = sign_A;
        frac_add = frac_A - frac_B; //main adder
      end
      else begin
        res_sign = sign_B;
        frac_add = frac_B - frac_A; //main adder
      end
    end

    if (frac_add_lzc == MANT_SIZE+2) begin  // frac_add is 0. i.e., output is 0.0
      res_exp = '0;
      shift_amount = 0;
    end
    else begin
      if (is_A_larger) begin
        res_exponent = exponent_A - (frac_add_lzc -1);
      end
      else begin
        res_exponent = exponent_B - (frac_add_lzc -1);
      end

      if ( res_exponent >= -(BIAS -1) ) begin //normal case
        res_exp = res_exponent + BIAS;
        shift_amount = frac_add_lzc;            
      end
      else begin  //subnormal case
        res_exp = 0;
        shift_amount = res_exponent + (BIAS-1) +  frac_add_lzc;            
      end
    end

    if (shift_amount >= 0)
      res_frac = frac_add << shift_amount;
    else
      res_frac = frac_add >> -shift_amount;

    res_mant = res_frac[MANT_SIZE:1];

   

    out = {res_sign,res_exp,res_mant};
  end
endmodule

module fsize_adder (		
    input logic	                  aclk,	
    input logic                   s_axis_a_tvalid,
    input logic [FLOAT_SIZE-1:0]  s_axis_a_tdata,
    input logic                   s_axis_b_tvalid,
    input logic [FLOAT_SIZE-1:0]  s_axis_b_tdata,
    output logic                  m_axis_result_tvalid,
    output logic [FLOAT_SIZE-1:0] m_axis_result_tdata
  );

  logic [FLOAT_SIZE-1:0] adder_result;

  float_adder float_adder(s_axis_a_tdata,s_axis_b_tdata,adder_result);

  FifoBuffer #(.DATA_SIZE(1), .CYCLES(ADDER_DELAY)) valid_fifo (.clk(aclk), .in(s_axis_a_tvalid), .out(m_axis_result_tvalid) );
  FifoBuffer #(.DATA_SIZE(FLOAT_SIZE), .CYCLES(ADDER_DELAY)) out_fifo (.clk(aclk), .in(adder_result), .out(m_axis_result_tdata) );
endmodule