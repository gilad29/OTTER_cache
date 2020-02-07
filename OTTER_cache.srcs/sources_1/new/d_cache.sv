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


module d_cache(
    input [127:0] mem_data,
    input [31:0] cpu_req_addr, cpu_req_data,
    output [31:0] data,
    output logic hit
    );

    wire [19:0] tag_req;
    wire [7:0] index_req;
    wire [1:0] block_offset_req, byte_offset_req;
    wire [127:0] data_out;

    assign tag_req = cpu_req_addr[31:13];
    assign index_req = cpu_req_addr[12:4];
    assign block_offset_req = cpu_req_addr[3:2];
    assign byte_offset_req = cpu_req_addr[1:0];

    wire [19:0] tag_current;
    logic valid, dirty;
    logic tag_match;

    assign hit = tag_match && valid;

    tag_mem TAG (.index(index_req), .tag(tag_current), .valid(valid), .dirty(dirty));
    cache_data cache_d(.data_in(mem_data), .index(index_req), .block_offset(block_offset_req), .byte_offset(byte_offset_req), .data_out(data_out));

    always_comb begin
        if (tag_current == tag_req) begin
            tag_match = 1;
        end
        else begin
            tag_match = 0;
        end
    end

    Mult4to1 block_offest_mux(data_out[31:0], data_out[63:32], data_out[95:64], data_out[127:96], block_offset_req);

endmodule


module tag_mem(
    input [7:0] index,
    output logic [19:0] tag,
    output logic valid,
    output logic dirty);

    logic [63:0] tag_memory [21:0];

    always_comb
    begin
      tag = tag_memory[index][19:0];
      dirty = tag_memory[index][20];
      valid = tag_memory[index][21];
    end

);

endmodule

module cache_data(
    input [127:0] data_in,
    input [7:0] index,
    input [1:0] block_offset, byte_offset,
    output logic [127:0] data_out,
  );

  logic [63:0] cache_memory [127:0];

  always_comb
  begin
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
