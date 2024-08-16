#ifndef __SPARQ_TESTBENCH_H__
#define __SPARQ_TESTBENCH_H__

#include <verilated.h>
#include "Vsparq_top.h"


#include <queue>
#include <map>
#include <vector>
#include <thread>
#include <mutex>
#include <array>


#include "defines.h"

#define DRAM_ADDR_A 0x1000
#define DRAM_ADDR_B 0x2000
#define DRAM_ADDR_C 0x3000
#define DRAM_ADDR_A_META 0x4000
#define DIM_1 16
#define DIM_2 16
#define DIM_3 16


struct CommandDataPort {
  uint8_t valid;
  uint8_t command;
  uint32_t command_data0;
  uint32_t command_data1;

  static struct CommandDataPort ConvertFromPort(const WData* p_packed_val) {
  struct CommandDataPort val;
    val.command_data1 = p_packed_val[0];
    val.command_data0 = p_packed_val[1];
    val.command = p_packed_val[2] & 0xFF;
    val.valid = (p_packed_val[2] >> 8) & 0x1;
    return val;
  }

  void ConvertToPort(WData* p_packed_val) {
    p_packed_val[0] = command_data1;
    p_packed_val[1] = command_data0;
    p_packed_val[2] = command | (valid<<8);
  }
} ;



#define COMMAND_TYPE_COMMANDDATAPORT 1
#define COMMAND_TYPE_STOP 2
#define COMMAND_TYPE_DEBUG 3

#define DEBUG_TYPE_CONTROLLER 0
#define DEBUG_TYPE_PE 1
#define DEBUG_TYPE_ACCUM 2
#define DEBUG_TYPE_RESCALE 3
#define DEBUG_TYPE_RESADD 4
#define DEBUG_TYPE_AVGPOOL 5

#define GET_STATE_TYPE 1

#define WAIT_STATE_AXI_A_IN 0
#define WAIT_STATE_AXI_A_META_IN 1
#define WAIT_STATE_AXI_B_IN 2
#define WAIT_STATE_AXI_C_IN 3
#define WAIT_STATE_AXI_C_OUT 4
#define WAIT_STATE_PEIN 5
#define WAIT_STATE_PEOUT 6
#define WAIT_STATE_7 7

class SparqTestBench {
  private:
    Vsparq_top* top;

    std::map<uint32_t, uint8_t> dram_contents;

    int8_t * mat_A;
    int8_t * mat_A_compressed;
    uint8_t * mat_A_meta;
    float * mat_B;
    float * mat_C;
    float * mat_C_ref;

    uint8_t get_dram_contents(uint32_t addr);

    CommandDataPort cdp_zero;
    
    int64_t stop_cycle;
    
    uint32_t load_data_fmap(uint32_t addr, uint32_t channels, uint32_t height, uint32_t width, uint32_t dimension,  uint32_t elemsize, const char* fn);
    uint32_t load_data_weight(uint32_t addr, uint32_t out_channels, uint32_t filter_height, uint32_t filter_width, uint32_t in_channels, uint32_t dimension, uint32_t elemsize, const char* fn);    
    uint32_t load_data_rq(uint32_t addr, uint32_t out_channels, uint32_t dimension, uint32_t elemsize, const char* fn_bias, const char* fn_rescale);
    
    void store_data_slice(uint32_t addr, uint32_t len, uint32_t width, uint32_t ldim, uint32_t elemsize, const char* fn);
    void dump_mem(uint32_t addr,uint32_t size,const char* fn);
    void dump_mem_ascii(uint32_t addr,uint32_t size,const char* fn);

    void prepare_ext_data(uint32_t dim_1, uint32_t dim_2,uint32_t dim_3, uint32_t addrA, uint32_t addrB, uint32_t addrA_meta);
    void compare_result(uint32_t dim_1, uint32_t dim_3, uint32_t addrC);

    //fake host program
    std::thread host_thread;
    std::mutex mtx;

    std::queue<CommandDataPort> command_dataport_queue;
    std::queue<int>             command_type_queue;
    int                         state_id_req;
    int                         state_ready;

    uint32_t  axi_A_load_addr;
    uint32_t  axi_A_load_size;
    uint32_t  axi_A_load_chunks;
    uint32_t  axi_A_load_interval;
    
    uint32_t  axi_A_load_pos;
    uint32_t  axi_A_load_chunk_idx;
    uint32_t  axi_A_load_base;

    uint32_t  axi_A_meta_load_addr;
    uint32_t  axi_A_meta_load_size;
    uint32_t  axi_A_meta_load_chunks;
    uint32_t  axi_A_meta_load_interval;
    
    uint32_t  axi_A_meta_load_pos;
    uint32_t  axi_A_meta_load_chunk_idx;
    uint32_t  axi_A_meta_load_base;

    uint32_t  axi_B_load_addr;
    uint32_t  axi_B_load_size;
    uint32_t  axi_B_load_chunks;
    uint32_t  axi_B_load_interval;
    
    uint32_t  axi_B_load_pos;
    uint32_t  axi_B_load_chunk_idx;
    uint32_t  axi_B_load_base;

    uint32_t  axi_C_load_addr;
    uint32_t  axi_C_load_size;
    uint32_t  axi_C_load_chunks;
    uint32_t  axi_C_load_interval;
    
    uint32_t  axi_C_load_pos;
    uint32_t  axi_C_load_chunk_idx;
    uint32_t  axi_C_load_base;

    uint32_t  axi_C_store_addr;
    uint32_t  axi_C_store_size;
    uint32_t  axi_C_store_chunks;    
    uint32_t  axi_C_store_interval;

    uint32_t  axi_C_store_pos;
    uint32_t  axi_C_store_chunk_idx;
    uint32_t  axi_C_store_base;



    uint32_t  host_stateport0;
    uint32_t  host_stateport1;
    uint32_t  host_stateport2;
    uint32_t  host_stateport3;
    uint32_t  host_stateport4;
    uint32_t  host_stateport5;
    uint32_t  host_stateport6;
    uint32_t  host_stateport7;
    
    void host_function();

    void host_getstates(int type);
    void host_setcommand(int type, CommandDataPort command);
    void wait_host_command_flush();
    void host_setdebug(int type, uint16_t id_v, uint16_t id_h, uint32_t debug);

    void gemm (uint32_t dim_1, uint32_t dim_2,uint32_t dim_3, uint32_t addrA, uint32_t addrB, uint32_t addrC, uint32_t addrA_meta);

    void Control_Load_A(uint32_t axi_addr, uint32_t size, uint32_t chunks, uint32_t interval, uint32_t addr_to);
    void Control_Load_A_meta(uint32_t axi_addr, uint32_t size, uint32_t chunks, uint32_t interval, uint32_t addr_to);
    void Control_Load_B(uint32_t axi_addr, uint32_t size, uint32_t chunks, uint32_t interval, uint32_t addr_to);
    void Control_Load_C(uint32_t axi_addr, uint32_t size, uint32_t chunks, uint32_t interval, uint32_t addr_to);
    void Control_Store_C(uint32_t axi_addr, uint32_t size, uint32_t chunks, uint32_t interval, uint32_t addr_from);
    
    void Control_GEMM(uint32_t  buffer_a_base_addr, uint32_t  buffer_b_base_addr, uint32_t  buffer_c_base_addr, uint32_t  reset_accum, uint32_t  buffer_a_size);
       
    void Control_Wait(uint32_t cycles);
    void Control_WaitforIdle(uint32_t type);
      
  public:
    SparqTestBench(Vsparq_top* _top) ;
    void initialize();
    bool step_cycle(vluint64_t cycle) ; //return false when stop
    void finish() ;
};



#endif // __SPARQ_TESTBENCH_H__