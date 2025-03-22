`timescale 1 ns / 1 ns 

`include "defines.vh"
import SPARQ_PKG::*;


module sparq_top #(
        parameter SIM_MODE        = 0
	) (
		input logic	clk,		    		
		input logic rstn,			

		input logic flat_axi_A_in_valid,
		input logic [ARRAY_DIMENSION*INT_SIZE-1:0] flat_axi_A_in_data,
		output logic flat_axi_A_out_valid,
		input logic flat_axi_A_out_ready,
		output logic [ARRAY_DIMENSION*INT_SIZE-1:0] flat_axi_A_out_data,
		    
		input logic flat_axi_A_meta_in_valid,
		input logic [ARRAY_DIMENSION*META_SIZE-1:0] flat_axi_A_meta_in_data,
		output logic flat_axi_A_meta_out_valid,
		input logic flat_axi_A_meta_out_ready,
		output logic [ARRAY_DIMENSION*META_SIZE-1:0] flat_axi_A_meta_out_data,
		    
		input logic flat_axi_B_in_valid,
		input logic [ARRAY_DIMENSION*FLOAT_SIZE-1:0] flat_axi_B_in_data,
		output logic flat_axi_B_out_valid,
		input logic flat_axi_B_out_ready,
		output logic [ARRAY_DIMENSION*FLOAT_SIZE-1:0] flat_axi_B_out_data,
		    
    input logic flat_axi_C_in_valid,
		input logic [ARRAY_DIMENSION*FLOAT_SIZE-1:0] flat_axi_C_in_data,		
		output logic flat_axi_C_out_valid,
		input logic flat_axi_C_out_ready,
		output logic [ARRAY_DIMENSION*FLOAT_SIZE-1:0] flat_axi_C_out_data,

    output CommandDataPort       commanddataport_axi_A,
    output CommandDataPort       commanddataport_axi_A_meta,
    output CommandDataPort       commanddataport_axi_B,
    output CommandDataPort       commanddataport_axi_C,

    input CommandDataPort commanddataport,
    output StatePort stateport
	);

  logic [$clog2(IN_BUFFER_SIZE)-1:0]      buffer_A_raddr;
  logic [$clog2(IN_BUFFER_SIZE)-1:0]      buffer_A_waddr;
  logic [INT_SIZE*ARRAY_DIMENSION-1:0]    buffer_A_rdata;
  logic [INT_SIZE*ARRAY_DIMENSION-1:0]    buffer_A_wdata;
  logic                                   buffer_A_wren;

  logic [$clog2(IN_BUFFER_SIZE/2)-1:0]    buffer_A_meta_waddr;
  logic [META_SIZE*ARRAY_DIMENSION-1:0]   buffer_A_meta_rdata;
  logic [META_SIZE*ARRAY_DIMENSION-1:0]   buffer_A_meta_wdata;
  logic                                   buffer_A_meta_wren;

  logic [$clog2(IN_BUFFER_SIZE)-1:0]      buffer_B_raddr;
  logic [$clog2(IN_BUFFER_SIZE)-1:0]      buffer_B_waddr;
  logic [FLOAT_SIZE*ARRAY_DIMENSION-1:0]  buffer_B_rdata;
  logic [FLOAT_SIZE*ARRAY_DIMENSION-1:0]  buffer_B_wdata;
  logic                                   buffer_B_wren;

  logic [$clog2(OUT_BUFFER_SIZE)-1:0]     buffer_C_raddr;
  logic [$clog2(OUT_BUFFER_SIZE)-1:0]     buffer_C_waddr;
  logic [FLOAT_SIZE*ARRAY_DIMENSION-1:0]  buffer_C_rdata0;
  logic [FLOAT_SIZE*ARRAY_DIMENSION-1:0]  buffer_C_rdata1;
  logic [FLOAT_SIZE*ARRAY_DIMENSION-1:0]  buffer_C_wdata0;
  logic [FLOAT_SIZE*ARRAY_DIMENSION-1:0]  buffer_C_wdata1;
logic                                     buffer_C_wren0;
logic                                     buffer_C_wren1;

  BufferRAMT #(
    .ID(0),
    .DEPTH(IN_BUFFER_SIZE),
    .WIDTH(INT_SIZE),
    .WORDS(ARRAY_DIMENSION)
  ) buffer_A (
    .clk(clk),
    .raddr(buffer_A_raddr),
    .rdata(buffer_A_rdata),
    .waddr(buffer_A_waddr),
    .wdata(buffer_A_wdata),
    .wren (buffer_A_wren)
  );  

  BufferRAMT #(
    .ID(0),
    .DEPTH(IN_BUFFER_SIZE/2),
    .WIDTH(META_SIZE),
    .WORDS(ARRAY_DIMENSION)
  ) buffer_A_meta (
    .clk(clk),
    .raddr(buffer_A_raddr[$clog2(IN_BUFFER_SIZE)-1:1]),
    .rdata(buffer_A_meta_rdata),
    .waddr(buffer_A_meta_waddr),
    .wdata(buffer_A_meta_wdata),
    .wren (buffer_A_meta_wren)
  );  

  BufferRAMT #(
    .ID(0),
    .DEPTH(IN_BUFFER_SIZE),
    .WIDTH(FLOAT_SIZE),
    .WORDS(ARRAY_DIMENSION)
  ) buffer_B (
    .clk(clk),
    .raddr(buffer_B_raddr),
    .rdata(buffer_B_rdata),
    .waddr(buffer_B_waddr),
    .wdata(buffer_B_wdata),
    .wren (buffer_B_wren)
  );  

  BufferRAMT2X #(
    .ID(0),
    .DEPTH(OUT_BUFFER_SIZE),
    .WIDTH(FLOAT_SIZE),
    .WORDS(ARRAY_DIMENSION)
  ) buffer_C (
    .clk(clk),
    .raddr(buffer_C_raddr),
    .rdata0(buffer_C_rdata0),
    .rdata1(buffer_C_rdata1),
    .waddr(buffer_C_waddr),
    .wdata0(buffer_C_wdata0),
    .wdata1(buffer_C_wdata1),
    .wren0 (buffer_C_wren0),
    .wren1 (buffer_C_wren1)
  );  

  //1-cycle buffer the input data since flat_axi_in_valid is also buffered 1-cycle in the contoller
  logic [ARRAY_DIMENSION*INT_SIZE-1:0] flat_axi_A_in_data_buf;
  always @ (posedge clk) flat_axi_A_in_data_buf <= flat_axi_A_in_data;
  logic [ARRAY_DIMENSION*META_SIZE-1:0] flat_axi_A_meta_in_data_buf;
  always @ (posedge clk) flat_axi_A_meta_in_data_buf <= flat_axi_A_meta_in_data;
  logic [ARRAY_DIMENSION*FLOAT_SIZE-1:0] flat_axi_B_in_data_buf;
  always @ (posedge clk) flat_axi_B_in_data_buf <= flat_axi_B_in_data;
  logic [ARRAY_DIMENSION*FLOAT_SIZE-1:0] flat_axi_C_in_data_buf;
  always @ (posedge clk) flat_axi_C_in_data_buf <= flat_axi_C_in_data;

  logic [$clog2(OUT_BUFFER_SIZE)-1:0] accumulator_raddr;
  logic [$clog2(OUT_BUFFER_SIZE)-1:0] accumulator_waddr;
  logic accumulator_wren;

  logic [$clog2(IN_BUFFER_SIZE)-1:0]   axi_A_in_waddr;
  logic                                axi_A_in_wren;

  logic [$clog2(IN_BUFFER_SIZE)-1:0]   axi_A_meta_in_waddr;
  logic                                axi_A_meta_in_wren;

  logic [$clog2(IN_BUFFER_SIZE)-1:0]   axi_B_in_waddr;
  logic                                axi_B_in_wren;
  
  logic axi_C_load_to_buffer_C;
  logic axi_C_store_from_buffer_C;
  logic [$clog2(OUT_BUFFER_SIZE)-1:0]  axi_C_in_waddr;
  logic                                axi_C_in_wren;
  logic [$clog2(OUT_BUFFER_SIZE)-1:0]  axi_C_out_raddr;

  logic [FLOAT_SIZE*ARRAY_DIMENSION-1:0]   accumulator_in_data0;
  logic [FLOAT_SIZE*ARRAY_DIMENSION-1:0]   accumulator_in_data1;
  logic [FLOAT_SIZE*ARRAY_DIMENSION-1:0]   accumulator_out_data0;
  logic [FLOAT_SIZE*ARRAY_DIMENSION-1:0]   accumulator_out_data1;
  

  always_comb begin
    buffer_A_wdata = flat_axi_A_in_data_buf;
    buffer_A_meta_wdata = flat_axi_A_meta_in_data_buf;
    buffer_B_wdata = flat_axi_B_in_data_buf;
    buffer_A_waddr = axi_A_in_waddr;
    buffer_A_meta_waddr = axi_A_meta_in_waddr;
    buffer_B_waddr = axi_B_in_waddr;   
    buffer_A_wren = axi_A_in_wren;
    buffer_A_meta_wren = axi_A_meta_in_wren;
    buffer_B_wren = axi_B_in_wren;
    
    flat_axi_C_out_data = buffer_C_rdata0;
    if(axi_C_store_from_buffer_C == 1'b1) begin
      buffer_C_raddr = axi_C_out_raddr;    
    end
    else begin
      buffer_C_raddr = accumulator_raddr;    
    end

    if(axi_C_load_to_buffer_C == 1'b1)  begin
      buffer_C_wren0 = axi_C_in_wren;
      buffer_C_wren1 = 1'b0;
      buffer_C_waddr = axi_C_in_waddr;
      buffer_C_wdata0 = flat_axi_C_in_data_buf;
      buffer_C_wdata1 = '0;
    end
    else begin
      buffer_C_wren0 = accumulator_wren;
      buffer_C_wren1 = accumulator_wren;
      buffer_C_waddr = accumulator_waddr;
      buffer_C_wdata0 = accumulator_out_data0;
      buffer_C_wdata1 = accumulator_out_data1;
    end
  end

  PE_A_Input PE_A_in   [0:ARRAY_DIMENSION][0:ARRAY_DIMENSION-1];
  PE_B_Input PE_B_in   [0:ARRAY_DIMENSION][0:ARRAY_DIMENSION-1];
  PE_C_Result PE_C_out0 [0:ARRAY_DIMENSION][0:ARRAY_DIMENSION-1];
  PE_C_Result PE_C_out1 [0:ARRAY_DIMENSION][0:ARRAY_DIMENSION-1];
  PE_C_Inter_Req PE_C_inter_req [0:ARRAY_DIMENSION][0:ARRAY_DIMENSION-1];
  PE_D_Output PE_D_out   [0:ARRAY_DIMENSION][0:ARRAY_DIMENSION-1];

  logic [PE_COMMAND_WIDTH-1:0] Cside_out_command;
  logic [PE_COMMAND_WIDTH-1:0] pre_Cside_out_command;
  logic [PE_COMMAND_WIDTH-1:0] Aside_last_in_command;
  logic [PE_COMMAND_WIDTH-1:0] Aside_command;
  logic [PE_COMMAND_WIDTH-1:0] Bside_command;
  PE_C_Inter_Req Cside_inter_req;
  logic [ACCUM_COMMAND_WIDTH-1:0] accumulator_command;
  logic [ACCUM_COMMAND_WIDTH-1:0] accumulator_command_array0 [0:ARRAY_DIMENSION-1];
  logic [ACCUM_COMMAND_WIDTH-1:0] accumulator_command_array1 [0:ARRAY_DIMENSION-1];

  data_skew_in_A #(
    .NUM_DATA(ARRAY_DIMENSION),
    .DATA_SIZE(INT_SIZE),
    .SKEW_DEGREE(ADDER_DELAY + 2 + 2 )
  )
  Aside_skew (
    .clk(clk),
    .command_in(Aside_command),
    .flat_data(buffer_A_rdata),
    .flat_meta_data(buffer_A_meta_rdata),
    .pe_in(PE_A_in[0])
  );

  data_skew_in_B #(
    .NUM_DATA(ARRAY_DIMENSION)
  )
  Bside_skew (
    .clk(clk),
    .command_in(Bside_command),
    .flat_data(buffer_B_rdata),
    .pe_in(PE_B_in[0])
  );
  
  data_skew_out #(
    .NUM_DATA(ARRAY_DIMENSION)
  )
  CSide_skew0 (
    .clk(clk),
    .pe_out(PE_C_out0[ARRAY_DIMENSION]),
    .accum_command_in(accumulator_command),
    .flat_data(accumulator_in_data0),
    .command_out(Cside_out_command),
    .pre_command_out(pre_Cside_out_command),
    .accum_commands_out(accumulator_command_array0)
  );

  data_skew_out #(
    .NUM_DATA(ARRAY_DIMENSION),
    .CYCLE_OFFSET(1)
  )
  CSide_skew1 (
    .clk(clk),
    .pe_out(PE_C_out1[ARRAY_DIMENSION]),
    .accum_command_in(accumulator_command),
    .flat_data(accumulator_in_data1),
    .command_out(),
    .pre_command_out(),
    .accum_commands_out(accumulator_command_array1)
  );

  data_skew_C_Inter_Req_in #(
    .NUM_DATA(ARRAY_DIMENSION)
  )
  Cside_inter_req_skew_in (
    .clk(clk),
    .req_in(Cside_inter_req),
    .req_out(PE_C_inter_req[ARRAY_DIMENSION])
  );

  accumulator_array #(
    .NUM_DATA(ARRAY_DIMENSION)
  )
  accumulator_array0 (
    .clk(clk),
    .command_array(accumulator_command_array0),
    .in_A(accumulator_in_data0),
    .in_B(buffer_C_rdata0),
    .out(accumulator_out_data0)    
  );

  accumulator_array #(
    .NUM_DATA(ARRAY_DIMENSION)
  )
  accumulator_array1 (
    .clk(clk),
    .command_array(accumulator_command_array1),
    .in_A(accumulator_in_data1),
    .in_B(buffer_C_rdata1),
    .out(accumulator_out_data1)    
  );

  (* use_dsp = "no" *)  Controller controller(
    .rstn(rstn),
    .clk(clk),

    .commanddataport(commanddataport),
    .stateport(stateport),
    
    .commanddataport_axi_A(commanddataport_axi_A),
    .commanddataport_axi_A_meta(commanddataport_axi_A_meta),
    .commanddataport_axi_B(commanddataport_axi_B),
    .commanddataport_axi_C (commanddataport_axi_C),

    .axi_A_in_valid(flat_axi_A_in_valid),
    .axi_A_in_waddr(axi_A_in_waddr),
    .axi_A_in_wren(axi_A_in_wren),    
  
    .axi_A_meta_in_valid(flat_axi_A_meta_in_valid),
    .axi_A_meta_in_waddr(axi_A_meta_in_waddr),
    .axi_A_meta_in_wren(axi_A_meta_in_wren),    
  
    .axi_B_in_valid(flat_axi_B_in_valid),
    .axi_B_in_waddr(axi_B_in_waddr),
    .axi_B_in_wren(axi_B_in_wren),    
  
    .axi_C_in_valid(flat_axi_C_in_valid),
    .axi_C_in_waddr(axi_C_in_waddr),
    .axi_C_in_wren(axi_C_in_wren),    
    .axi_C_load_to_buffer_C(axi_C_load_to_buffer_C),

    .axi_C_out_raddr(axi_C_out_raddr),
    .axi_C_out_valid(flat_axi_C_out_valid),
    .axi_C_out_ready(flat_axi_C_out_ready),
    .axi_C_store_from_buffer_C(axi_C_store_from_buffer_C),
  
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
    .Aside_last_in_command(Aside_last_in_command)
  );

  genvar hi,vi;
  generate 
    for(hi = 0; hi < ARRAY_DIMENSION; hi ++) begin : internal_pipe_cap_v
      assign PE_C_out0[0][hi].command = 0; //tie end
      assign PE_C_out0[0][hi].data = 0; //tie end
      assign PE_C_out1[0][hi].command = 0; //tie end
      assign PE_C_out1[0][hi].data = 0; //tie end
    end

    for(vi = 0; vi < ARRAY_DIMENSION; vi ++) begin : internal_pipe_cap_h
      assign PE_D_out[0][vi].pos_0 = 0; //tie end
      assign PE_D_out[0][vi].pos_1 = 0; //tie end
    end

    assign Aside_last_in_command = PE_A_in[0][ARRAY_DIMENSION-1].command;

    for(vi = 0; vi < ARRAY_DIMENSION; vi = vi+1) begin : pe_v_gen
      for(hi = 0; hi < ARRAY_DIMENSION; hi = hi+1) begin : pe_h_gen
        PE_C_Result PE_C_out_internal0;
        PE_C_Result PE_C_out_internal1;
        PE #(.ID_V(vi),.ID_H(hi)) pe(
          .clk(clk),          
          .Aside_in_input   ( PE_A_in[hi]  [vi]   ),
          .Aside_in_output  ( PE_A_in[hi+1][vi]   ),
	    	  .Bside_in_input   ( PE_B_in[vi][hi]   ),
          .Bside_in_output  ( PE_B_in[vi+1][hi]   ),
          .Cside_out_input0 ( PE_C_out0[vi ] [hi]  ),
          .Cside_out_input1 ( PE_C_out1[vi ] [hi]  ),
          .Cside_out_output0 ( PE_C_out_internal0   ),
          .Cside_out_output1 ( PE_C_out_internal1   ),
          .Cside_inter_req_output ( PE_C_inter_req[vi][hi] )
        );     
        InterPEBuffer #(.ID_V(vi),.ID_H(hi)) inter_buffer (
          .clk(clk),          
	    	  .Cside_out_input0  ( PE_C_out_internal0 ),
	    	  .Cside_out_input1  ( PE_C_out_internal1 ),
	    	  .Cside_out_output0 ( PE_C_out0[vi+1][hi] ),
	    	  .Cside_out_output1 ( PE_C_out1[vi+1][hi] ),
          .Cside_inter_req_input   ( PE_C_inter_req[vi+1][hi] ),
          .Dside_out_input   ( PE_D_out[hi][vi]),
          .Dside_out_output  ( PE_D_out[hi+1][vi])
        );
      end
    end    
  endgenerate

endmodule
