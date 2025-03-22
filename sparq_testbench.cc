
#include "sparq_testbench.h" 
#include "Vsparq_top.h"
#include <iostream>

void SparqTestBench::host_getstates(int type) {
  mtx.lock();
  mtx.unlock();
  state_ready = false;
  state_id_req = type;
  std::this_thread::yield();

  while(1) {
    mtx.lock();
    if(state_ready) {
      mtx.unlock();
      return;
    }

    mtx.unlock();
    std::this_thread::yield();
  }
}

void SparqTestBench::host_setcommand(int type, CommandDataPort command)  {
  usleep(100+rand()%100);
  mtx.lock();
  command_dataport_queue.push(command);
  command_type_queue.push(type);
  mtx.unlock();
}

void SparqTestBench::wait_host_command_flush()  {  
  usleep(100+rand()%100);
  mtx.lock();
  while(!command_type_queue.empty()) {
    mtx.unlock();
    usleep(100+rand()%100);
    mtx.lock();
  }
  mtx.unlock();
}

void SparqTestBench::host_setdebug(int type, uint16_t id_v, uint16_t id_h, uint32_t debug)  {
  mtx.lock();
  CommandDataPort debug_command;
  debug_command.command = type;
  debug_command.command_data0 = id_v << 16 | id_h;
  debug_command.command_data1 = debug;
  command_dataport_queue.push(debug_command);
  command_type_queue.push(COMMAND_TYPE_DEBUG);
  mtx.unlock();
}


SparqTestBench::SparqTestBench(Vsparq_top* _top) 
  : top(_top)
  {
  
  cdp_zero.valid = 0;
  cdp_zero.command = 0;
  cdp_zero.command_data0 = 0;
  cdp_zero.command_data1 = 0;

  stop_cycle = -1;

}


void SparqTestBench::initialize() {
  axi_A_load_chunks = 0;
  axi_A_load_chunk_idx = 0;
  axi_A_meta_load_chunks = 0;
  axi_A_meta_load_chunk_idx = 0;
  axi_B_load_chunks = 0;
  axi_B_load_chunk_idx = 0;
  axi_C_load_chunks = 0;
  axi_C_load_chunk_idx = 0;
  axi_C_store_chunks = 0;
  axi_C_store_chunk_idx = 0;

  // Initial input values
  top->clk = 0;
  top->rstn = 1;
  top->flat_axi_A_in_valid = 0;
  top->flat_axi_A_meta_in_valid = 0;
  top->flat_axi_B_in_valid = 0;
  top->flat_axi_C_in_valid = 0;
  top->flat_axi_C_out_ready = 1;

  cdp_zero.ConvertToPort(top->commanddataport);
  
  #if ARRAY_DIMENSION <= 16
    top->flat_axi_A_in_data = 0;
  #else
    for(int i = 0; i < AXI_A_IN_SIZE_BYTES/sizeof(WData); i ++) { 
      top->flat_axi_A_in_data[i] = 0;
    }  
  #endif

  #if ARRAY_DIMENSION <= 16
    top->flat_axi_A_meta_in_data = 0;
  #else
    for(int i = 0; i < AXI_A_META_IN_SIZE_BYTES/sizeof(WData); i ++) { 
      top->flat_axi_A_meta_in_data[i] = 0;
    }  
  #endif


  #if ARRAY_DIMENSION <= 4
    top->flat_axi_B_in_data = 0;
  #else
    for(int i = 0; i < AXI_B_IN_SIZE_BYTES/sizeof(WData); i ++) { 
      top->flat_axi_B_in_data[i] = 0;
    }  
  #endif

  #if ARRAY_DIMENSION <= 4
    top->flat_axi_C_in_data = 0;
  #else
    for(int i = 0; i < AXI_C_IN_SIZE_BYTES/sizeof(WData); i ++) { 
       top->flat_axi_C_in_data[i] = 0;
    }  
  #endif
  
  host_thread = std::thread(&SparqTestBench::host_function, this);
}

bool SparqTestBench::step_cycle(vluint64_t cycle) {
  //reset
  top->rstn = 1;
  if(cycle < 20)  top->rstn = 0;


  //handle AXI requests
  auto commanddataport_axi_A = CommandDataPort::ConvertFromPort(top->commanddataport_axi_A);
  if(commanddataport_axi_A.valid) {
    if(commanddataport_axi_A.command == COMMAND_AXI_A_LOAD1) {
      axi_A_load_addr = commanddataport_axi_A.command_data0;
      axi_A_load_size = commanddataport_axi_A.command_data1;
    }
    else if(commanddataport_axi_A.command == COMMAND_AXI_A_LOAD2) {
      axi_A_load_chunks = commanddataport_axi_A.command_data0;
      axi_A_load_interval = commanddataport_axi_A.command_data1;
    
      axi_A_load_base = axi_A_load_addr;
      axi_A_load_chunk_idx = 0;
      axi_A_load_pos = 0;

      printf("commanddataport_axi_A COMMAND_AXI_A_LOAD2 axi_A_load_addr:%x axi_A_load_size:%x axi_A_load_interval:%x axi_A_load_chunks:%d\n",axi_A_load_addr,axi_A_load_size,axi_A_load_interval,axi_A_load_chunks);      
    }
  }

  auto commanddataport_axi_A_meta = CommandDataPort::ConvertFromPort(top->commanddataport_axi_A_meta);
  if(commanddataport_axi_A_meta.valid) {
    if(commanddataport_axi_A_meta.command == COMMAND_AXI_A_META_LOAD1) {
      axi_A_meta_load_addr = commanddataport_axi_A_meta.command_data0;
      axi_A_meta_load_size = commanddataport_axi_A_meta.command_data1;
    }
    else if(commanddataport_axi_A_meta.command == COMMAND_AXI_A_META_LOAD2) {
      axi_A_meta_load_chunks = commanddataport_axi_A_meta.command_data0;
      axi_A_meta_load_interval = commanddataport_axi_A_meta.command_data1;
    
      axi_A_meta_load_base = axi_A_meta_load_addr;
      axi_A_meta_load_chunk_idx = 0;
      axi_A_meta_load_pos = 0;

      printf("commanddataport_axi_A_meta COMMAND_AXI_A_META_LOAD2 axi_A_meta_load_addr:%x axi_A_meta_load_size:%x axi_A_meta_load_interval:%x axi_A_meta_load_chunks:%d\n",axi_A_meta_load_addr,axi_A_meta_load_size,axi_A_meta_load_interval,axi_A_meta_load_chunks);      
    }
  }

  auto commanddataport_axi_B = CommandDataPort::ConvertFromPort(top->commanddataport_axi_B);
  if(commanddataport_axi_B.valid) {
    if(commanddataport_axi_B.command == COMMAND_AXI_B_LOAD1) {
      axi_B_load_addr = commanddataport_axi_B.command_data0;
      axi_B_load_size = commanddataport_axi_B.command_data1;
    }
    else if(commanddataport_axi_B.command == COMMAND_AXI_B_LOAD2) {
      axi_B_load_chunks = commanddataport_axi_B.command_data0;
      axi_B_load_interval = commanddataport_axi_B.command_data1;
    
      axi_B_load_base = axi_B_load_addr;
      axi_B_load_chunk_idx = 0;
      axi_B_load_pos = 0;

      printf("commanddataport_axi_B COMMAND_AXI_B_LOAD2 axi_B_load_addr:%x axi_B_load_size:%x axi_B_load_interval:%x axi_B_load_chunks:%d\n",axi_B_load_addr,axi_B_load_size,axi_B_load_interval,axi_B_load_chunks);      
    }
  }
  
  auto commanddataport_axi_C = CommandDataPort::ConvertFromPort(top->commanddataport_axi_C);
  if(commanddataport_axi_C.valid) {
    if(commanddataport_axi_C.command == COMMAND_AXI_C_LOAD1) {
      axi_C_load_addr = commanddataport_axi_C.command_data0;
      axi_C_load_size = commanddataport_axi_C.command_data1;
    }
    else if(commanddataport_axi_C.command == COMMAND_AXI_C_LOAD2) {
      axi_C_load_chunks = commanddataport_axi_C.command_data0;
      axi_C_load_interval = commanddataport_axi_C.command_data1;
    
      axi_C_load_base = axi_C_load_addr;
      axi_C_load_chunk_idx = 0;
      axi_C_load_pos = 0;

      printf("commanddataport_axi_C COMMAND_AXI_C_LOAD2 axi_C_load_addr:%x axi_C_load_size:%x axi_C_load_interval:%x axi_C_load_chunks:%d\n",axi_C_load_addr,axi_C_load_size,axi_C_load_interval,axi_C_load_chunks);
    }
    else if(commanddataport_axi_C.command == COMMAND_AXI_C_STORE1) {
      axi_C_store_addr = commanddataport_axi_C.command_data0;
      axi_C_store_size = commanddataport_axi_C.command_data1;
    }
    else if(commanddataport_axi_C.command == COMMAND_AXI_C_STORE2) {
      axi_C_store_chunks = commanddataport_axi_C.command_data0;
      axi_C_store_interval = commanddataport_axi_C.command_data1;

      axi_C_store_base = axi_C_store_addr;
      axi_C_store_chunk_idx = 0;
      axi_C_store_pos = 0;
    }
  }
  
  
  //feed axi in data
  top->flat_axi_A_in_valid = 0;
  if(axi_A_load_chunk_idx < axi_A_load_chunks) {
    mtx.lock();
    top->flat_axi_A_in_valid = 1;    

    #if ARRAY_DIMENSION <= 8
      IData v32 = 0;
      for(int j = 0; j < ARRAY_DIMENSION/2; j ++) {                        
        uint8_t v = get_dram_contents(axi_A_load_base + axi_A_load_pos + j);
        v32 |= (IData)v << j*8;   
      }
      top->flat_axi_A_in_data = v32;
    #elif ARRAY_DIMENSION == 16
      QData v64 = 0;
      for(int j = 0; j < sizeof(v64); j ++) {                        
        uint8_t v = get_dram_contents(axi_A_load_base + axi_A_load_pos + j);
        v64 |= (QData)v << j*8;   
      }
      top->flat_axi_A_in_data = v64;
    #else
    for(int i = 0; i < AXI_A_IN_SIZE_BYTES/sizeof(WData); i ++) {
      WData v64 = 0;
      for(int j = 0; j < sizeof(WData); j ++) {                        
        uint8_t v = get_dram_contents(axi_A_load_base + axi_A_load_pos + i*sizeof(WData) + j);
        v64 |= (WData)v << j*8;   
      }
      top->flat_axi_A_in_data[i] = v64;
    }
    #endif

    axi_A_load_pos += AXI_A_IN_SIZE_BYTES;

    if(axi_A_load_pos == axi_A_load_size) {
      axi_A_load_base += axi_A_load_interval;
      axi_A_load_pos = 0;

      axi_A_load_chunk_idx += 1;
    } 
    mtx.unlock();
  }

  top->flat_axi_A_meta_in_valid = 0;
  if(axi_A_meta_load_chunk_idx < axi_A_meta_load_chunks) {
    mtx.lock();
    top->flat_axi_A_meta_in_valid = 1;    

    #if ARRAY_DIMENSION <= 8
      IData v32 = 0;
      for(int j = 0; j < ARRAY_DIMENSION/2; j ++) {                        
        uint8_t v = get_dram_contents(axi_A_meta_load_base + axi_A_meta_load_pos + j);
        v32 |= (IData)v << j*8;   
      }
      top->flat_axi_A_meta_in_data = v32;
    #elif ARRAY_DIMENSION == 16
      QData v64 = 0;
      for(int j = 0; j < sizeof(v64); j ++) {                        
        uint8_t v = get_dram_contents(axi_A_meta_load_base + axi_A_meta_load_pos + j);
        v64 |= (QData)v << j*8;   
      }
      top->flat_axi_A_meta_in_data = v64;
    #else
    for(int i = 0; i < AXI_A_META_IN_SIZE_BYTES/sizeof(WData); i ++) {
      WData v64 = 0;
      for(int j = 0; j < sizeof(WData); j ++) {                        
        uint8_t v = get_dram_contents(axi_A_meta_load_base + axi_A_meta_load_pos + i*sizeof(WData) + j);
        v64 |= (WData)v << j*8;   
      }
      top->flat_axi_A_meta_in_data[i] = v64;
    }
    #endif

    axi_A_meta_load_pos += AXI_A_META_IN_SIZE_BYTES;

    if(axi_A_meta_load_pos == axi_A_meta_load_size) {
      axi_A_meta_load_base += axi_A_meta_load_interval;
      axi_A_meta_load_pos = 0;

      axi_A_meta_load_chunk_idx += 1;
    } 
    mtx.unlock();
  }

  top->flat_axi_B_in_valid = 0;
  if(axi_B_load_chunk_idx < axi_B_load_chunks) {
    mtx.lock();
    top->flat_axi_B_in_valid = 1;    

    #if ARRAY_DIMENSION == 2
      IData v32 = 0;
      for(int j = 0; j < sizeof(v32); j ++) {                        
        uint8_t v = get_dram_contents(axi_B_load_base + axi_B_load_pos + j);
        v32 |= (IData)v << j*8;   
      }
      top->flat_axi_B_in_data = v32;
    #elif ARRAY_DIMENSION == 4
      QData v64 = 0;
      for(int j = 0; j < sizeof(v64); j ++) {                        
        uint8_t v = get_dram_contents(axi_B_load_base + axi_B_load_pos + j);
        v64 |= (QData)v << j*8;   
      }
      top->flat_axi_B_in_data = v64;
    #else
    for(int i = 0; i < AXI_B_IN_SIZE_BYTES/sizeof(WData); i ++) {
      WData v64 = 0; 
      for(int j = 0; j < sizeof(WData); j ++) {                        
        uint8_t v = get_dram_contents(axi_B_load_base + axi_B_load_pos + i*sizeof(WData) + j);
        v64 |= (WData)v << j*8;   
      }
      top->flat_axi_B_in_data[i] = v64;
    }
    #endif

    axi_B_load_pos += AXI_B_IN_SIZE_BYTES;

    if(axi_B_load_pos == axi_B_load_size) {
      axi_B_load_base += axi_B_load_interval;
      axi_B_load_pos = 0;

      axi_B_load_chunk_idx += 1;
    } 
    mtx.unlock();
  }

  top->flat_axi_C_in_valid = 0;
  if(axi_C_load_chunk_idx < axi_C_load_chunks) {
    mtx.lock();
    top->flat_axi_C_in_valid = 1;    
    #if ARRAY_DIMENSION == 4
      QData v64 = 0; 
      for(int j = 0; j < sizeof(QData); j ++) {                        
        uint8_t v = get_dram_contents(axi_C_load_base + axi_C_load_pos + j);
        v64 |= (QData)v << j*8;   
      }

      top->flat_axi_C_in_data = v64;
    #else
    for(int i = 0; i < AXI_C_IN_SIZE_BYTES/sizeof(WData); i ++) {
      WData v64 = 0; 
      for(int j = 0; j < sizeof(WData); j ++) {                        
        uint8_t v = get_dram_contents(axi_C_load_base + axi_C_load_pos + i*sizeof(WData) + j);
        v64 |= (WData)v << j*8;   
      }

      top->flat_axi_C_in_data[i] = v64;
    }    
    #endif

    axi_C_load_pos += AXI_C_IN_SIZE_BYTES;

    if(axi_C_load_pos == axi_C_load_size) {
      axi_C_load_base += axi_C_load_interval;
      axi_C_load_pos = 0;

      axi_C_load_chunk_idx += 1;
    } 
    mtx.unlock();
  }


  //receive axi out data
  top->flat_axi_C_out_ready = 1;
  if(top->flat_axi_C_out_valid) {
    mtx.lock();
    #if ARRAY_DIMENSION == 4
      QData v64 = top->flat_axi_C_out_data;
      for(int j = 0; j < sizeof(QData); j ++) {        
        uint8_t v = (v64 >> 8*j) & 0xFF;
                
        dram_contents[axi_C_store_base + axi_C_store_pos++] = v;


        if(axi_C_store_pos == axi_C_store_size) {
          axi_C_store_base += axi_C_store_interval;
          axi_C_store_pos = 0;
          
          axi_C_store_chunk_idx += 1;
        }
      }
    #else
      for(int i = 0; i < AXI_C_OUT_SIZE_BYTES/sizeof(WData); i ++) {
        for(int j = 0; j < sizeof(WData); j ++) {        
          uint8_t v = (top->flat_axi_C_out_data[i] >> 8*j) & 0xFF;
                  
          dram_contents[axi_C_store_base + axi_C_store_pos++] = v;


          if(axi_C_store_pos == axi_C_store_size) {
            axi_C_store_base += axi_C_store_interval;
            axi_C_store_pos = 0;
            
            axi_C_store_chunk_idx += 1;
          }
        }
      }
    #endif
    mtx.unlock();
  }

  // get state 
  {
    mtx.lock();
    if(state_id_req == GET_STATE_TYPE) {
      host_stateport0 = top->stateport[7];
      host_stateport1 = top->stateport[6];
      host_stateport2 = top->stateport[5];
      host_stateport3 = top->stateport[4];
      host_stateport4 = top->stateport[3];
      host_stateport5 = top->stateport[2];
      host_stateport6 = top->stateport[1];
      host_stateport7 = top->stateport[0];
      state_ready = true;
    }
    mtx.unlock();
  }

  //set command
  {
    cdp_zero.ConvertToPort(top->commanddataport);
    
    mtx.lock();
    if(!command_type_queue.empty()) {
      int command_type = command_type_queue.front();
      CommandDataPort command = command_dataport_queue.front();
      command_type_queue.pop();
      command_dataport_queue.pop();

      if(command_type == COMMAND_TYPE_COMMANDDATAPORT) {
        command.ConvertToPort(top->commanddataport);
      }
      else if(command_type == COMMAND_TYPE_STOP) {
        stop_cycle = cycle + 100; //set stop cycle
      }
    }
    mtx.unlock();    
  }

  if(stop_cycle == cycle)  return false; //stop

  return true;
}

void SparqTestBench::finish() {
  host_thread.join();
}


uint8_t SparqTestBench::get_dram_contents(uint32_t addr) {
  std::map<uint32_t, uint8_t>::const_iterator it = dram_contents.find( addr );
  if ( it == dram_contents.end() ) {
    printf("Read from uninitialized DRAM addr:%x\n",addr);
    return 0;
  }
  else {
    return it->second;
  }
}

