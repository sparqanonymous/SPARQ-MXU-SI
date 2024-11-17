
#include "sparq_testbench.h"
#include <iostream>
#include <random>
#include <cmath>


extern vluint64_t main_cycle;

void SparqTestBench::Control_Wait(uint32_t cycles)  {
  CommandDataPort command;
  command.valid = 1;
  command.command = 0;
  command.command_data0 = 0;
  command.command_data1 = 0;
  for(int i = 0; i < cycles; i ++)
    host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command);
}

void SparqTestBench::Control_WaitforIdle(uint32_t type)  {
  wait_host_command_flush();

  Control_Wait(4);

  wait_host_command_flush();


  while(true) {
    if(type == WAIT_STATE_AXI_A_IN) {
      host_getstates(GET_STATE_TYPE);
      if(host_stateport0 == 0)  break;
    }
    else if(type == WAIT_STATE_AXI_A_META_IN) {
      host_getstates(GET_STATE_TYPE);
      if(host_stateport1 == 0)  break;
    }
    else if(type == WAIT_STATE_AXI_B_IN) {
      host_getstates(GET_STATE_TYPE);
      if(host_stateport2 == 0)  break;
    }
    else if(type == WAIT_STATE_AXI_C_IN) {
      host_getstates(GET_STATE_TYPE);
      if(host_stateport3 == 0)  break;
    }
    else if(type == WAIT_STATE_AXI_C_OUT) {
      host_getstates(GET_STATE_TYPE);
      if(host_stateport4 == 0)  break;
    }
    else if(type == WAIT_STATE_PEIN) {
      host_getstates(GET_STATE_TYPE);
      if(host_stateport5 == 0)  break;
    }
    else if(type == WAIT_STATE_PEOUT) {
      host_getstates(GET_STATE_TYPE);
      if(host_stateport6 == 0)  break;
    }
    else if(type == WAIT_STATE_7) {
      host_getstates(GET_STATE_TYPE);
      if(host_stateport7 == 0)  break;
    }
  }
}

void SparqTestBench::Control_Load_A(uint32_t axi_addr, uint32_t size, uint32_t chunks, uint32_t interval, uint32_t addr_to)  {
  CommandDataPort command;
  command.valid = 1;

  command.command = COMMAND_AXI_A_LOAD0;
  command.command_data0 = addr_to;
  command.command_data1 = 0;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command);
  
  command.command = COMMAND_AXI_A_LOAD1;
  command.command_data0 = axi_addr;
  command.command_data1 = size ;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command);
  
  command.command = COMMAND_AXI_A_LOAD2;
  command.command_data0 = chunks;
  command.command_data1 = interval;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command);
  
  Control_Wait(4);
  
  std::cout << "As cycle: " << main_cycle <<std::endl;
  Control_WaitforIdle(WAIT_STATE_AXI_A_IN);    
  std::cout << "Ae cycle: " << main_cycle <<std::endl;
}

void SparqTestBench::Control_Load_A_meta(uint32_t axi_addr, uint32_t size, uint32_t chunks, uint32_t interval, uint32_t addr_to)  {
  CommandDataPort command;
  command.valid = 1;

  command.command = COMMAND_AXI_A_META_LOAD0;
  command.command_data0 = addr_to;
  command.command_data1 = 0;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command);
  
  command.command = COMMAND_AXI_A_META_LOAD1;
  command.command_data0 = axi_addr;
  command.command_data1 = size ;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command);
  
  command.command = COMMAND_AXI_A_META_LOAD2;
  command.command_data0 = chunks;
  command.command_data1 = interval;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command);
  
  Control_Wait(4);
  
  std::cout << "As cycle: " << main_cycle <<std::endl;
  Control_WaitforIdle(WAIT_STATE_AXI_A_META_IN);    
  std::cout << "Ae cycle: " << main_cycle <<std::endl;
}


void SparqTestBench::Control_Load_B(uint32_t axi_addr, uint32_t size, uint32_t chunks, uint32_t interval, uint32_t addr_to)  {
  CommandDataPort command;
  command.valid = 1;

  command.command = COMMAND_AXI_B_LOAD0;
  command.command_data0 = addr_to;
  command.command_data1 = 0;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command);
  
  command.command = COMMAND_AXI_B_LOAD1;
  command.command_data0 = axi_addr;
  command.command_data1 = size ;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command);
  
  command.command = COMMAND_AXI_B_LOAD2;
  command.command_data0 = chunks;
  command.command_data1 = interval;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command);
  
  Control_Wait(4);
  
  std::cout << "As cycle: " << main_cycle <<std::endl;
  Control_WaitforIdle(WAIT_STATE_AXI_B_IN);    
  std::cout << "Ae cycle: " << main_cycle <<std::endl;
}

void SparqTestBench::Control_Load_C(uint32_t axi_addr, uint32_t size, uint32_t chunks, uint32_t interval, uint32_t addr_to)  {
  CommandDataPort command;
  command.valid = 1;

  command.command = COMMAND_AXI_C_LOAD0;
  command.command_data0 = addr_to;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command);
  
  command.command = COMMAND_AXI_C_LOAD1;
  command.command_data0 = axi_addr;
  command.command_data1 = size ;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command);
  
  command.command = COMMAND_AXI_C_LOAD2;
  command.command_data0 = chunks;
  command.command_data1 = interval;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command);
  
  Control_Wait(4);
  
  std::cout << "As cycle: " << main_cycle <<std::endl;
  Control_WaitforIdle(WAIT_STATE_AXI_C_IN);    
  std::cout << "Ae cycle: " << main_cycle <<std::endl;
}

void SparqTestBench::Control_Store_C(uint32_t axi_addr, uint32_t size, uint32_t chunks, uint32_t interval, uint32_t addr_from)  {
  CommandDataPort command;
  command.valid = 1;

  command.command = COMMAND_AXI_C_STORE0;
  command.command_data0 = addr_from;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command);

  command.command = COMMAND_AXI_C_STORE1;
  command.command_data0 = axi_addr;
  command.command_data1 = size;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command);
  
  command.command = COMMAND_AXI_C_STORE2;
  command.command_data0 = chunks;
  command.command_data1 = interval;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command);
  
  Control_WaitforIdle(WAIT_STATE_AXI_C_OUT);    
}



void SparqTestBench::Control_GEMM(  
  uint32_t  buffer_a_base_addr,
  uint32_t  buffer_b_base_addr,
  uint32_t  buffer_c_base_addr,
  uint32_t  reset_accum,
  uint32_t  buffer_a_size
) {
  CommandDataPort command;
  command.valid = 1;

  command.command = COMMAND_GEMM0;
  command.command_data0 = buffer_a_base_addr;
  command.command_data1 = buffer_b_base_addr;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command); 

  command.command = COMMAND_GEMM1;
  command.command_data0 = buffer_c_base_addr;
  command.command_data1 = reset_accum;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command); 

  command.command = COMMAND_GEMM2;
  command.command_data0 = buffer_a_size;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command); 

  std::cout << "GEMMStart cycle: " << main_cycle <<std::endl;
  Control_WaitforIdle(WAIT_STATE_PEIN);  
  Control_WaitforIdle(WAIT_STATE_PEOUT);  
  std::cout << "GEMMEnd cycle: " << main_cycle <<std::endl;
}

void SparqTestBench::gemm(uint32_t dim_1, uint32_t dim_2,uint32_t dim_3, uint32_t addrA, uint32_t addrB, uint32_t addrC, uint32_t addrA_meta) {
  int out_slices = dim_3 / ARRAY_DIMENSION; //assum even division
  int mid_slices = dim_2 / ARRAY_DIMENSION;

  printf("out_slices %d, mid_slices %d\n",out_slices,mid_slices);

  for (int out_i = 0; out_i < out_slices; out_i ++) {
    for (int mid_i = 0; mid_i < mid_slices; mid_i ++) {
      Control_Load_A(
        addrA + mid_i * ARRAY_DIMENSION /2,
        ARRAY_DIMENSION /2,        
        dim_1 /2,
        dim_2 /2,
        0
      );

      Control_Load_A_meta(
        addrA_meta + mid_i * ARRAY_DIMENSION /2 * sizeof(uint8_t),
        ARRAY_DIMENSION /2,        
        dim_1 /4,
        dim_2 /2,
        0
      );
      
      Control_Load_B(
        addrB + out_i * ARRAY_DIMENSION * sizeof(uint16_t) + mid_i * ARRAY_DIMENSION * dim_3 * sizeof(uint16_t),
        ARRAY_DIMENSION * sizeof(uint16_t),
        ARRAY_DIMENSION,
        dim_3 * sizeof (uint16_t),
        0
      );

      Control_GEMM(
        0, 0, 0, 
        (mid_i == 0) ? 1 : 0,
        dim_1
      );
    }
    Control_Store_C(
      addrC + out_i * ARRAY_DIMENSION * sizeof(uint16_t),
      ARRAY_DIMENSION * sizeof(uint16_t),  
      dim_1,
      dim_3 * sizeof (uint16_t),
      0
    ); 
    Control_Wait(ARRAY_DIMENSION);
  }
}


void SparqTestBench::host_function()  {
  prepare_ext_data(DIM_1,DIM_2,DIM_3,DRAM_ADDR_A,DRAM_ADDR_B,DRAM_ADDR_A_META);

  CommandDataPort command;

  Control_Wait(200+ARRAY_DIMENSION);

  command.valid = 1;  
  command.command = COMMAND_PE_RESET;
  host_setcommand(COMMAND_TYPE_COMMANDDATAPORT,command);

  Control_Wait(ARRAY_DIMENSION);
  
  gemm(DIM_1,DIM_2,DIM_3,DRAM_ADDR_A,DRAM_ADDR_B,DRAM_ADDR_C,DRAM_ADDR_A_META);
  
  host_setcommand(COMMAND_TYPE_STOP,command);    

  compare_result(DIM_1,DIM_3,DRAM_ADDR_C);
}

float convert_from_fp16_uint(uint16_t h) {
    uint32_t sign = (h >> 15) & 0x1;
    int exponent = (h >> 10) & 0x1F;
    uint32_t mantissa = h & 0x3FF;

    uint32_t fp32 = sign << 31;

    if (exponent == 0) {
        if (mantissa == 0) {
            // Zero
            // fp32 remains as zero with only the sign bit possibly set
        } else {
            // Subnormal
            exponent = 1;  // Start from the smallest exponent in FP32
            while (!(mantissa & 0x400)) {
                mantissa <<= 1;
                exponent--;
            }
            mantissa &= 0x3FF;  // Remove the leading one
            exponent += 127 - 15;  // Adjust exponent from FP16 to FP32 bias
            fp32 |= (exponent << 23) | (mantissa << 13);
        }
    } else if (exponent == 31) {
        // Infinity or NaN
        fp32 |= 0x7F800000 | (mantissa << 13);
    } else {
        // Normalized number
        exponent += 127 - 15;  // Adjust the exponent from FP16 to FP32
        fp32 |= (exponent << 23) | (mantissa << 13);
    }

    return *((float*)&fp32);
}

uint16_t convert_to_fp16_uint(float f) {
    uint32_t fp32 = *((uint32_t*)&f);
    uint32_t sign = (fp32 >> 31) & 0x1;
    int exponent = ((fp32 >> 23) & 0xFF) - 127;
    uint32_t mantissa = fp32 & 0x7FFFFF;

    uint16_t fp16_val = 0;

    if (exponent > 15) {
        // Exponent overflow, set as infinity or max normal
        exponent = 31;
        mantissa = 0;
        fp16_val = (sign << 15) | (exponent << 10) | mantissa;
    } else if (exponent < -14) {
        // Subnormal or zero
        mantissa |= 0x800000;  // Restore the implicit leading one
        int shift = -14 - exponent;  // Additional shift for subnormal range
        if (shift < 24) {
            mantissa >>= shift;
        } else {
            mantissa = 0;
        }
        mantissa >>= 13;  // Shift for fp16 mantissa alignment
        fp16_val = (sign << 15) | mantissa;  // Exponent is zero for subnormals
    } else {
        // Normalized case
        exponent += 15;
        mantissa >>= 13;
        fp16_val = (sign << 15) | (exponent << 10) | mantissa;
    }

    return fp16_val;
}

float gen_random_float(
  std::mt19937 &gen,
  std::normal_distribution<float> &d
) {
  float val = d(gen);  
  return val;
}

int8_t gen_random_int() {
  int8_t val;
  if(rand() %2 == 0) {
    val = rand() % 7;
  }
  else {
    val = -(rand() % 8);
  }

  return val;
}


void SparqTestBench::prepare_ext_data(uint32_t dim_1, uint32_t dim_2,uint32_t dim_3, uint32_t addrA, uint32_t addrB, uint32_t addrA_meta) {
  srand(100);

  std::mt19937 gen{100};
  std::normal_distribution<float> d{0.0, 2.0};

  mat_A = (int8_t*)malloc( dim_1 * dim_2 * sizeof(int8_t) );
  mat_A_compressed = (int8_t*)malloc( (dim_1/2) * dim_2 * sizeof(int8_t) );
  mat_A_meta = (uint8_t*)malloc( (dim_1/4) * (dim_2/2) * sizeof(uint8_t) );
  mat_B = (float*)malloc( dim_2 * dim_3 * sizeof(float) );
  mat_C = (float*)malloc( dim_1 * dim_3 * sizeof(float) );
  mat_C_ref = (float*)malloc( dim_1 * dim_3 * sizeof(float) );

  mtx.lock();
  printf("A:\n");
  for (int i1 = 0 ; i1 < dim_1; i1++)  {
    for (int i2 = 0 ; i2 < dim_2; i2++)  {
      int8_t val = gen_random_int();
      mat_A[i1 * dim_2 + i2] = val;
      printf("%d ",val);
    }
    printf("\n");
  }


  for (int i2 = 0 ; i2 < dim_2; i2++)  {
    for (int i1 = 0 ; i1 < dim_1; i1+=4)  {
      uint8_t sparse_type = rand() % 6;
      uint8_t phase = (i1/4) % 2 ;
      uint8_t id_0, id_1, skip_id_0, skip_id_1 = 0;
      switch(sparse_type) {
        case 0: id_0 = 0; id_1 = 1; skip_id_0 = 2, skip_id_1 = 3; break;
        case 1: id_0 = 0; id_1 = 2; skip_id_0 = 1, skip_id_1 = 3; break;
        case 2: id_0 = 0; id_1 = 3; skip_id_0 = 1, skip_id_1 = 2; break;
        case 3: id_0 = 1; id_1 = 2; skip_id_0 = 0, skip_id_1 = 3; break;
        case 4: id_0 = 1; id_1 = 3; skip_id_0 = 0, skip_id_1 = 2; break;
        case 5: id_0 = 2; id_1 = 3; skip_id_0 = 0, skip_id_1 = 1; break;
      }

      mat_A_compressed[ (i1/2 + 0) * dim_2 + i2 ] = mat_A[ (i1+id_0) * dim_2 + i2 ];
      mat_A_compressed[ (i1/2 + 1) * dim_2 + i2 ] = mat_A[ (i1+id_1) * dim_2 + i2 ];
      mat_A[ (i1+skip_id_0) * dim_2 + i2 ] = 0;
      mat_A[ (i1+skip_id_1) * dim_2 + i2 ] = 0;
      mat_A_meta[ i1/4 * dim_2 + i2 ] = sparse_type;
    }
  }

  printf("saving A dram contents:\n");
  for (int i1 = 0 ; i1 < dim_1/2; i1++)  {
    for (int i2 = 0 ; i2 < dim_2/2; i2++)  {
      int8_t val0 = mat_A_compressed[ i1 * dim_2 + i2*2 + 0 ];
      int8_t val1 = mat_A_compressed[ i1 * dim_2 + i2*2 + 1 ];
      uint8_t ival = (((uint8_t)val1 << 4) & 0xF0) | ((uint8_t)val0 & 0xF);
      dram_contents[addrA + i1 * dim_2 / 2 + i2 ] = ival;

      printf("%x %x ",val0,val1);
    }
    printf("\n");
  }

  printf("saving A meta dram contents:\n");
  for (int i1 = 0 ; i1 < dim_1/4; i1++)  {
    for (int i2 = 0 ; i2 < dim_2/2; i2++)  {
      uint8_t val0 = mat_A_meta[ i1 * dim_2 + i2*2 + 0 ];
      uint8_t val1 = mat_A_meta[ i1 * dim_2 + i2*2 + 1 ];
      uint8_t ival = (((uint8_t)val1 << 4) & 0xF0) | ((uint8_t)val0 & 0xF);
      dram_contents[addrA_meta + i1 * dim_2 / 2 + i2 ] = ival;

      printf("%x %x ",val0,val1);
    }
    printf("\n");
  }


  printf("A Sparse:\n");
  for (int i1 = 0 ; i1 < dim_1; i1++)  {
    for (int i2 = 0 ; i2 < dim_2; i2++)  {
      int8_t val = mat_A[i1 * dim_2 + i2];
      printf("%d ",val);
    }
    printf("\n");
  }

  printf("A Compressed:\n");
  for (int i1 = 0 ; i1 < dim_1/2; i1++)  {
    for (int i2 = 0 ; i2 < dim_2; i2++)  {
      int8_t val = mat_A_compressed[i1 * dim_2 + i2];
      printf("%d ",val);
    }
    printf("\n");
  }


  printf("A dram contents:\n");
  for (int i1 = 0 ; i1 < dim_1/2; i1++)  {
    for (int i2 = 0 ; i2 < dim_2/2; i2++)  {
      uint8_t val = get_dram_contents(addrA + i1 * dim_2 /2 + i2);

      printf("%x %x ",val&0xF,(val>>4)& 0xF);
    }
    printf("\n");
  }

  printf("A meta dram contents:\n");
  for (int i1 = 0 ; i1 < dim_1/4; i1++)  {
    for (int i2 = 0 ; i2 < dim_2/2; i2++)  {
      uint8_t val = get_dram_contents(addrA_meta + i1 * dim_2 /2 + i2);

      printf("%x %x ",val&0xF,(val>>4)& 0xF);
    }
    printf("\n");
  }


  printf("B:\n");
  for (int i2 = 0 ; i2 < dim_2; i2++)  {
    for (int i3 = 0 ; i3 < dim_3; i3++)  {
      float val = gen_random_float(gen,d);
      
      mat_B[i2 * dim_3 + i3] = val;

      uint16_t ival = convert_to_fp16_uint(val);
      dram_contents[addrB + (i2 * dim_3 + i3) * sizeof(uint16_t) + 0] = (ival >> 0) & 0xFF;
      dram_contents[addrB + (i2 * dim_3 + i3) * sizeof(uint16_t) + 1] = (ival >> 8) & 0xFF;

      printf("%f ",val);
    }
    printf("\n");
  }

  printf("C:\n");
  for (int i1 = 0 ; i1 < dim_1; i1++)  {
    for (int i3 = 0 ; i3 < dim_3; i3++)  {
      float res = 0;
      for (int i2 = 0 ; i2 < dim_2; i2++)  {
        res += mat_A[i1 * dim_2 + i2] * mat_B[i2 * dim_3 + i3];
      }
      mat_C_ref[i1 * dim_3 + i3] = res;
      printf("%f ",res);
    }
    printf("\n");
  }
  mtx.unlock();
}

void SparqTestBench::compare_result(uint32_t dim_1, uint32_t dim_3, uint32_t addrC) {
  printf("res C:\n");
  for (int i1 = 0 ; i1 < dim_1; i1++)  {
    for (int i3 = 0 ; i3 < dim_3; i3++)  {
      uint8_t v0 = get_dram_contents(addrC + (i1 * dim_3 + i3)*sizeof(uint16_t) + 0);
      uint8_t v1 = get_dram_contents(addrC + (i1 * dim_3 + i3)*sizeof(uint16_t) + 1);
      uint16_t v = (v1 << 8) | (v0);
      float vs = convert_from_fp16_uint(v);

      mat_C[i1 * dim_3 + i3] = vs;
      printf("%f ",vs);
    }
    printf("\n");
  }

  for (int i1 = 0 ; i1 < dim_1; i1++)  {
    for (int i3 = 0 ; i3 < dim_3; i3++)  {
      float v = mat_C[i1 * dim_3 + i3];
      float ref_v = mat_C_ref[i1 * dim_3 + i3];

      float rel_diff;
      
      if (ref_v == 0.0 || v == 0.0) 
        rel_diff = (ref_v-v) ;
      else 
        rel_diff = ((ref_v-v ) / ref_v);

      if (rel_diff < 0.0) rel_diff = - rel_diff;

      if( rel_diff >= 0.01 ) 
        printf("Result mismatch (%d,%d) v:%f - ref:%f rel_diff:%f\n",i1,i3,v,ref_v,rel_diff);      
      // else
      //   printf("Result match (%d,%d) v:%f - ref:%f rel_diff:%f\n",i1,i3,v,ref_v,rel_diff);
    }
  }
}

