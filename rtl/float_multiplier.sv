`timescale 1 ns / 1 ns

`include "defines.vh"


import SPARQ_PKG::*;

module count_leading_zeros( 
    input [(MANT_SIZE+1+INT_SIZE)-1:0] vector,
    output reg [$clog2(MANT_SIZE+1+INT_SIZE)-1:0] num_zeros
);
  generate
    if (MANT_SIZE == 10 && INT_SIZE == 4) begin
      always @(*) begin
        casez(vector)
          15'b1??????????????: num_zeros = 0;
          15'b01?????????????: num_zeros = 1;
          15'b001????????????: num_zeros = 2;
          15'b0001???????????: num_zeros = 3;
          15'b00001??????????: num_zeros = 4;
          15'b000001?????????: num_zeros = 5;
          15'b0000001????????: num_zeros = 6;
          15'b00000001???????: num_zeros = 7;
          15'b000000001??????: num_zeros = 8;
          15'b0000000001?????: num_zeros = 9;
          15'b00000000001????: num_zeros = 10;
          15'b000000000001???: num_zeros = 11;
          15'b0000000000001??: num_zeros = 12;
          15'b00000000000001?: num_zeros = 13;
          15'b000000000000001: num_zeros = 14;
          15'b000000000000000: num_zeros = 15;
          default: num_zeros = 15;
        endcase
      end
    end      
    else if (MANT_SIZE == 7 && INT_SIZE == 4) begin
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
  endgenerate
endmodule

module float_multiplier (
  input [FLOAT_SIZE-1:0] in_A,
  input [INT_SIZE-1:0] in_B,
  output reg [FLOAT_SIZE-1:0] out
);

  logic sign_A, sign_B;
  logic [EXP_SIZE-1:0] exp_A;
  logic signed [EXP_SIZE+1:0] exponent_A;
  logic [MANT_SIZE-1:0] mant_A;
  
  logic [MANT_SIZE:0] frac_A;
  logic [(MANT_SIZE+1+INT_SIZE)-1:0] frac_mult;

  logic signed [$clog2(INT_SIZE-1)-1:0] exponent_B;
  logic [INT_SIZE-1:0] frac_B;
  
  //hard-coded length!
  /* verilator lint_off UNOPTFLAT */
  logic [$clog2(MANT_SIZE+1+INT_SIZE)-1:0] frac_mult_lzc;
  /* verilator lint_on UNOPTFLAT */
  count_leading_zeros count_leading_zeros(frac_mult,frac_mult_lzc);

  logic [(MANT_SIZE+1+INT_SIZE)-1:0] res_frac;
  logic signed [EXP_SIZE+1:0] res_exponent;
  logic [EXP_SIZE-1:0] res_exp;
  logic [MANT_SIZE-1:0] res_mant;
  logic res_sign;

  logic signed [EXP_SIZE-1:0] shift_amount;
  
  always_comb begin
    sign_A = in_A[EXP_SIZE+MANT_SIZE];
    exp_A = in_A[EXP_SIZE+MANT_SIZE-1:MANT_SIZE];
    mant_A = in_A[MANT_SIZE-1:0];


    if (exp_A == '0) begin  //subnormal case
      frac_A = {1'b0,mant_A};
      exponent_A = - (BIAS-1);
    end
    else begin  //normal case
      frac_A = {1'b1,mant_A};
      exponent_A = exp_A - BIAS;
    end

    sign_B = in_B[INT_SIZE-1];
    exponent_B = INT_SIZE-1;
    frac_B = {1'b0,in_B[INT_SIZE-2:0]};
    if (sign_B == 1'b1) begin
      frac_B = ~in_B + 1'b1;
    end
    


    frac_mult = frac_A * frac_B;  //main multiplier

    res_exponent = exponent_A + exponent_B - (frac_mult_lzc - 1);
    
    if (frac_mult_lzc == (MANT_SIZE+1+INT_SIZE)) begin //frac_mult is 0. i.e., output is 0.0
      res_exp = 0;
      shift_amount = 0;
      res_frac = 0;
      res_mant = 0;
    end    
    else if(res_exponent >= -(BIAS-1) ) begin //normal case
      res_exp = res_exponent + BIAS;
      shift_amount = frac_mult_lzc;
      res_frac = frac_mult << shift_amount;
      res_mant = res_frac[(MANT_SIZE+1+INT_SIZE)-2:INT_SIZE];
    end
    else begin  //subnormal case
      res_exp = 0;
      shift_amount = (res_exponent + (BIAS -1 ) + frac_mult_lzc);
      if (shift_amount >= 0)
        res_frac = frac_mult << shift_amount;
      else
        res_frac = frac_mult >> -shift_amount;
      res_mant = res_frac[(MANT_SIZE+1+INT_SIZE)-2:INT_SIZE];
    end

    res_sign = sign_A ^ sign_B;

    out = {res_sign,res_exp,res_mant};
  end
endmodule

module fsize_multiplier (		
    input logic	                  aclk,	
    input logic                   s_axis_a_tvalid,
    input logic [FLOAT_SIZE-1:0]  s_axis_a_tdata,
    input logic                   s_axis_b_tvalid,
    input logic [INT_SIZE-1:0]    s_axis_b_tdata,
    output logic                  m_axis_result_tvalid,
    output logic [FLOAT_SIZE-1:0] m_axis_result_tdata
  );

  logic [FLOAT_SIZE-1:0] multiplier_result;

  float_multiplier float_multiplier(s_axis_a_tdata,s_axis_b_tdata,multiplier_result);

  FifoBuffer #(.DATA_SIZE(1), .CYCLES(MULTIPLIER_DELAY)) valid_fifo (.clk(aclk), .in(s_axis_a_tvalid), .out(m_axis_result_tvalid) );
  FifoBuffer #(.DATA_SIZE(FLOAT_SIZE), .CYCLES(MULTIPLIER_DELAY)) out_fifo (.clk(aclk), .in(multiplier_result), .out(m_axis_result_tdata) );
endmodule