`ifndef __DEFINES_VH__ 
`define __DEFINES_VH__

`define CEIL(x,y) (((x) + (y) -1)/(y))
`define CEILDIV(x,y) (((x) + (y) -1)/(y))
`define MAX(x,y) ( ( (x) > (y) ) ? (x) : (y) )
`define MIN(x,y) ( ( (x) < (y) ) ? (x) : (y) )

`define AXI_OUTPUT_IDLE       '{default:'0, arburst:2'b01, arsize : 3'b011, awburst : 2'b01, awsize : 3'b011, bready : 1'b1, rready : 1'b1, wstrb : '1}
 
 
`endif //__DEFINES_VH__