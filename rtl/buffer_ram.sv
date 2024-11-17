`timescale 1 ns / 1 ns

`include "defines.vh"


import SPARQ_PKG::*;



module BufferRAMT #(
  parameter ID      = 0,
  parameter DEPTH   = 512,
  parameter WIDTH   = FSIZE,
  parameter WORDS   = 32,
  parameter READ_LATENCY = BUFFER_READ_LATENCY,
  parameter DEPTHAD = $clog2(DEPTH)
) (
  input logic                   clk,
  input logic [DEPTHAD-1:0]     raddr,
  input logic [DEPTHAD-1:0]     waddr,
  input logic [WIDTH*WORDS-1:0] wdata,
  input logic                   wren,
  output logic [WIDTH*WORDS-1:0] rdata
);
  `ifndef SYNTHESIS
  generate 
      logic[WIDTH*WORDS-1:0] memory[0:DEPTH-1];
      logic[WIDTH*WORDS-1:0] rbuffer[0:READ_LATENCY-1];
      
      assign rdata = rbuffer[READ_LATENCY-1];
      
      always @ (posedge clk) begin
        rbuffer[0] <= memory[raddr];
        for(int i = 0; i < READ_LATENCY-1; i ++)  
          rbuffer[i+1] <= rbuffer[i];
        
        if(wren) begin
          memory[waddr] = wdata;
        end
      end  
  endgenerate  
  `endif

endmodule

module BufferRAMT2X #(
  parameter ID      = 0,
  parameter DEPTH   = 512,
  parameter WIDTH   = FSIZE,
  parameter WORDS   = 32,
  parameter READ_LATENCY = BUFFER_READ_LATENCY,
  parameter DEPTHAD = $clog2(DEPTH)
) (
  input logic                   clk,
  input logic [DEPTHAD-1:0]     raddr,
  input logic [DEPTHAD-1:0]     waddr,
  input logic [WIDTH*WORDS-1:0] wdata0,
  input logic [WIDTH*WORDS-1:0] wdata1,
  input logic                   wren0,
  input logic                   wren1,
  output logic [WIDTH*WORDS-1:0] rdata0,
  output logic [WIDTH*WORDS-1:0] rdata1
);
  `ifndef SYNTHESIS
  generate 
      logic[WIDTH*WORDS-1:0] memory[0:DEPTH-1];
      logic[WIDTH*WORDS-1:0] rbuffer0[0:READ_LATENCY-1];
      logic[WIDTH*WORDS-1:0] rbuffer1[0:READ_LATENCY-1];
      
      assign rdata0 = rbuffer0[READ_LATENCY-1];
      assign rdata1 = rbuffer1[READ_LATENCY-1];
      
      always @ (posedge clk) begin
        rbuffer0[0] <= memory[raddr];
        rbuffer1[0] <= memory[raddr+1];
        for(int i = 0; i < READ_LATENCY-1; i ++)  begin
          rbuffer0[i+1] <= rbuffer0[i];
          rbuffer1[i+1] <= rbuffer1[i];
        end
        
        if(wren0) begin
          memory[waddr] = wdata0;
        end
        if(wren1) begin
          memory[waddr+1] = wdata1;
        end
      end  
  endgenerate  
  `endif

endmodule