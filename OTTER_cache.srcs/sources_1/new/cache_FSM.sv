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
    output logic we_mem, en_mem, wr_dirty, valid, wr_tag, cpu_hold
    );

    typedef enum logic[1:0] {COMPARE_TAG,WRITEBACK,ALLOCATE} state_type;
    state_type state;

    initial begin state = COMPARE_TAG; end

    always @(posedge CLK) begin
      case (state)
        COMPARE_TAG: begin
          if (miss) begin
            if (dirty)
              state <= WRITEBACK;
            else
              state <= ALLOCATE;
          end
          else begin
            if (en) begin
              cpu_hold <= 0;
              valid <= 1;
              wr_tag <= 1;
              if (we)
                wr_dirty <= 1;
              else
                wr_dirty <= 0;
            end
            else
              cpu_hold <= 1;
              valid <= 0;
            state <= COMPARE_TAG;
          end
        end
        WRITEBACK: begin
          valid <= 0;
          wr_tag <= 0;
          wr_dirty <= 0;
          cpu_hold <= 1;
          en_mem <= 0;
          we_mem <= 1;
          if (ready) 
            state <= ALLOCATE;
          else
            state <= WRITEBACK;
        end
        ALLOCATE: begin
          valid <= 0;
          wr_tag <= 0;
          wr_dirty <= 0;
          cpu_hold <= 1;
          we_mem <= 0;
          en_mem <= 1;
          if (ready)
            state <= COMPARE_TAG;
          else
            state <= ALLOCATE;
        end
      endcase
    end
endmodule
