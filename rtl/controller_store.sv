`timescale 1 ns / 1 ns

`include "defines.vh"
import SPARQ_PKG::*;

(* use_dsp = "no" *) module Buffer_Store_Controller # (
		parameter BUFFER_SIZE = OUT_BUFFER_SIZE,
		parameter COMMAND_AXI_STORE0 = COMMAND_AXI_C_STORE0,
		parameter COMMAND_AXI_STORE1 = COMMAND_AXI_C_STORE1,
		parameter COMMAND_AXI_STORE2 = COMMAND_AXI_C_STORE2
	) (
    input rstn,
    input clk,

    input CommandDataPort commanddataport,
    output CommandDataPort commanddataport_axi,
       
    output logic axi_out_valid,
    input logic axi_out_ready, //not almost full.

    output logic[$clog2(BUFFER_SIZE)-1:0] out_raddr,

    output logic store_in_progress
);
  (* keep = "true" , max_fanout = 32 *) logic rstn_b;
  
  typedef struct packed{
    CommandDataPort commanddataport;

    logic [COMMAND_WIDTH-1:0] command;        
    logic [FSIZE-1:0]  command_data0;
    logic [FSIZE-1:0]  command_data1;

    logic [FSIZE-1:0] axi_out_state;

    logic [$clog2(BUFFER_SIZE)-1:0] accum_store_base_addr;

    logic [$clog2(BUFFER_SIZE)-1:0] axi_out_idx;
    logic [$clog2(BUFFER_SIZE)-1:0] axi_out_end;
    logic [$clog2(BUFFER_SIZE)-1:0] axi_store_size;
    logic [7:0] axi_store_chunk;
    logic [7:0] axi_store_chunks;

    logic axi_out_ready;
  } Registers;
    
  Registers reg_current,reg_next;

  logic axi_out_valid_0;
  FifoBuffer #(.DATA_SIZE(1), .CYCLES(BUFFER_READ_LATENCY) )  fb_axi_out_valid (.clk(clk), .in(axi_out_valid_0), .out(axi_out_valid));
  always_comb begin
    reg_next = reg_current;
    
    store_in_progress = 0;
    commanddataport_axi = '{default:'0};

    reg_next.axi_out_ready = axi_out_ready;

    reg_next.command = 0;
    if(commanddataport.valid) begin
      reg_next.command = commanddataport.command;       
      reg_next.command_data0 = commanddataport.data0;       
      reg_next.command_data1 = commanddataport.data1;       
    end
   
    if(reg_current.command == COMMAND_AXI_STORE0) begin 
      reg_next.accum_store_base_addr = reg_current.command_data0;              
    end
    if(reg_current.command == COMMAND_AXI_STORE1) begin 
      commanddataport_axi.valid = 1;
      commanddataport_axi.command = COMMAND_AXI_STORE1;
      commanddataport_axi.data0 = reg_current.command_data0;  //axi start addr
      commanddataport_axi.data1 = reg_current.command_data1;  //store  size

      reg_next.axi_store_size = reg_current.command_data1  / ((FLOAT_SIZE/8) * ARRAY_DIMENSION);  //store size
    end           
    if(reg_current.command == COMMAND_AXI_STORE2) begin 
      commanddataport_axi.valid = 1;
      commanddataport_axi.command = COMMAND_AXI_STORE2;
      commanddataport_axi.data0 = reg_current.command_data0;  //chunks
      commanddataport_axi.data1 = reg_current.command_data1;  //interval 

      reg_next.axi_store_chunk = 0;
      reg_next.axi_store_chunks = reg_current.command_data0;  //chunks

      reg_next.axi_out_state = STATE_WORKING;
      reg_next.axi_out_idx = reg_current.accum_store_base_addr;
      reg_next.axi_out_end = reg_current.accum_store_base_addr + reg_current.axi_store_size - 1;
    end           

    //++axi_writer out //
    axi_out_valid_0 = 0;
    if(reg_current.axi_out_state == STATE_WORKING)  begin
      store_in_progress = 1;

      if(reg_current.axi_out_ready ) begin
        axi_out_valid_0 = 1;

        reg_next.axi_out_idx = reg_current.axi_out_idx + 1;
        if(reg_current.axi_out_idx == reg_current.axi_out_end) begin
          reg_next.axi_out_end = reg_current.axi_out_idx + reg_current.axi_store_size;
          reg_next.axi_store_chunk = reg_current.axi_store_chunk + 1;
          if(reg_current.axi_store_chunk == reg_current.axi_store_chunks-1) begin
            reg_next.axi_store_chunk = 0;
            reg_next.axi_out_state = STATE_IDLE;       
          end
        end              
      end      
    end
    out_raddr = reg_current.axi_out_idx;

    if(rstn_b == 0) begin
      reg_next.commanddataport = '{default:'0};
      reg_next.axi_out_state = 0;
    end
  end
    
	always @( posedge clk ) begin
    rstn_b <= rstn;
    reg_current <= reg_next;
	end 
  
endmodule
