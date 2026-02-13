`timescale 1ns / 1ps
module control_unit(
    input           clk,
    input           reset,
    input [2:0]     sw_under,
    input [1:0]     sw_upper,
    input           btn_l,
    input           btn_r,
    input           btn_u,
    input           btn_d,
    output reg      o_monitor_type, // SW? W?
    output          o_sel_display,  // s-ms / h-m
    output          o_sw_mode,
    output reg      o_sw_run_stop,
    output reg      o_sw_clear,
    output reg      o_w_modify_mode,
    output reg [3:0] o_w_modify_position,
    output          o_w_up,
    output          o_w_down
);

    // State
    localparam  SYS_SW          = 2'b00,
                SYS_W           = 2'b10,
                SYS_W_MODIFY    = 2'b11;

    localparam  SW_STOP    = 2'b00,
                SW_RUN     = 2'b01,
                SW_CLEAR   = 2'b10;
    
    wire sel_sw_ud, sel_sw_w, sel_sec_hm, sel_RL, sel_modify;

    assign sel_sw_ud = sw_under[0];
    assign sel_sw_w = sw_under[1];
    assign sel_sec_hm = sw_under[2];

    assign sel_RL = sw_upper[0];
    assign sel_modify = sw_upper[1];

    assign o_sel_display = sel_sec_hm;
    assign o_sw_mode = sel_sw_ud;

    assign o_w_up = btn_u;
    assign o_w_down = btn_d;

    // State Variable
    reg [1:0] sys_state, next_sys_state;
    reg [1:0] sw_state, next_sw_state;

    // State Register SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            sys_state <= SYS_SW;
            sw_state <= SW_STOP;
        end
        else begin
            sys_state <= next_sys_state;
            sw_state <= next_sw_state;
        end
    end

    // Next State Logic CL
    always @(*) begin
        // System
        next_sys_state = sys_state;
        case (sys_state)
            SYS_SW: begin
                if (sel_sw_w) begin
                    next_sys_state = (sel_modify)? SYS_W_MODIFY : SYS_W;
                end
            end
            SYS_W: begin
                if (~sel_sw_w) begin next_sys_state = SYS_SW; end
                else if (sel_modify) begin next_sys_state = SYS_W_MODIFY; end
            end
            SYS_W_MODIFY: begin
                if (~sel_sw_w) begin next_sys_state = SYS_SW; end
                else if (~sel_modify) begin next_sys_state = SYS_W; end
            end
        endcase

        // Stopwatch
        next_sw_state = sw_state;
        case (sw_state)
            SW_STOP: begin
                if (sys_state == SYS_SW) begin
                    if (btn_l) next_sw_state = SW_CLEAR;
                    else if (btn_r) next_sw_state = SW_RUN;
                end
            end
            SW_RUN: begin
                if (sys_state == SYS_SW) begin
                    if (btn_r) next_sw_state = SW_STOP;
                end
            end
            SW_CLEAR: begin
                next_sw_state = SW_STOP;
            end
        endcase
    end

    // Output Logic CL
    always @(*) begin
        // System
        o_monitor_type = 1'b0;
        o_w_modify_mode = 1'b0;
        o_w_modify_position = 4'b0000;
        case (sys_state)
            SYS_SW: begin
                o_monitor_type = 1'b0;
                o_w_modify_mode = 1'b0;
                o_w_modify_position = 4'b0000;
            end
            SYS_W: begin
                o_monitor_type = 1'b1;
                o_w_modify_mode = 1'b0;
                o_w_modify_position = 4'b0000;
            end
            SYS_W_MODIFY: begin
                o_monitor_type = 1'b1;
                o_w_modify_mode = 1'b1;
                case ({sel_sec_hm, sel_RL})
                    2'b00: o_w_modify_position = 4'b0001;
                    2'b01: o_w_modify_position = 4'b0010;
                    2'b10: o_w_modify_position = 4'b0100;
                    2'b11: o_w_modify_position = 4'b1000;
                endcase
            end
        endcase

        // Stopwatch
        o_sw_run_stop = 1'b0;
        o_sw_clear = 1'b0;
        case (sw_state)
            SW_STOP: begin
                o_sw_run_stop = 1'b0;
                o_sw_clear = 1'b0;
            end
            SW_RUN: begin
                o_sw_run_stop = 1'b1;
                o_sw_clear = 1'b0;
            end
            SW_CLEAR: begin
                o_sw_run_stop = 1'b0;
                o_sw_clear = 1'b1;
            end
        endcase
    end
    

endmodule
