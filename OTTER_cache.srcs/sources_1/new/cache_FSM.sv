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
    input CLK, miss, dirty, ready;
    output logic wr_dirty, valid, tag;
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
            state <= COMPARE_TAG;
          end
        end
        WRITEBACK: begin
          if (ready) begin
            state <= ALLOCATE;
          else
            state <= WRITEBACK;
          end
        end
        ALLOCATE: begin
          if (ready) begin
            state <= COMPARE_TAG;
          else
            state <= ALLOCATE;
          end
        end
      endcase
    end
endmodule
