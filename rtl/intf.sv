`timescale 1 ns / 1 ns 

`include "defines.vh"


package SPARQ_PKG;

localparam ARRAY_DIMENSION = 8;

localparam IN_BUFFER_SIZE    = 32'h10000;
localparam OUT_BUFFER_SIZE   = 32'h10000;

localparam QSIZE=8;
localparam FSIZE=32;

localparam COMMAND_WIDTH=8;
localparam PE_COMMAND_WIDTH=4;
localparam ACCUM_COMMAND_WIDTH=1;
localparam STATE_WIDTH=4;

localparam BUFFER_READ_LATENCY=2;

typedef struct  packed {
  logic valid;
  logic [COMMAND_WIDTH-1:0] command;
  logic [FSIZE-1:0] data0;
  logic [FSIZE-1:0] data1;
} CommandDataPort;

typedef struct  packed {
  logic [FSIZE-1:0] state0;	//will be connected to the axi in state
  logic [FSIZE-1:0] state1;	//will be connected to the axi out state
  logic [FSIZE-1:0] state2;	//will be connected to the pein state
  logic [FSIZE-1:0] state3;	//will be connected to the peout state
  logic [FSIZE-1:0] state4;	//will be connected to the peout state
  logic [FSIZE-1:0] state5;	//will be connected to the peout state
  logic [FSIZE-1:0] state6;	//will be connected to the peout state
  logic [FSIZE-1:0] state7;	//will be connected to the peout state
} StatePort;




localparam COMMAND_PE_RESET = 1;
localparam COMMAND_GEMM0 = 2;
localparam COMMAND_GEMM1 = 3;
localparam COMMAND_GEMM2 = 4;
localparam COMMAND_AXI_A_LOAD0 = 5;
localparam COMMAND_AXI_A_LOAD1 = 6;
localparam COMMAND_AXI_A_LOAD2 = 7;
localparam COMMAND_AXI_A_META_LOAD0 = 8;
localparam COMMAND_AXI_A_META_LOAD1 = 9;
localparam COMMAND_AXI_A_META_LOAD2 = 10;
localparam COMMAND_AXI_B_LOAD0 = 11;
localparam COMMAND_AXI_B_LOAD1 = 12;
localparam COMMAND_AXI_B_LOAD2 = 13;
localparam COMMAND_AXI_C_LOAD0 = 14;
localparam COMMAND_AXI_C_LOAD1 = 15;
localparam COMMAND_AXI_C_LOAD2 = 16;
localparam COMMAND_AXI_C_STORE0 = 17;
localparam COMMAND_AXI_C_STORE1 = 18;
localparam COMMAND_AXI_C_STORE2 = 19;

localparam STATE_IDLE = 0;
localparam STATE_WORKING = 1;

localparam PE_COMMAND_IDLE      =  0;
localparam PE_COMMAND_NORMAL    =  1;
localparam PE_COMMAND_RESET     =  3;
localparam PE_COMMAND_LOAD      =  4;

localparam ACCUMULATOR_COMMAND_ACCUM = 1;
localparam ACCUMULATOR_COMMAND_NEW_ACCUM = 0;

localparam MULTIPLIER_DELAY = 4; //fp16:4 bf16:4
localparam ADDER_DELAY = 6;

localparam EXP_SIZE = 5;
localparam MANT_SIZE = 10;
localparam BIAS = 15;

//localparam EXP_SIZE = 8;
//localparam MANT_SIZE = 7;
//localparam BIAS = 127;

localparam FLOAT_SIZE = 1 + EXP_SIZE + MANT_SIZE;
localparam INT_SIZE = 4;

localparam META_SIZE = 4;

typedef struct packed {
  logic [PE_COMMAND_WIDTH-1:0] command;
  logic [META_SIZE-1:0] meta;
  logic signed [INT_SIZE-1:0] data;
} PE_A_Input;

typedef struct packed {
  logic [PE_COMMAND_WIDTH-1:0] command;
  logic signed [FLOAT_SIZE-1:0] data;
} PE_B_Input;

typedef struct packed  {
  logic [PE_COMMAND_WIDTH-1:0] command;
  logic phase;
  logic [1:0] id;
  logic signed [FLOAT_SIZE-1:0] data;
} PE_C_Result;

typedef struct packed  {
  logic valid;
  logic phase;
  logic [1:0] id;
  logic [1:0] skip_id;
} PE_C_Inter_Req;

typedef struct packed  {
  logic [1:0] pos_0;
  logic [1:0] pos_1;
} PE_D_Output;


endpackage: SPARQ_PKG

