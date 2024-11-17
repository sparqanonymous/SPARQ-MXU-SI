`timescale 1 ns / 1 ns

`include "defines.vh"

import SPARQ_PKG::*;

module InterPEBuffer #(
		parameter ID_V        = 0,
		parameter ID_H        = 0
	) (
		input logic			  clk,	
    input PE_C_Result    Cside_out_input0,    
    input PE_C_Result    Cside_out_input1,    
    output PE_C_Result   Cside_out_output0,
    output PE_C_Result   Cside_out_output1,
    input PE_C_Inter_Req Cside_inter_req_input,
    input PE_D_Output    Dside_out_input,
    output PE_D_Output   Dside_out_output
	);
  
  typedef struct packed {
    PE_C_Result [3:0] c_inter;
    logic c_inter_pos;
    PE_D_Output dside_out_buf;
    PE_C_Inter_Req Cside_inter_req_input;
  } Registers;
  
  Registers reg_current,reg_next;
  
  PE_C_Result   Cside_out_output1_next;
  
  always_comb begin
    reg_next = reg_current;

    Cside_out_output0 = '{default:'0};
    Cside_out_output1_next = '{default:'0};

    reg_next.dside_out_buf = Dside_out_input;

    reg_next.Cside_inter_req_input = Cside_inter_req_input;
    
    Dside_out_output.pos_0 = 0;
    Dside_out_output.pos_1 = 0;

    if(ID_H == 0)  begin        
      if(reg_current.Cside_inter_req_input.valid) begin
        for(int j = 0; j < 4; j ++) begin          
          if( reg_current.c_inter[j].command == PE_COMMAND_NORMAL && 
              reg_current.Cside_inter_req_input.id == reg_current.c_inter[j].id && 
              reg_current.Cside_inter_req_input.phase == reg_current.c_inter[j].phase
            ) begin
            Cside_out_output0 = reg_current.c_inter[j];
            reg_next.c_inter[j] = Cside_out_input0;

            Dside_out_output.pos_0 = j;
          end

          if( reg_current.c_inter[j].command == PE_COMMAND_NORMAL && 
              reg_current.Cside_inter_req_input.skip_id == reg_current.c_inter[j].id && 
              reg_current.Cside_inter_req_input.phase == reg_current.c_inter[j].phase
            ) begin
            Cside_out_output1_next = reg_current.c_inter[j];
            reg_next.c_inter[j] = Cside_out_input1;

            Dside_out_output.pos_1 = j;
          end
        end
      end
      else begin
        if(reg_current.c_inter_pos != 0) begin
          reg_next.c_inter[0] = Cside_out_input0;
          reg_next.c_inter[1] = Cside_out_input1;
          Dside_out_output.pos_0 = 0;
          Dside_out_output.pos_1 = 1;
        end
        else begin
          reg_next.c_inter[2] = Cside_out_input0;
          reg_next.c_inter[3] = Cside_out_input1;
          Dside_out_output.pos_0 = 2;
          Dside_out_output.pos_1 = 3;
        end
        reg_next.c_inter_pos = ~reg_current.c_inter_pos;
      end
    end
    else begin
      reg_next.dside_out_buf = Dside_out_input;
      Cside_out_output0 = reg_current.c_inter[reg_current.dside_out_buf.pos_0];
      Cside_out_output1_next = reg_current.c_inter[reg_current.dside_out_buf.pos_1];
      reg_next.c_inter[reg_current.dside_out_buf.pos_0] = Cside_out_input0;
      reg_next.c_inter[reg_current.dside_out_buf.pos_1] = Cside_out_input1;
      Dside_out_output = reg_current.dside_out_buf;
    end
    
    // Dside_out_output = reg_current.dside_out_buf;
  end
           
  always @ (posedge clk) begin
    reg_current <= reg_next;
    Cside_out_output1 <= Cside_out_output1_next;
	end
endmodule
