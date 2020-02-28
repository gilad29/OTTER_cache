`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/04/2020 05:17:01 PM
// Design Name:
// Module Name: d_cache
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
import memory_bus_sizes::*;

module d_cache(
    input CLK,
    i_mhub_to_dcache.device mhub,
    i_dcache_to_ram.controller ram
    //input [127:0] mem_data, //i_dcache_to_ram.controller(mem_data)
    //input [31:0] cpu_req_addr, cpu_req_data,
      //cpu_req_addr = i_mhub_to_dcache.device(waddr)
      //cpu_req_data = i_mhub_to_dcache.device(din)
    //output [31:0] data, //i_mhub_to_dcache.device(dout)
    //output logic hit
    );

    wire [19:0] tag_req;
    wire [7:0] index_req;
    wire [1:0] block_offset_req, byte_offset_req;
    wire [31:0] data_out_32;
    wire [127:0] data_out;
    logic [127:0] cache_din;

    // assign tag_req = cpu_req_addr[31:13];
    assign tag_req = mhub.waddr[31:12];
    assign index_req = mhub.waddr[11:4];
    assign block_offset_req = mhub.waddr[3:2];
    //assign byte_offset_req = mhub.waddr[1:0];
    assign mhub.dout = data_out_32;
    assign ram.din = data_out;
    assign ram.baddr = mhub.waddr;    
   
    wire [19:0] tag_current;
    logic wr_valid, wr_dirty, wr_tag, wr_ram_mhub;
    logic valid, dirty;
    logic tag_match;

    wire hit;
    assign hit = tag_match && valid;
    wire miss;
    assign miss = ~hit;
    wire ready;
    assign ready = ~ram.hold;
    wire wr_from_ram;

    always_comb begin
      if (mhub.we)
        cache_din = {{96{1'b0}},mhub.din};
      else if (ready)
        cache_din = ram.dout;
      else
        cache_din = 0;
    end

    tag_mem_d TAG ( .CLK(CLK), .index(index_req), .tag_in(tag_req), .dirty_in(wr_dirty), .valid_in(wr_valid), .we(wr_tag), .tag_out(tag_current), .valid(valid), .dirty(dirty));
    // cache_data cache_d(.CLK(CLK), .data_in(mem_data), .index(index_req), .block_offset(block_offset_req), .byte_offset(byte_offset_req), .data_out(data_out));
    cache_data_d cache_d(.CLK(CLK), .data_in(cache_din), .we(mhub.we || wr_from_ram), .from_ram(wr_from_ram), .be(mhub.be), .index(index_req), .block_offset(block_offset_req), .data_out(data_out));
    cache_FSM cache_fsm(.CLK(CLK), .miss(miss), .ready(ready), .dirty(dirty), .en(mhub.en), .we(mhub.we), .mhub(mhub), .ram(ram), .we_mem(ram.we), .en_mem(ram.en), .wr_dirty(wr_dirty), .valid(wr_valid), .wr_tag(wr_tag), .cpu_hold(mhub.hold), .wr_from_ram(wr_from_ram) );

    always_comb begin
        if (tag_current == tag_req) begin
            tag_match = 1;
        end
        else begin
            tag_match = 0;
        end
    end

    Mult4to1 block_offest_mux(data_out[127:96], data_out[95:64], data_out[63:32], data_out[31:0], block_offset_req, data_out_32);

endmodule


module tag_mem_d(
    input CLK,
    input [7:0] index,
    input dirty_in,
    input valid_in,
    input [19:0] tag_in,
    input we,
    output logic [19:0] tag_out,
    output logic valid,
    output logic dirty);

    logic [255:0] tag_memory [21:0];

    always@(posedge CLK)
    begin
      if (we == 1) begin
        tag_memory[index][19:0] = tag_in;
        tag_memory[index][20] = dirty_in;
        tag_memory[index][21] = valid_in;
      end
    end

    always_comb begin
      tag_out = tag_memory[index][19:0];
      dirty = tag_memory[index][20];
      valid = tag_memory[index][21];
    end

endmodule

module cache_data_d(
    input CLK,
    input [127:0] data_in,
    input we, from_ram,
    input [3:0] be,
    input [7:0] index,
    input [1:0] block_offset,
    output logic [127:0] data_out
  );

  logic [255:0] cache_memory [127:0];

  initial begin
      for(int i=0; i<256; i++)
          cache_memory[i]='0;
  end

  always@(posedge CLK)
  begin
    if(we) begin
        if(from_ram)
            cache_memory[index] <= data_in;
        if(!from_ram) begin
          for (int b = 0; b < WORD_SIZE; b++) begin
            if (be[b]) begin
                cache_memory[index][block_offset*WORD_WIDTH+b*8+:8] <= data_in[block_offset*WORD_WIDTH+b*8+:8];  //[b*8+:8];
            end
          end
        end
    end
    //data_out = cache_memory[index];
  end
 
 always_comb
    data_out = cache_memory[index];

endmodule

/*module Mult4to1(In1, In2, In3, In4, Sel, Out);
    input [31:0] In1, In2, In3, In4; //four 64-bit inputs
    input [1:0] Sel; //selector signal
    output logic [31:0] Out; //64-bit output
    always_comb
        case (Sel) //a 4->1 multiplexor
            0: Out <= In1;
            1: Out <= In2;
            2: Out <= In3;
            default: Out <= In4;
        endcase
endmodule
*/