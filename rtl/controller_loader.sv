`timescale 1 ns / 1 ns

`include "defines.vh"
import SPARQ_PKG::*;


(* use_dsp = "no" *) module Buffer_Load_Controller  #(
		parameter BUFFER_SIZE = IN_BUFFER_SIZE,
		parameter COMMAND_AXI_LOAD0 = COMMAND_AXI_A_LOAD0,
		parameter COMMAND_AXI_LOAD1 = COMMAND_AXI_A_LOAD1,
		parameter COMMAND_AXI_LOAD2 = COMMAND_AXI_A_LOAD2,
    parameter BYTES_PER_LOAD = (FLOAT_SIZE/8) * ARRAY_DIMENSION
	) (
    input rstn,
    input clk,

    input CommandDataPort commanddataport,
    output CommandDataPort commanddataport_axi,

    input logic axi_in_valid,
    output logic[$clog2(BUFFER_SIZE)-1:0]  axi_in_waddr,
    output logic                           axi_in_wren,

    output logic load_in_progress
);
  (* keep = "true" , max_fanout = 32 *) logic rstn_b;
  
  typedef struct packed{
    CommandDataPort commanddataport;

    logic [COMMAND_WIDTH-1:0] command;        
    logic [FSIZE-1:0]  command_data0;
    logic [FSIZE-1:0]  command_data1;

    logic [FSIZE-1:0] axi_in_state;

    logic [$clog2(IN_BUFFER_SIZE)-1:0] axi_load_base_addr;


    logic [$clog2(BUFFER_SIZE)-1:0] axi_in_idx;
    logic [$clog2(BUFFER_SIZE)-1:0] axi_in_end;

    logic [$clog2(BUFFER_SIZE)-1:0] axi_load_size;
    logic [7:0] axi_load_chunk;
    logic [7:0] axi_load_chunks;

    logic axi_in_valid;
  } Registers;
    
  Registers reg_current,reg_next;

  always_comb begin
    reg_next = reg_current;
    
    load_in_progress = 0;
    commanddataport_axi = '{default:'0};

    reg_next.axi_in_valid = axi_in_valid;

    reg_next.command = 0;
    if(commanddataport.valid) begin
      reg_next.command = commanddataport.command;       
      reg_next.command_data0 = commanddataport.data0;       
      reg_next.command_data1 = commanddataport.data1;       
    end
   
    if(reg_current.command == COMMAND_AXI_LOAD0) begin 
      reg_next.axi_load_base_addr = reg_current.command_data0;   
    end
    if(reg_current.command == COMMAND_AXI_LOAD1) begin 
      commanddataport_axi.valid = 1;
      commanddataport_axi.command = COMMAND_AXI_LOAD1;
      commanddataport_axi.data0 = reg_current.command_data0;  //axi start addr
      commanddataport_axi.data1 = reg_current.command_data1;  //load size

      reg_next.axi_load_size = reg_current.command_data1  / BYTES_PER_LOAD;
    end               
    if(reg_current.command == COMMAND_AXI_LOAD2) begin 
      commanddataport_axi.valid = 1;
      commanddataport_axi.command = COMMAND_AXI_LOAD2;
      commanddataport_axi.data0 = reg_current.command_data0;  //chunks
      commanddataport_axi.data1 = reg_current.command_data1;  //interval 

      reg_next.axi_load_chunk = 0;
      reg_next.axi_load_chunks = reg_current.command_data0;  //chunks

      reg_next.axi_in_state = STATE_WORKING;
      reg_next.axi_in_idx = reg_current.axi_load_base_addr;
      reg_next.axi_in_end = reg_current.axi_load_base_addr + reg_current.axi_load_size - 1;
    end            

    //++axi_loader in //
    axi_in_wren = 0;
    axi_in_waddr = 0;
    if(reg_current.axi_in_state == STATE_WORKING)  begin
        load_in_progress = 1;
        
        if(reg_current.axi_in_valid) begin
          reg_next.axi_in_idx = reg_current.axi_in_idx + 1;
          if(reg_current.axi_in_idx == reg_current.axi_in_end) begin
            reg_next.axi_in_end = reg_current.axi_in_idx + reg_current.axi_load_size;

            reg_next.axi_load_chunk = reg_current.axi_load_chunk + 1;
            if(reg_current.axi_load_chunk == reg_current.axi_load_chunks-1) begin
              reg_next.axi_load_chunk = 0;

              reg_next.axi_in_state = STATE_IDLE;       
            end
          end

          axi_in_wren = 1;
        end
        axi_in_waddr = reg_current.axi_in_idx; 
    end
    //--axi_loader in //

    if(rstn_b == 0) begin
      reg_next.commanddataport = '{default:'0};
      reg_next.axi_in_state = 0;
    end
  end
    
	always @( posedge clk ) begin
    rstn_b <= rstn;
    reg_current <= reg_next;
	end 
  
endmodule
