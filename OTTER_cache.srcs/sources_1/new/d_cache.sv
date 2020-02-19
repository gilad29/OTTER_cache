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

    // assign tag_req = cpu_req_addr[31:13];
    assign tag_req = mhub.waddr[31:13]
    assign index_req = mhub.waddr[12:4];
    assign block_offset_req = mhub.waddr[3:2];
    assign byte_offset_req = mhub.waddr[1:0];
    assign data_out_32 = mhub.dout;

    wire [19:0] tag_current;
    logic valid, dirty;
    logic tag_match;

    assign hit = tag_match && valid;
    wire miss;
    assign miss = ~hit;
    wire ready;
    assign ready = ~ram.hold;

    tag_mem TAG ( .CLK(CLK), .index(index_req), .tag(tag_current), .valid(valid), .dirty(dirty));
    // cache_data cache_d(.CLK(CLK), .data_in(mem_data), .index(index_req), .block_offset(block_offset_req), .byte_offset(byte_offset_req), .data_out(data_out));
    cache_data cache_d(.CLK(CLK), .data_in(ram.dout), .we(mhub.we), .from_ram(), .be(mhub.be), .index(index_req), .block_offset(block_offset_req), .byte_offset(byte_offset_req), .data_out(data_out));
    cache_FSM cache_fsm(.CLK(CLK), .miss(miss), .ready(ready), .dirty(dirty),  );

    always_comb begin
        if (tag_current == tag_req) begin
            tag_match = 1;
        end
        else begin
            tag_match = 0;
        end
    end

    Mult4to1 block_offest_mux(data_out[31:0], data_out[63:32], data_out[95:64], data_out[127:96], block_offset_req, data_out_32);

endmodule


module tag_mem(
    input CLK,
    input [7:0] index,
    input [19:0] tag_in,
    output logic [19:0] tag_out,
    output logic valid,
    output logic dirty);

    logic [63:0] tag_memory [21:0];

    always@(posedge CLK)
    begin

    end

    always_comb begin
      tag_out = tag_memory[index][19:0];
      dirty = tag_memory[index][20];
      valid = tag_memory[index][21];
    end

);

endmodule

module cache_data(
    input CLK,
    input [127:0] data_in,
    input we, from_ram,
    input [3:0] be,
    input [7:0] index,
    input [1:0] block_offset, byte_offset,
    output logic [127:0] data_out,
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
      data_out = cache_memory[index];
  end

endmodule

module Mult4to1(In1, In2, In3, In4, Sel, Out);
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
