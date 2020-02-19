`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Keefe Johnson
// Credits: adapted from code by Joseph Callenes-Sloan
//
// Create Date: 02/07/2020 02:06:59 PM
// Updated Date: 02/13/2020 08:00:00 AM
// Design Name:
// Module Name: cache_testbench
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

module cache_testbench();

    parameter CACHE_LINES = 256;  // power of 2, customize to the specific cache implementation

    // 100MHz clock
    logic clk = 1; always #5 clk = ~clk;
    default clocking cb @(posedge clk); endclocking

    localparam INDEX_WIDTH = $clog2(CACHE_LINES);
    localparam TAG_MSB = ADDR_WIDTH - 1;
    localparam TAG_LSB = BLOCK_ADDR_LSB + INDEX_WIDTH;
    localparam INDEX_MSB = BLOCK_ADDR_LSB + INDEX_WIDTH - 1;
    localparam INDEX_LSB = BLOCK_ADDR_LSB;
    localparam BLOCK_OFFSET_MSB = BLOCK_ADDR_LSB - 1;
    localparam BLOCK_OFFSET_LSB = WORD_ADDR_LSB;
    localparam BYTE_OFFSET_MSB = WORD_ADDR_LSB - 1;
    localparam BYTE_OFFSET_LSB = 0;

    i_mhub_to_dcache s_dcache();
    i_icache_to_ram s_icache_to_ram();
    i_dcache_to_ram s_dcache_to_ram();

    logic [TAG_MSB:TAG_LSB] s_dcache_tag;
    logic [INDEX_MSB:INDEX_LSB] s_dcache_index;
    logic [BLOCK_OFFSET_MSB:BLOCK_OFFSET_LSB] s_dcache_block_offset;
    logic [BYTE_OFFSET_MSB:BYTE_OFFSET_LSB] s_dcache_byte_offset;

    dcache dcache(.clk(clk), .mhub(s_dcache), .ram(s_dcache_to_ram));
    sim_slow_ram #(.MEM_DELAY(10)) ram(.clk(clk), .icache(s_icache_to_ram), .dcache(s_dcache_to_ram));

    assign s_dcache.waddr = {s_dcache_tag, s_dcache_index, s_dcache_block_offset};
    assign s_dcache_byte_offset = '0;

    initial begin
        $timeformat(-9, 3, "ns", 10);

        // for debugging, use Z when the cache shouldn't depend on the signals
        s_dcache.waddr = 'Z;
        s_dcache.be = 'Z;
        s_dcache.en = '0;  // en always matters
        s_dcache.we = 'Z;
        s_dcache.flush = 'Z;  // not implementing for now
        s_dcache.din = 'Z;
        ##50;


        $display("%t: ==== Read, miss, clean line (allocate) ========================================================", $time);
        s_dcache.we <= '0;
        s_dcache_tag <= 'h01234;
        s_dcache_index <= 'h02;
        s_dcache_block_offset <= 'h0;
        s_dcache.en <= '1;
        $strobe("%t: [CPU] read addr=%x", $time, {s_dcache.waddr, s_dcache_byte_offset});
        @(posedge clk iff !s_dcache.hold);
        $strobe("%t: [CPU] got data=%x", $time, s_dcache.dout);
        s_dcache.en <= '0;
        s_dcache.we <= 'Z;
        {s_dcache_tag, s_dcache_index, s_dcache_block_offset} <= 'Z;
        ##50;


        $display("%t: ==== Read, hit, clean line ====================================================================", $time);
        s_dcache.we <= '0;
        s_dcache_tag <= 'h01234;
        s_dcache_index <= 'h02;
        s_dcache_block_offset <= 'h2;
        s_dcache.en <= '1;
        $strobe("%t: [CPU] read addr=%x", $time, {s_dcache.waddr, s_dcache_byte_offset});
        @(posedge clk iff !s_dcache.hold);
        $strobe("%t: [CPU] got data=%x", $time, s_dcache.dout);
        s_dcache.en <= '0;
        s_dcache.we <= 'Z;
        {s_dcache_tag, s_dcache_index, s_dcache_block_offset} <= 'Z;
        ##50;


        $display("%t: ==== Write, hit, clean line (cache line is dirty afterwards) ==================================", $time);
        s_dcache.we <= '1;
        s_dcache_tag <= 'h01234;
        s_dcache_index <= 'h02;
        s_dcache_block_offset <= 'h2;
        s_dcache.be <= 'b1111;
        s_dcache.din <= 'hdeadbeef;
        s_dcache.en <= '1;
        $strobe("%t: [CPU] write addr=%x with data=%x", $time, {s_dcache.waddr, s_dcache_byte_offset}, s_dcache.din);
        @(posedge clk iff !s_dcache.hold);
        $strobe("%t: [CPU] write accepted", $time);
        s_dcache.en <= '0;
        s_dcache.we <= 'Z;
        {s_dcache_tag, s_dcache_index, s_dcache_block_offset} <= 'Z;
        s_dcache.be <= 'Z;
        s_dcache.din <= 'Z;
        ##50;


        $display("%t: ==== Write, conflict miss, (write back then allocate, cache line dirty) =======================", $time);
        s_dcache.we <= '1;
        s_dcache_tag <= 'h04321;
        s_dcache_index <= 'h02;
        s_dcache_block_offset <= 'h2;
        s_dcache.be <= 'b1111;
        s_dcache.din <= 'hcafebeef;
        s_dcache.en <= '1;
        $strobe("%t: [CPU] write addr=%x with data=%x", $time, {s_dcache.waddr, s_dcache_byte_offset}, s_dcache.din);
        @(posedge clk iff !s_dcache.hold);
        $strobe("%t: [CPU] write accepted", $time);
        s_dcache.en <= '0;
        s_dcache.we <= 'Z;
        {s_dcache_tag, s_dcache_index, s_dcache_block_offset} <= 'Z;
        s_dcache.be <= 'Z;
        s_dcache.din <= 'Z;
        ##50;


        $display("%t: ==== Read, hit, dirty cache line ==============================================================", $time);
        s_dcache.we <= '0;
        s_dcache_tag <= 'h04321;
        s_dcache_index <= 'h02;
        s_dcache_block_offset <= 'h0;
        s_dcache.en <= '1;
        $strobe("%t: [CPU] read addr=%x", $time, {s_dcache.waddr, s_dcache_byte_offset});
        @(posedge clk iff !s_dcache.hold);
        $strobe("%t: [CPU] got data=%x", $time, s_dcache.dout);
        s_dcache.en <= '0;
        s_dcache.we <= 'Z;
        {s_dcache_tag, s_dcache_index, s_dcache_block_offset} <= 'Z;
        ##50;


        $display("%t: ==== Read, conflict miss, dirty cache line (write back then allocate, cache line is clean) ====", $time);
        s_dcache.we <= '0;
        s_dcache_tag <= 'h05678;
        s_dcache_index <= 'h02;
        s_dcache_block_offset <= 'h1;
        s_dcache.en <= '1;
        $strobe("%t: [CPU] read addr=%x", $time, {s_dcache.waddr, s_dcache_byte_offset});
        @(posedge clk iff !s_dcache.hold);
        $strobe("%t: [CPU] got data=%x", $time, s_dcache.dout);
        s_dcache.en <= '0;
        s_dcache.we <= 'Z;
        {s_dcache_tag, s_dcache_index, s_dcache_block_offset} <= 'Z;
        ##50;


        $finish();
    end

endmodule

module sim_slow_ram #(
    parameter MEM_DELAY = 10  // accept/process one command every MEM_DELAY+1 clock cycles
    )(
    input clk,
    i_icache_to_ram.device icache,
    i_dcache_to_ram.device dcache
    );

    logic [ADDR_WIDTH-1:BLOCK_ADDR_LSB] rami_baddr, ramd_baddr;
    logic [BLOCK_WIDTH-1:0] rami_din, rami_dout, ramd_din, ramd_dout;
    logic rami_en, rami_we, ramd_en, ramd_we;

    sim_delay_ram #(
        .PORT_NAME("Instruction"), .MEM_DELAY(MEM_DELAY)
    ) delay_rami (
        .clk(clk), .baddr(icache.baddr), .en(icache.en), .we('0), .din('0), .dout(icache.dout), .hold(icache.hold),
        .ram_baddr(rami_baddr), .ram_en(rami_en), .ram_we(), .ram_din(), .ram_dout(rami_dout)
    );
    sim_delay_ram #(
        .PORT_NAME("Data"), .MEM_DELAY(MEM_DELAY)
    ) delay_ramd (
        .clk(clk), .baddr(dcache.baddr), .en(dcache.en), .we(dcache.we), .din(dcache.din), .dout(dcache.dout), .hold(dcache.hold),
        .ram_baddr(ramd_baddr), .ram_en(ramd_en), .ram_we(ramd_we), .ram_din(ramd_din), .ram_dout(ramd_dout)
    );
    sim_xilinx_bram_tdp_nc_nr #(
        .ADDR_WIDTH(ADDR_WIDTH - BLOCK_ADDR_LSB), .DATA_WIDTH(BLOCK_WIDTH)
    ) bram (
        .clka(clk), .addra(rami_baddr), .dina('0), .douta(rami_dout), .ena(rami_en), .wea('0),
        .clkb(clk), .addrb(ramd_baddr), .dinb(ramd_din), .doutb(ramd_dout), .enb(ramd_en), .web(ramd_we)
    );

endmodule

module sim_delay_ram #(
    PORT_NAME = "",  // define in parent, for debug output labeling
    MEM_DELAY = -1  // define in parent
    )(
    input clk,
    input [ADDR_WIDTH-1:BLOCK_ADDR_LSB] baddr,
    input en, we,
    input [BLOCK_WIDTH-1:0] din,
    output [BLOCK_WIDTH-1:0] dout,
    output hold,
    output [ADDR_WIDTH-1:BLOCK_ADDR_LSB] ram_baddr,
    output ram_en, ram_we,
    output [BLOCK_WIDTH-1:0] ram_din,
    input [BLOCK_WIDTH-1:0] ram_dout
    );

    localparam CNT_WIDTH = (MEM_DELAY == 0) ? 1 : $clog2(MEM_DELAY+1);
    logic [CNT_WIDTH-1:0] r_cycle_cnt = 0;
    logic r_we;
    logic [ADDR_WIDTH-1:BLOCK_ADDR_LSB] r_baddr;
    logic [BLOCK_WIDTH-1:0] r_din;

    logic s_hold;  // if command present, tells controller to hold it's command steady while we process
    logic s_available;  // available unless processing, but also includes all of the acceptance partial cycle
    logic s_processing;  // includes acceptance partial cycle
    logic s_accepting, s_in_delay_cycles;  // if s_processing, exactly one true, otherwise all false
    logic s_reading, s_writing;  // if s_processing, exactly one true, otherwise all false
    logic s_in_final_cycle;  // the operation completes on the edge after this cycle, which may be the acceptance cycle if MEM_DELAY==0
    logic s_we;  // command or saved
    logic [ADDR_WIDTH-1:BLOCK_ADDR_LSB] s_baddr;  // command or saved
    logic [BLOCK_WIDTH-1:0] s_din;  // command or saved

    assign s_in_delay_cycles = r_cycle_cnt > 0;
    assign s_available = !s_in_delay_cycles;
    assign s_accepting = s_available && en;
    assign s_processing = s_accepting || s_in_delay_cycles;
    assign s_in_final_cycle = s_processing && r_cycle_cnt == MEM_DELAY;
    assign s_we = s_accepting ? we : r_we;
    assign s_reading = s_processing && !s_we;
    assign s_writing = s_processing && s_we;
    assign s_baddr = s_accepting ? baddr : r_baddr;
    assign s_din = s_accepting ? din : r_din;
    assign s_hold = en ? ((s_reading && !s_in_final_cycle) || (s_writing && !s_accepting)) : 0;

    assign hold = s_hold;
    assign dout = ram_dout;

    assign ram_baddr = s_baddr;
    assign ram_en = s_in_final_cycle;
    assign ram_we = s_writing;
    assign ram_din = s_din;

    always_ff @(posedge clk) begin
        if (s_in_final_cycle) begin
            r_cycle_cnt <= 0;
        end else if (s_processing) begin
            r_cycle_cnt <= r_cycle_cnt + 1;
        end
        if (s_accepting && !s_in_final_cycle) begin
            r_baddr <= baddr;
            r_we <= we;
            if (s_writing) begin
                r_din <= din;
            end
        end
    end

    // debug display for simulation
    always @(posedge clk) begin
        // first look at our address and reading/writing before nonblocking assignments (NBAs) on the clock edge
        //   change them but display the read data after the NBAs since that isn't available yet
        // note that strobe schedules the probing/displaying of signals to after the NBAs, but returns immediately
        automatic logic [ADDR_WIDTH-1:BLOCK_ADDR_LSB] v_bc_baddr = s_baddr;  // save the before-clock address
        if (s_in_final_cycle && s_reading) begin
            $strobe("%t: [Memory] %s Read finished @ baddr=%x (addr=%x..%x) with data=%x",
                    $time, PORT_NAME, v_bc_baddr,
                    {v_bc_baddr, {BLOCK_ADDR_LSB{1'b0}}}, {v_bc_baddr, {BLOCK_ADDR_LSB{1'b1}}},
                    dout);
        end
        if (s_accepting && s_writing) begin
            $strobe("%t: [Memory] %s Write accepted @ baddr=%x (addr=%x..%x)",
                    $time, PORT_NAME, v_bc_baddr,
                    {v_bc_baddr, {BLOCK_ADDR_LSB{1'b0}}}, {v_bc_baddr, {BLOCK_ADDR_LSB{1'b1}}});
        end
        if (s_in_final_cycle && s_writing) begin
            $strobe("%t: [Memory] %s Write finished @ baddr=%x (addr=%x..%x)",
                    $time, PORT_NAME, v_bc_baddr,
                    {v_bc_baddr, {BLOCK_ADDR_LSB{1'b0}}}, {v_bc_baddr, {BLOCK_ADDR_LSB{1'b1}}});
        end
        // then use #1 to postpone further processing until nonblocking assignments have completed
        #1
        // we should now get an early look at what the inputs will be right before the next positive clock edge
        if (s_accepting) begin
            if (s_reading) begin
                $display("%t: [Memory] %s Read started @ baddr=%x (addr=%x..%x)",
                         $time, PORT_NAME, s_baddr,
                         {s_baddr, {BLOCK_ADDR_LSB{1'b0}}}, {s_baddr, {BLOCK_ADDR_LSB{1'b1}}});
            end
            if (s_writing) begin
                $display("%t: [Memory] %s Write started @ baddr=%x (addr=%x..%x) with data=%x",
                         $time, PORT_NAME, s_baddr,
                         {s_baddr, {BLOCK_ADDR_LSB{1'b0}}}, {s_baddr, {BLOCK_ADDR_LSB{1'b1}}},
                         s_din);
            end
        end else begin
            @(negedge clk);
            #1;
            // check again right after the negative edge, for another early look at what the inputs will be right
            //   before the next positive clock edge (the same upcoming positive edge as for the first early look)
            if (s_accepting) begin
                if (s_reading) begin
                    $display("%t: [Memory] %s Read started @ baddr=%x (addr=%x..%x)",
                             $time, PORT_NAME, s_baddr,
                             {s_baddr, {BLOCK_ADDR_LSB{1'b0}}}, {s_baddr, {BLOCK_ADDR_LSB{1'b1}}});
                end
                if (s_writing) begin
                    $display("%t: [Memory] %s Write started @ baddr=%x (addr=%x..%x) with data=%x",
                             $time, PORT_NAME, s_baddr,
                             {s_baddr, {BLOCK_ADDR_LSB{1'b0}}}, {s_baddr, {BLOCK_ADDR_LSB{1'b1}}},
                             s_din);
                end
            end
        end
    end

endmodule

module sim_xilinx_bram_tdp_nc_nr #(
    parameter ADDR_WIDTH = -1,  // define in parent
    parameter DATA_WIDTH = -1  // define in parent
    )(
    input clka, clkb,
    input ena, enb,
    input wea, web,
    input [ADDR_WIDTH-1:0] addra, addrb,
    input [DATA_WIDTH-1:0] dina, dinb,
    output [DATA_WIDTH-1:0] douta, doutb
    );

    logic [DATA_WIDTH-1:0] r_douta, r_doutb;

    assign douta = r_douta;
    assign doutb = r_doutb;

    class rand_cl;
        rand bit [DATA_WIDTH-1:0] v;
    endclass
    rand_cl rand_data = new();

    bit [DATA_WIDTH-1:0] r_ram [*];  // associative array

    always_ff @(posedge clka) begin
        if (ena) begin
            if (wea) begin
                r_ram[addra] <= dina;  // warning [VRFC 10-587] is probably safe to ignore
            end else begin
                if (!r_ram.exists(addra)) begin  // new random number only on first read
                    rand_data.randomize();
                    r_ram[addra] = rand_data.v;
                end
                r_douta <= r_ram[addra];
            end
        end
    end

    always_ff @(posedge clkb) begin
        if (enb) begin
            if (web) begin
                r_ram[addrb] <= dinb;  // warning [VRFC 10-587] is probably safe to ignore
            end else begin
                if (!r_ram.exists(addrb)) begin  // new random number only on first read
                    rand_data.randomize();
                    r_ram[addrb] = rand_data.v;
                end
                r_doutb <= r_ram[addrb];
            end
        end
    end

endmodule
