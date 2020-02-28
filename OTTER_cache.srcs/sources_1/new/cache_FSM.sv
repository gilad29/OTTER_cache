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
    input CLK, miss, dirty, ready, en, we,
    i_mhub_to_dcache.device mhub,
    i_dcache_to_ram.controller ram,
    output logic we_mem, en_mem, wr_dirty, valid, wr_tag, cpu_hold, wr_from_ram
    );

    typedef enum logic[1:0] {COMPARE_TAG,WRITEBACK,ALLOCATE_READ_RAM,ALLOCATE_SAVE} state_type;
    state_type state, n_state;

    //initial begin state = COMPARE_TAG; end
    
    always_comb begin
      n_state = state;
      case (state)
        COMPARE_TAG: begin
          en_mem = 0;
          we_mem = 0;
          wr_from_ram = 0;
          if (miss) begin
            if (dirty) begin
              en_mem = 0;
              n_state = WRITEBACK;
            end
            else begin
                if (en) begin
                  n_state = ALLOCATE_READ_RAM;
                  en_mem = 1;
                end
                else
                  n_state = COMPARE_TAG;
            end
            cpu_hold = 1;
            wr_dirty = 0;
            wr_tag = 0;
            valid = 0;  
          end
          else begin
            en_mem = 1;
            if (en) begin
              cpu_hold = 0;
              valid = 1;
              wr_tag = 1;
              if (we)
                wr_dirty = 1;
              else
                wr_dirty = 0;
            end
            else
              cpu_hold = 1;
              valid = 0;
              wr_tag = 0;
              wr_dirty = 0;
            n_state = COMPARE_TAG;
          end
        end
        WRITEBACK: begin
          valid = 0;
          wr_tag = 0;
          wr_dirty = 0;
          cpu_hold = 1;
          en_mem = 0;
          we_mem = 1;
          wr_from_ram = 0;
          if (ready)
            n_state = ALLOCATE_READ_RAM;
          else
            n_state <= WRITEBACK;
        end
        ALLOCATE_READ_RAM: begin
          valid = 0;
          wr_tag = 0;
          wr_dirty = 0;
          cpu_hold = 1;
          we_mem = 0;
          en_mem = 1;
          wr_from_ram = 0;
          //ram.baddr = mhub.waddr;
          if (ready)
            n_state = ALLOCATE_SAVE;
          else
            n_state = ALLOCATE_READ_RAM;
        end
        ALLOCATE_SAVE: begin
          valid = 1;
          wr_tag = 1;
          wr_dirty = 0;
          cpu_hold = 1;
          we_mem = 0;
          en_mem = 0;
          n_state = COMPARE_TAG;
        end
       default:
         n_state = COMPARE_TAG;
      endcase
    end
    
    always_ff@(posedge CLK) begin state <= n_state; end
endmodule
