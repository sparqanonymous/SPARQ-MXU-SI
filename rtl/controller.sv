`timescale 1 ns / 1 ns

`include "defines.vh"
import SPARQ_PKG::*;


(* use_dsp = "no" *) module Controller  (
    input rstn,
    input clk,

    input CommandDataPort commanddataport,
    output StatePort stateport,
    
    output CommandDataPort commanddataport_axi_A,
    output CommandDataPort commanddataport_axi_A_meta,
    output CommandDataPort commanddataport_axi_B,
    output CommandDataPort commanddataport_axi_C,
       
    input logic axi_A_in_valid,
    output logic [$clog2(IN_BUFFER_SIZE)-1:0] axi_A_in_waddr,
    output logic                              axi_A_in_wren,
    
    input logic axi_A_meta_in_valid,
    output logic [$clog2(IN_BUFFER_SIZE)-1:0] axi_A_meta_in_waddr,
    output logic                              axi_A_meta_in_wren,
    
    input logic axi_B_in_valid,
    output logic [$clog2(IN_BUFFER_SIZE)-1:0] axi_B_in_waddr,
    output logic                              axi_B_in_wren,
    
    input logic   axi_C_in_valid,        
    output logic [$clog2(OUT_BUFFER_SIZE)-1:0]  axi_C_in_waddr,
    output logic                                axi_C_in_wren,
    output logic axi_C_load_to_buffer_C,

    output logic [$clog2(OUT_BUFFER_SIZE)-1:0]  axi_C_out_raddr,
    output logic  axi_C_out_valid,
    input logic   axi_C_out_ready,
    output logic  axi_C_store_from_buffer_C,

    output logic[PE_COMMAND_WIDTH-1:0] Aside_command,
    output logic[PE_COMMAND_WIDTH-1:0] Bside_command,    
    output PE_C_Inter_Req Cside_inter_req,
    output logic[ACCUM_COMMAND_WIDTH-1:0] accumulator_command,
    
    output logic [$clog2(IN_BUFFER_SIZE)-1:0]   buffer_A_raddr,
    output logic [$clog2(IN_BUFFER_SIZE)-1:0]   buffer_B_raddr,
    
    output logic[$clog2(OUT_BUFFER_SIZE)-1:0]   accumulator_raddr,
    output logic[$clog2(OUT_BUFFER_SIZE)-1:0]   accumulator_waddr,
    output logic                                accumulator_wren,
    
    input logic[PE_COMMAND_WIDTH-1:0] Cside_out_command,
    input logic[PE_COMMAND_WIDTH-1:0] pre_Cside_out_command,
    input logic[PE_COMMAND_WIDTH-1:0] Aside_last_in_command       
);
  (* keep = "true" , max_fanout = 32 *) logic rstn_b;
  
  CommandDataPort commanddataport_axi_C_buffer_load;
  CommandDataPort commanddataport_axi_C_buffer_store;


  logic axi_A_load_in_progress;
  Buffer_Load_Controller #(
    .BUFFER_SIZE(IN_BUFFER_SIZE),
    .COMMAND_AXI_LOAD0(COMMAND_AXI_A_LOAD0),
    .COMMAND_AXI_LOAD1(COMMAND_AXI_A_LOAD1),
    .COMMAND_AXI_LOAD2(COMMAND_AXI_A_LOAD2),
    .BYTES_PER_LOAD(ARRAY_DIMENSION / 2)
  ) axi_A_load_controller (
    .rstn(rstn),
    .clk(clk),
    .commanddataport(commanddataport),
    .commanddataport_axi(commanddataport_axi_A),
    .axi_in_valid(axi_A_in_valid),
    .axi_in_waddr(axi_A_in_waddr),
    .axi_in_wren(axi_A_in_wren),
    .load_in_progress(axi_A_load_in_progress)
  );

  logic axi_A_meta_load_in_progress;
  Buffer_Load_Controller #(
    .BUFFER_SIZE(IN_BUFFER_SIZE),
    .COMMAND_AXI_LOAD0(COMMAND_AXI_A_META_LOAD0),
    .COMMAND_AXI_LOAD1(COMMAND_AXI_A_META_LOAD1),
    .COMMAND_AXI_LOAD2(COMMAND_AXI_A_META_LOAD2),
    .BYTES_PER_LOAD(ARRAY_DIMENSION / 2)
  ) axi_A_META_load_controller (
    .rstn(rstn),
    .clk(clk),
    .commanddataport(commanddataport),
    .commanddataport_axi(commanddataport_axi_A_meta),
    .axi_in_valid(axi_A_meta_in_valid),
    .axi_in_waddr(axi_A_meta_in_waddr),
    .axi_in_wren(axi_A_meta_in_wren),
    .load_in_progress(axi_A_meta_load_in_progress)
  );

  logic axi_B_load_in_progress;
  Buffer_Load_Controller #(
    .BUFFER_SIZE(IN_BUFFER_SIZE),
    .COMMAND_AXI_LOAD0(COMMAND_AXI_B_LOAD0),
    .COMMAND_AXI_LOAD1(COMMAND_AXI_B_LOAD1),
    .COMMAND_AXI_LOAD2(COMMAND_AXI_B_LOAD2),
    .BYTES_PER_LOAD((FLOAT_SIZE/8) * ARRAY_DIMENSION)
  ) axi_B_load_controller (
    .rstn(rstn),
    .clk(clk),
    .commanddataport(commanddataport),
    .commanddataport_axi(commanddataport_axi_B),
    .axi_in_valid(axi_B_in_valid),
    .axi_in_waddr(axi_B_in_waddr),
    .axi_in_wren(axi_B_in_wren),
    .load_in_progress(axi_B_load_in_progress)
  );

  logic axi_C_load_in_progress;
  Buffer_Load_Controller #(
    .BUFFER_SIZE(OUT_BUFFER_SIZE),
    .COMMAND_AXI_LOAD0(COMMAND_AXI_C_LOAD0),
    .COMMAND_AXI_LOAD1(COMMAND_AXI_C_LOAD1),
    .COMMAND_AXI_LOAD2(COMMAND_AXI_C_LOAD2),
    .BYTES_PER_LOAD((FLOAT_SIZE/8) * ARRAY_DIMENSION)
  ) axi_C_load_controller (
    .rstn(rstn),
    .clk(clk),
    .commanddataport(commanddataport),
    .commanddataport_axi(commanddataport_axi_C_buffer_load), 
    .axi_in_valid(axi_C_in_valid),
    .axi_in_waddr(axi_C_in_waddr),
    .axi_in_wren(axi_C_in_wren),
    .load_in_progress(axi_C_load_in_progress)
  );

  logic axi_C_store_in_progress;
  Buffer_Store_Controller #(
    .BUFFER_SIZE(OUT_BUFFER_SIZE),
    .COMMAND_AXI_STORE0(COMMAND_AXI_C_STORE0),
    .COMMAND_AXI_STORE1(COMMAND_AXI_C_STORE1),
    .COMMAND_AXI_STORE2(COMMAND_AXI_C_STORE2)
  ) axi_C_store_controller (
    .rstn(rstn),
    .clk(clk),
    .commanddataport(commanddataport),
    .commanddataport_axi(commanddataport_axi_C_buffer_store),
    .axi_out_valid(axi_C_out_valid),    
    .axi_out_ready(axi_C_out_ready),    
    .out_raddr(axi_C_out_raddr),
    .store_in_progress(axi_C_store_in_progress)
  );


  logic pein_in_progress;
  logic accum_in_progress;
  GEMM_Controller gemm_controller (
    .rstn(rstn),
    .clk(clk),
    .commanddataport(commanddataport),
    
    .Aside_command(Aside_command),
    .Bside_command(Bside_command),
    .Cside_inter_req(Cside_inter_req),
    .accumulator_command(accumulator_command),
    
    .buffer_A_raddr(buffer_A_raddr),
    .buffer_B_raddr(buffer_B_raddr),

    .accumulator_raddr(accumulator_raddr),
    .accumulator_waddr(accumulator_waddr),
    .accumulator_wren (accumulator_wren),

    .Cside_out_command(Cside_out_command),
    .pre_Cside_out_command(pre_Cside_out_command),
    .Aside_last_in_command(Aside_last_in_command),

    .pein_in_progress(pein_in_progress),
    .accum_in_progress(accum_in_progress)
  );

  assign commanddataport_axi_C = commanddataport_axi_C_buffer_store.valid? commanddataport_axi_C_buffer_store: commanddataport_axi_C_buffer_load;
  assign axi_C_store_from_buffer_C = axi_C_store_in_progress;
  assign axi_C_load_to_buffer_C = axi_C_load_in_progress;

  always_comb begin
    stateport.state0 = axi_A_load_in_progress;
    stateport.state1 = axi_A_meta_load_in_progress;
    stateport.state2 = axi_B_load_in_progress;
    stateport.state3 = axi_C_load_in_progress;
    stateport.state4 = axi_C_store_in_progress;
    stateport.state5 = pein_in_progress;
    stateport.state6 = accum_in_progress;
    stateport.state7 = 0;
  end
    
  
endmodule
