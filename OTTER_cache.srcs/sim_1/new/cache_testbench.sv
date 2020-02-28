`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Keefe Johnson
// Credits: adapted from code by Joseph Callenes-Sloan
// 
// Create Date: 02/07/2020 02:06:59 PM
// Updated Date: 02/22/2020 09:00:00 AM
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


parameter DISPLAY_TIME = 0;  // 1 to include timestamps in log, 0 to omit them
        
import memory_bus_sizes::*;

module cache_testbench();

    parameter CACHE_LINES = 256;  // power of 2, customize to the specific cache implementation 

    // 100MHz clock
    logic clk = 0;
    initial begin
        #10 clk = 1;
        forever #5 clk = ~clk;
    end
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

    d_cache dcache(.CLK(clk), .mhub(s_dcache), .ram(s_dcache_to_ram));
    sim_slow_ram #(.MEM_DELAY(10)) ram(.clk(clk), .icache(s_icache_to_ram), .dcache(s_dcache_to_ram));

    vlm_protocol_validator #(.DISPLAY_NAME("mhub<->dcache")) vpv1 (.clk(clk), .vlm(s_dcache.vlm_validator), .err());
    vlm_protocol_validator #(.DISPLAY_NAME("dcache<->ram")) vpv2 (.clk(clk), .vlm(s_dcache_to_ram.vlm_validator), .err());
    
    initial begin
        $timeformat(-9, 0, "ns", 7);
        // for debugging, use Z when the cache shouldn't depend on the signals
        s_dcache.waddr = 'Z;
        s_dcache.be = 'Z;
        s_dcache.en = '0;  // en always matters
        s_dcache.we = 'Z;
        s_dcache.flush = 'Z;  // not implementing for now
        s_dcache.din = 'Z;
        #499 @(posedge clk);

        // initialize ram to specific random values to make the output more deterministic and diffable
        ram.bram.r_ram['h0000000] = 'h4b7dad7111aa23301944fd6db2055e5f;
        ram.bram.r_ram['h0123401] = 'h8832e97688f820c98b3373b29827043e;
        ram.bram.r_ram['h0123402] = 'hfeb1a64ac99c9e59efd2d505e68aa20b;
        ram.bram.r_ram['h0432101] = 'he190eac386e48fc0d294bf22fb0648b7;
        ram.bram.r_ram['h0432102] = 'h3d6ddcdfe042910dd0812e19c2679427;
        ram.bram.r_ram['h0567801] = 'hdabe3c23a2eb5e42ff4158af37a84ee7;
        ram.bram.r_ram['h0567802] = 'he57d81631efec7a2e72720cd2315ed3c;
        ram.bram.r_ram['h0876501] = 'h9e10c863c03bbd86c1ea25e4e668797c;
        ram.bram.r_ram['h0876502] = 'h2793f810f8cf0486e3271bc9c12b7e93;
        ram.bram.r_ram['h0123405] = 'h1f68e1863f49e9a98fc0b571d100b910;
        ram.bram.r_ram['h0123406] = 'h4ac678e5e3eb7dacf8b426ec3b729619;
        ram.bram.r_ram['h0432105] = 'h1641a2304ddf4124a4a370881c56a4b1;
        ram.bram.r_ram['h0432106] = 'h92954f88cf492658c2b04d7d027f9dd1;
        ram.bram.r_ram['h0567805] = 'h8c2ee818a687c3efcfdb5ba3c3b43e7c;
        ram.bram.r_ram['h0567806] = 'h7b07db7a7d16e0c63765927a1b67dc43;
        ram.bram.r_ram['h0876505] = 'h91e2e5f0cb59beded29e7b8b4604a9a8;
        ram.bram.r_ram['h0876506] = 'he5396c6406dec455979957fa7044fe8d;


        $strobe("%s==== (checking invalid tag match) Read, cold-start miss (allocate, block now valid and clean) ==================", DISPLAY_TIME ? $sformatf("%t: ", $time) : "");
        read_dcache('h00000, 'h00, 'h0);
        #499 @(posedge clk);
        
        // run tests first with delays, then without
        for (int i = 0; i < 2; i++) begin

            if (i == 0) begin
                $strobe("%s================ Testing various cases, with delays between ====================================================", DISPLAY_TIME ? $sformatf("%t: ", $time) : "");
            end else begin
                $strobe("%s================ Testing various cases, with no delays between, and partial-word writes ========================", DISPLAY_TIME ? $sformatf("%t: ", $time) : "");
            end
    
            $strobe("%s==== Read, cold-start miss (allocate, block now valid and clean) ===============================================", DISPLAY_TIME ? $sformatf("%t: ", $time) : "");
            read_dcache('h01234, 'h01 + i * 4, 'h0);
            if (i == 0) #499 @(posedge clk);
            
            $strobe("%s==== Write, cold-start miss (allocate then update, block now valid and dirty) ==================================", DISPLAY_TIME ? $sformatf("%t: ", $time) : "");
            write_dcache('h01234, 'h02 + i * 4, 'h1, i == 0 ? 'b1111 : 'b1100, 'haabbccdd);
            if (i == 0) #499 @(posedge clk);
    
            $strobe("%s==== Read, hit, clean block (block still clean) ================================================================", DISPLAY_TIME ? $sformatf("%t: ", $time) : "");
            read_dcache('h01234, 'h01 + i * 4, 'h2);
            if (i == 0) #499 @(posedge clk);
    
            $strobe("%s==== Read, hit, dirty block (block still dirty) ================================================================", DISPLAY_TIME ? $sformatf("%t: ", $time) : "");
            read_dcache('h01234, 'h02 + i * 4, 'h3);
            if (i == 0) #499 @(posedge clk);
    
            $strobe("%s==== Read, conflict miss, clean block (allocate, block still clean) ============================================", DISPLAY_TIME ? $sformatf("%t: ", $time) : "");
            read_dcache('h04321, 'h01 + i * 4, 'h0);
            if (i == 0) #499 @(posedge clk);
    
            $strobe("%s==== Read, conflict miss, dirty block (write back then allocate, block now clean) ==============================", DISPLAY_TIME ? $sformatf("%t: ", $time) : "");
            read_dcache('h04321, 'h02 + i * 4, 'h1);
            if (i == 0) #499 @(posedge clk);
    
            $strobe("%s==== Write, hit, clean block (update, block now dirty) =========================================================", DISPLAY_TIME ? $sformatf("%t: ", $time) : "");
            write_dcache('h04321, 'h01 + i * 4, 'h2, i == 0 ? 'b1111 : 'b0011, 'hbbccddee);
            if (i == 0) #499 @(posedge clk);
    
            $strobe("%s==== Write, hit, dirty block (update, block still dirty) =======================================================", DISPLAY_TIME ? $sformatf("%t: ", $time) : "");
            write_dcache('h04321, 'h01 + i * 4, 'h3, i == 0 ? 'b1111 : 'b1000, 'hccddeeff);
            if (i == 0) #499 @(posedge clk);
    
            $strobe("%s==== Write, conflict miss, clean block (allocate then update, block now dirty) =================================", DISPLAY_TIME ? $sformatf("%t: ", $time) : "");
            write_dcache('h05678, 'h02 + i * 4, 'h0, i == 0 ? 'b1111 : 'b0100, 'hddeeffaa);
            if (i == 0) #499 @(posedge clk);
    
            $strobe("%s==== Write, conflict miss, dirty block (write back then allocate then update, block still dirty) ===============", DISPLAY_TIME ? $sformatf("%t: ", $time) : "");
            write_dcache('h05678, 'h01 + i * 4, 'h1, i == 0 ? 'b1111 : 'b0010, 'heeffaabb);
            if (i == 0) #499 @(posedge clk);
    
            $strobe("%s==== (verifying state) Read, conflict miss, dirty block (write back then allocate, block now clean) ============", DISPLAY_TIME ? $sformatf("%t: ", $time) : "");
            read_dcache('h08765, 'h01 + i * 4, 'h2);
            if (i == 0) #499 @(posedge clk);
    
            $strobe("%s==== (verifying state) Read, conflict miss, dirty block (write back then allocate, block now clean) ============", DISPLAY_TIME ? $sformatf("%t: ", $time) : "");
            read_dcache('h08765, 'h02 + i * 4, 'h3);
            if (i == 0) #499 @(posedge clk);

        end

        $strobe("%s================ DONE ==========================================================================================", DISPLAY_TIME ? $sformatf("%t: ", $time) : "");
        #499 @(posedge clk);
        $finish();
    end

    task read_dcache(
        input [TAG_MSB:TAG_LSB] tag,
        input [INDEX_MSB:INDEX_LSB] index,
        input [BLOCK_OFFSET_MSB:BLOCK_OFFSET_LSB] block_offset
        );
        s_dcache.we <= 0;
        s_dcache.waddr <= {tag, index, block_offset};
        s_dcache.en <= 1;
        $strobe("%s[CPU] read waddr=%x (addr=%x..%x)", DISPLAY_TIME ? $sformatf("%t: ", $time) : "",
                s_dcache.waddr, {s_dcache.waddr, {WORD_ADDR_LSB{1'b1}}}, {s_dcache.waddr, {WORD_ADDR_LSB{1'b0}}});
        @(posedge clk iff !s_dcache.hold);
        #0;  // in case both memory and cpu operations complete at the same time, try to report the cpu one last
        $strobe("%s[CPU] got data=%x", DISPLAY_TIME ? $sformatf("%t: ", $time) : "", s_dcache.dout);
        s_dcache.we <= 'Z;
        s_dcache.waddr <= 'Z;
        s_dcache.en <= 0;
    endtask

    task write_dcache(
        input [TAG_MSB:TAG_LSB] tag,
        input [INDEX_MSB:INDEX_LSB] index,
        input [BLOCK_OFFSET_MSB:BLOCK_OFFSET_LSB] block_offset,
        input [WORD_SIZE-1:0] byte_enable,
        input [WORD_WIDTH-1:0] data
        );
        string masked_data;
        masked_data = byte_mask(byte_enable, data);
        s_dcache.we <= 1;
        s_dcache.waddr <= {tag, index, block_offset};
        s_dcache.be <= byte_enable;
        s_dcache.din <= data;
        s_dcache.en <= 1;
        $strobe("%s[CPU] write waddr=%x (addr=%x..%x) with data=%s", DISPLAY_TIME ? $sformatf("%t: ", $time) : "",
                s_dcache.waddr, {s_dcache.waddr, {WORD_ADDR_LSB{1'b1}}}, {s_dcache.waddr, {WORD_ADDR_LSB{1'b0}}},
                masked_data);
        @(posedge clk iff !s_dcache.hold);
        #0;  // in case both memory and cpu operations complete at the same time, try to report the cpu one last
        $strobe("%s[CPU] write accepted", DISPLAY_TIME ? $sformatf("%t: ", $time) : "");
        s_dcache.we <= 'Z;
        s_dcache.waddr <= 'Z;
        s_dcache.be <= 'Z;
        s_dcache.din <= 'Z;
        s_dcache.en <= 0;
    endtask

    function string byte_mask(input logic [WORD_SIZE-1:0] byte_enable, input logic [WORD_WIDTH-1:0] data); begin
        string s;
        s = "";
        for (int i = 0; i < WORD_SIZE; i++) begin
            if (byte_enable[i]) begin
                string h;
                h.hextoa(data[i*8+:8]);
                if (h.len == 1) begin
                    h = {"0", h};
                end
                s = {h, s};
            end else begin
                s = {"__", s};
            end
        end
        byte_mask = s;
    end endfunction

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
        logic [ADDR_WIDTH-1:BLOCK_ADDR_LSB] v_bc_baddr;
        v_bc_baddr = s_baddr;  // save the before-clock address
        if (s_in_final_cycle && s_reading) begin
            $strobe("%s[Memory] %s Read finished @ baddr=%x (addr=%x..%x) with data=%x",
                    DISPLAY_TIME ? $sformatf("%t: ", $time) : "", PORT_NAME, v_bc_baddr,
                    {v_bc_baddr, {BLOCK_ADDR_LSB{1'b1}}}, {v_bc_baddr, {BLOCK_ADDR_LSB{1'b0}}},
                    dout); 
        end
        if (s_accepting && s_writing) begin
            $strobe("%s[Memory] %s Write accepted @ baddr=%x (addr=%x..%x)",
                    DISPLAY_TIME ? $sformatf("%t: ", $time) : "", PORT_NAME, v_bc_baddr,
                    {v_bc_baddr, {BLOCK_ADDR_LSB{1'b1}}}, {v_bc_baddr, {BLOCK_ADDR_LSB{1'b0}}});
        end 
        if (s_in_final_cycle && s_writing) begin
            $strobe("%s[Memory] %s Write finished @ baddr=%x (addr=%x..%x)",
                    DISPLAY_TIME ? $sformatf("%t: ", $time) : "", PORT_NAME, v_bc_baddr,
                    {v_bc_baddr, {BLOCK_ADDR_LSB{1'b1}}}, {v_bc_baddr, {BLOCK_ADDR_LSB{1'b0}}});
        end 
        // then use #1 to postpone further processing until nonblocking assignments have completed
        #1;
        // we should now get an early look at what the inputs will be right before the next positive clock edge
        if (s_accepting) begin
            if (s_reading) begin
                $display("%s[Memory] %s Read started @ baddr=%x (addr=%x..%x)",
                         DISPLAY_TIME ? $sformatf("%t: ", $time) : "", PORT_NAME, s_baddr,
                         {s_baddr, {BLOCK_ADDR_LSB{1'b1}}}, {s_baddr, {BLOCK_ADDR_LSB{1'b0}}});
            end 
            if (s_writing) begin
                $display("%s[Memory] %s Write started @ baddr=%x (addr=%x..%x) with data=%x",
                         DISPLAY_TIME ? $sformatf("%t: ", $time) : "", PORT_NAME, s_baddr,
                         {s_baddr, {BLOCK_ADDR_LSB{1'b1}}}, {s_baddr, {BLOCK_ADDR_LSB{1'b0}}},
                         s_din);
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
                r_ram[addra] <= dina;  // warning [VRFC 10-587] is probably safe to ignore, and NBA is important
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
                r_ram[addrb] <= dinb;  // warning [VRFC 10-587] is probably safe to ignore, and NBA is important
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
