`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Keefe Johnson
//
// Create Date: 02/06/2020 06:40:37 PM
// Updated Date: 02/12/2020 01:30:00 AM
// Design Name:
// Module Name: memory_interfaces
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


package memory_bus_sizes;
    // user-defined
    parameter ADDR_WIDTH = 32;  // bits
    parameter WORD_SIZE = 4;  // bytes, power of 2
    parameter BLOCK_SIZE = 16;  // bytes, power of 2
    parameter MMIO_START_ADDR = 'h11000000;
    // derived
    parameter WORD_WIDTH = WORD_SIZE * 8;
    parameter BLOCK_WIDTH = BLOCK_SIZE * 8;
    parameter WORD_ADDR_LSB = $clog2(WORD_SIZE);
    parameter BLOCK_ADDR_LSB = $clog2(BLOCK_SIZE);
endpackage
import memory_bus_sizes::*;

interface i_cpui_to_mhub();
    logic [ADDR_WIDTH-1:0] addr;
    logic [WORD_WIDTH-1:0] dout;
    logic en, hold;
    modport controller (output addr, en, input  dout, hold);
    modport device     (input  addr, en, output dout, hold);
endinterface

interface i_cpud_to_mhub();
    logic [ADDR_WIDTH-1:0] addr;
    logic [WORD_WIDTH-1:0] din, dout;
    logic [1:0] size;
    logic lu;
    logic en, we, hold;
    modport controller (output addr, size, lu, en, we, din, input  dout, hold);
    modport device     (input  addr, size, lu, en, we, din, output dout, hold);
endinterface

interface i_prog_to_mhub();
    logic [ADDR_WIDTH-1:WORD_ADDR_LSB] waddr;
    logic [WORD_WIDTH-1:0] din;
    logic en, we, flush, hold;
    modport controller (output waddr, en, we, flush, din, input  hold);
    modport device     (input  waddr, en, we, flush, din, output hold);
endinterface

interface i_mhub_to_mmio();
    logic [ADDR_WIDTH-1:WORD_ADDR_LSB] waddr;
    logic [WORD_WIDTH-1:0] din, dout;
    logic [WORD_SIZE-1:0] be;
    logic en, we, hold;
    modport controller (output waddr, be, en, we, din, input  dout, hold);
    modport device     (input  waddr, be, en, we, din, output dout, hold);
endinterface

interface i_mhub_to_icache();
    logic [ADDR_WIDTH-1:WORD_ADDR_LSB] waddr;
    logic [WORD_WIDTH-1:0] dout;
    logic en, flush, hold;
    modport controller (output waddr, en, flush, input  dout, hold);
    modport device     (input  waddr, en, flush, output dout, hold);
endinterface

interface i_mhub_to_dcache();
    logic [ADDR_WIDTH-1:WORD_ADDR_LSB] waddr;
    logic [WORD_WIDTH-1:0] din, dout;
    logic [WORD_SIZE-1:0] be;
    logic en, we, flush, hold;
    modport controller (output waddr, be, en, we, flush, din, input  dout, hold);
    modport device     (input  waddr, be, en, we, flush, din, output dout, hold);
endinterface

interface i_icache_to_ram();
    logic [ADDR_WIDTH-1:BLOCK_ADDR_LSB] baddr;
    logic [BLOCK_WIDTH-1:0] dout;
    logic en, hold;
    modport controller (output baddr, en, input  dout, hold);
    modport device     (input  baddr, en, output dout, hold);
endinterface

interface i_dcache_to_ram();
    logic [ADDR_WIDTH-1:BLOCK_ADDR_LSB] baddr;
    logic [BLOCK_WIDTH-1:0] din, dout;
    logic en, we, hold;
    modport controller (output baddr, en, we, din, input  dout, hold);
    modport device     (input  baddr, en, we, din, output dout, hold);
endinterface

// empty module just to force Vivado to show this file in source hierarchy
module memory_interfaces(); endmodule
