`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/13/2020 04:43:16 PM
// Design Name:
// Module Name: cache_FSM
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


module cache_FSM(
    input CLK, miss, dirty, ready,
    i_mhub_to_dcache.device mhub,
    i_dcache_to_ram.controller ram,
    output logic wr_dirty, valid, wr_tag, wr_from_ram, wr_mhub_dout, wr_ram_din, wr_ram_tag, clr_dirty
    );

    typedef enum logic[1:0] {COMPARE_TAG,WRITEBACK,ALLOCATE_READ_RAM,ALLOCATE_SAVE} state_type;
    state_type state, n_state;

    //initial begin state = COMPARE_TAG; end
    
    always_comb begin
      n_state = state;
      case (state)
        COMPARE_TAG: begin
          clr_dirty = 0;
          ram.en = 0;
          ram.we = 0;
          wr_from_ram = 0;
          wr_ram_tag = 0;
          mhub.hold = mhub.en && miss;
          if (miss) begin
            wr_mhub_dout = 0;
            if (dirty && mhub.en) begin
              n_state = WRITEBACK;
              wr_ram_din = 1;
            end
            else begin
                wr_ram_din = 0;
                if (mhub.en) begin
                  n_state = ALLOCATE_READ_RAM;
                end
                else
                  n_state = COMPARE_TAG;
            end
            wr_dirty = 0;
            wr_tag = 0;
            valid = 0;  
          end
          else begin
            wr_ram_din = 0;
            if (mhub.en) begin
              valid = 1;
              wr_tag = 1;
              if (mhub.we) begin
                wr_dirty = 1;
                wr_mhub_dout = 0;
              end
              else begin
                wr_mhub_dout = 1;
                wr_dirty = 0;
              end
            end
            else begin
              valid = 0;
              wr_tag = 0;
              wr_dirty = 0;
            end
            n_state = COMPARE_TAG;
          end
        end
        WRITEBACK: begin
          wr_ram_din = 0;
          wr_mhub_dout = 0;
          valid = 0;
          wr_tag = 0;
          wr_dirty = 0;
          mhub.hold = 1;
          ram.en = 1;
          ram.we = 1;
          wr_from_ram = 0;
          wr_ram_tag = 1;
          if (ready) begin
            n_state = ALLOCATE_READ_RAM;
            clr_dirty = 1;
          end
          else begin
            clr_dirty = 0;
            n_state = WRITEBACK;
          end
        end
        ALLOCATE_READ_RAM: begin
          clr_dirty = 0;
          wr_ram_din = 0;
          wr_mhub_dout = 0;
          valid = 0;
          wr_tag = 0;
          wr_dirty = 0;
          mhub.hold = 1;
          ram.we = 0;
          ram.en = 1;
          wr_from_ram = 0;
          wr_ram_tag = 0;
          ram.baddr = mhub.waddr[31:4];
          if (ready)
            n_state = ALLOCATE_SAVE;
          else
            n_state = ALLOCATE_READ_RAM;
        end
        ALLOCATE_SAVE: begin
          clr_dirty = 0;
          wr_ram_din = 0;
          wr_mhub_dout = 0;
          valid = 1;
          wr_tag = 1;
          wr_dirty = 0;
          mhub.hold = 1;
          ram.we = 0;
          ram.en = 0;
          wr_from_ram = 1;
          wr_ram_tag = 0;
          n_state = COMPARE_TAG;
        end
       default:
         n_state = COMPARE_TAG;
      endcase
    end
    
    always_ff@(posedge CLK) begin state <= n_state; end
endmodule
