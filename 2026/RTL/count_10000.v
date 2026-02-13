`timescale 1ns / 1ps

module top_stopwatch_watch (
    input               clk,
    input               reset,
    input   [3:0]       sw_under,
    input   [1:0]       sw_upper,
    input               btn_l,
    input               btn_r,
    input               btn_u,
    input               btn_d,
    input               uart_rx,
    output              uart_tx,
    output  [3:0]       fnd_digit,
    output  [7:0]       fnd_data
);

    wire        o_btn_r, o_btn_l, o_btn_up, o_btn_down;
    
    wire        w_mode, w_run_stop, w_clear;
    wire        w_monitor_type, w_sel_display;
    wire        w_w_modify_mode, w_w_up, w_w_down;
    wire [3:0]  w_w_modify_position;

    wire [7:0]  w_uart_opcode, w_uart_rx_data, w_ascii_data;
    wire        w_uart_tx_done, w_uart_rx_done, w_uart_tx_busy;
    wire        w_ascii_sender_running, w_ascii_sender_tx_start;

    wire [23:0] w_stopwatch_time, w_watch_time, w_out_time;

    wire        w_mode_sel, w_displayarea_sel, w_sw_w_sel;

    reg mode_sel_reg, mode_sel_next;
    reg sw_w_sel_reg, sw_w_sel_next;
    reg displayarea_sel_reg, displayarea_sel_next;

    // UART MODE SET
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            mode_sel_reg <= 1'b0;
            displayarea_sel_reg <= 1'b0;
            sw_w_sel_reg <= 1'b0;
        end
        else begin
            mode_sel_reg <= mode_sel_next;
            sw_w_sel_reg <= sw_w_sel_next;
            displayarea_sel_reg <= displayarea_sel_next;
        end
    end

    always @(*) begin
        mode_sel_next = mode_sel_reg;
        sw_w_sel_next = sw_w_sel_reg;
        displayarea_sel_next = displayarea_sel_reg;
        if (w_uart_opcode[4]) mode_sel_next = ~mode_sel_reg;
        if (w_uart_opcode[5]) sw_w_sel_next = ~sw_w_sel_reg;
        if (w_uart_opcode[6]) displayarea_sel_next = ~displayarea_sel_reg;
    end

    assign w_mode_sel = (sw_under[3])? mode_sel_reg : sw_under[0];
    assign w_sw_w_sel = (sw_under[3])? sw_w_sel_reg : sw_under[1];
    assign w_displayarea_sel = (sw_under[3])? displayarea_sel_reg : sw_under[2];

    btn_debounce U_BD_RUNSTOP(
        .clk        (clk),
        .reset      (reset),
        .i_btn      (btn_r),
        .o_btn      (o_btn_r)
    );
    
    btn_debounce U_BD_CLEAR(
        .clk        (clk),
        .reset      (reset),
        .i_btn      (btn_l),
        .o_btn      (o_btn_l)
    );

    btn_debounce U_BD_UP(
        .clk        (clk),
        .reset      (reset),
        .i_btn      (btn_u),
        .o_btn      (o_btn_up)
    );

    btn_debounce U_BD_DOWN(
        .clk        (clk),
        .reset      (reset),
        .i_btn      (btn_d),
        .o_btn      (o_btn_down)
    );

    uart_sys U_UART_SYS(
        .clk            (clk),
        .rst            (reset),
        .set_en_tx      (w_ascii_sender_running),
        .en_tx_start    (w_ascii_sender_tx_start),
        .new_tx         (w_ascii_data),
        .uart_rx        (uart_rx),
        .uart_tx        (uart_tx),
        .tx_done        (w_uart_tx_done),
        .tx_busy        (w_uart_tx_busy),
        .rx_data        (w_uart_rx_data),
        .rx_done        (w_uart_rx_done)
    );

    ascii_decoder U_ASCII_DECODER(
        .clk            (clk),
        .rst            (reset),
        .rx_data        (w_uart_rx_data),
        .rx_done        (w_uart_rx_done),
        .opcode         (w_uart_opcode)// s_2_1_0_d_u_l_r
    );

    ascii_sender U_ASCII_SENDER (
        .clk            (clk),
        .rst            (reset),
        .type_sw_w      (w_monitor_type), // sw: 0, w: 1
        .time_value     (w_out_time),
        .s_active       (w_uart_opcode[7]),
        .tx_busy        (w_uart_tx_busy),
        .tx_done        (w_uart_tx_done),
        .new_tx_data    (w_ascii_data),
        .tx_start       (w_ascii_sender_tx_start),
        .running        (w_ascii_sender_running)
    );

    control_unit U_CTRL_UNIT(
        .clk                    (clk),
        .reset                  (reset),
        .sw_under               ({w_displayarea_sel, w_sw_w_sel, w_mode_sel}),
        .sw_upper               (sw_upper),
        .btn_l                  (o_btn_l | w_uart_opcode[1]),
        .btn_r                  (o_btn_r | w_uart_opcode[0]),
        .btn_u                  (o_btn_up | w_uart_opcode[2]),
        .btn_d                  (o_btn_down | w_uart_opcode[3]),
        .o_monitor_type         (w_monitor_type),
        .o_sel_display          (w_sel_display),
        .o_sw_mode              (w_mode),
        .o_sw_run_stop          (w_run_stop),
        .o_sw_clear             (w_clear),
        .o_w_modify_mode        (w_w_modify_mode),
        .o_w_modify_position    (w_w_modify_position),
        .o_w_up                 (w_w_up),
        .o_w_down               (w_w_down)
    );

    stopwatch_datapath U_STOPWATCH_DATAPATH(
        .clk(clk),
        .reset(reset),
        .mode(w_mode),
        .clear(w_clear),
        .run_stop(w_run_stop),
        .msec(w_stopwatch_time[6:0]),
        .sec(w_stopwatch_time[12:7]),
        .min(w_stopwatch_time[18:13]),
        .hour(w_stopwatch_time[23:19])
    );

    watch_datapath U_WATCH_DATAPATH(
        .clk    (clk),
        .reset  (reset),
        .modify_mode    (w_w_modify_mode),
        .sel_timeslot   (w_w_modify_position),
        .up             (w_w_up),
        .down           (w_w_down),
        .msec   (w_watch_time[6:0]),
        .sec    (w_watch_time[12:7]),
        .min    (w_watch_time[18:13]),
        .hour   (w_watch_time[23:19])
    );

    mux_2x1_24bit U_MUX_STOPWATCH_WATCH(
        .sel(w_monitor_type),
        .i_sel0(w_stopwatch_time),
        .i_sel1(w_watch_time),
        .o_mux(w_out_time)
    );

    fnd_controller U_FND_CTRL(
        .clk(clk),
        .reset(reset),
        .sel_display(w_sel_display), // time slots
        .fnd_in_data(w_out_time),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );

endmodule

module mux_2x1_24bit (
    input       sel,
    input [23:0] i_sel0,
    input [23:0] i_sel1,
    output [23:0] o_mux
);

    assign o_mux = (sel)? i_sel1 : i_sel0;

endmodule

// (START) stopwatch section ===========

module stopwatch_datapath (
    input clk,
    input reset,
    input mode,
    input clear,
    input run_stop,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;
    
    tick_counter #(
        .BIT_WIDTH(5),
        .TIMES(24)
    ) U_HOUR_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_hour_tick),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .o_count(hour),
        .o_tick()
    );

    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) U_MIN_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_min_tick),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .o_count(min),
        .o_tick(w_hour_tick)
    );

    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) U_SEC_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_sec_tick),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .o_count(sec),
        .o_tick(w_min_tick)
    );

    tick_counter #(
        .BIT_WIDTH(7),
        .TIMES(100)
    ) U_MSEC_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_100hz),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .o_count(msec),
        .o_tick(w_sec_tick)
    );

    tick_gen_100hz U_TICK_GEN(
        .clk(clk),
        .reset(reset),
        .i_run_stop(run_stop),
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

module tick_counter #(
    parameter   BIT_WIDTH = 7,
                TIMES = 100
) (
    input                   clk,
    input                   reset,
    input                   i_tick,
    input                   mode,
    input                   clear,
    input                   run_stop,
    output [BIT_WIDTH-1:0]  o_count,
    output reg              o_tick
);

    // counter reg
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;

    assign o_count = counter_reg;

    // State reg SL
    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            counter_reg <= 0;
        end
        else begin
            counter_reg <= counter_next;
        end
    end

    // next CL
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (i_tick & run_stop) begin
            if (mode == 1'b1) begin
                // down
                if (counter_reg == 0) begin
                    counter_next = TIMES-1;
                    o_tick = 1'b1;
                end
                else begin
                    counter_next = counter_reg - 1;
                    o_tick = 1'b0;
                end
            end
            else begin
                // up
                if (counter_reg == (TIMES-1)) begin
                    counter_next = 0;
                    o_tick = 1'b1;
                end
                else begin
                    counter_next = counter_reg + 1;
                    o_tick = 1'b0;
                end
            end
        end
    end

endmodule

module tick_gen_100hz (
    input               clk,
    input               reset,
    input               i_run_stop,
    output reg          o_tick_100hz
);
    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT)-1:0] cnt_10hz;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            cnt_10hz <= 0;
            o_tick_100hz <= 0;
        end 
        else begin
            cnt_10hz <= (i_run_stop) ? cnt_10hz + 1 : cnt_10hz;
            
            if (cnt_10hz == (F_COUNT-1)) begin
                cnt_10hz <= 0;
                o_tick_100hz <= 1;
            end
            else begin
                o_tick_100hz <= 0;
            end
        end
    end

endmodule

// ====== stopwatch section (END)

// (START) watch section ===========

module watch_datapath (
    input clk,
    input reset,
    input modify_mode,
    input [3:0] sel_timeslot,
    input up,
    input down,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;
    
    tick_counter_up_modify #(
        .BIT_WIDTH(5),
        .TIMES(24)
    ) U_HOUR_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_hour_tick),
        .modify_mode( modify_mode & sel_timeslot[3] ),
        .up(up),
        .down(down),
        .o_count(hour),
        .o_tick()
    );

    tick_counter_up_modify #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) U_MIN_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_min_tick),
        .modify_mode( modify_mode & sel_timeslot[2] ),
        .up(up),
        .down(down),
        .o_count(min),
        .o_tick(w_hour_tick)
    );

    tick_counter_up_modify #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) U_SEC_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_sec_tick),
        .modify_mode( modify_mode & sel_timeslot[1] ),
        .up(up),
        .down(down),
        .o_count(sec),
        .o_tick(w_min_tick)
    );

    tick_counter_up_modify #(
        .BIT_WIDTH(7),
        .TIMES(100)
    ) U_MSEC_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_100hz),
        .modify_mode( modify_mode & sel_timeslot[0] ),
        .up(up),
        .down(down),
        .o_count(msec),
        .o_tick(w_sec_tick)
    );

    tick_gen_100hz U_TICK_GEN(
        .clk(clk),
        .reset(reset),
        .i_run_stop(1'b1),
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

module tick_counter_up_modify #(
    parameter   BIT_WIDTH = 7,
                TIMES = 100
) (
    input                   clk,
    input                   reset,
    input                   i_tick,
    input                   modify_mode,
    input                   up,
    input                   down,
    output [BIT_WIDTH-1:0]  o_count,
    output reg              o_tick
);

    // counter reg
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;

    assign o_count = counter_reg;

    // State reg SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
        end
        else begin
            counter_reg <= counter_next;
        end
    end

    // next CL
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (modify_mode) begin
            // modify time
            o_tick = 1'b0;
            if (up) begin
                if (counter_reg == (TIMES-1)) begin
                    counter_next = 0;
                end
                else begin
                    counter_next = counter_reg + 1;
                end
            end
            else if (down) begin
                if (counter_reg == 0) begin
                    counter_next = (TIMES-1);
                end
                else begin
                    counter_next = counter_reg - 1;
                end
            end
        end
        else begin
            // normal mode
            if (i_tick) begin
                if (counter_reg == (TIMES-1)) begin
                    counter_next = 0;
                    o_tick = 1'b1;
                end
                else begin
                    counter_next = counter_reg + 1;
                    o_tick = 1'b0;
                end
            end
        end
    end

endmodule

// ====== watch section (END)

/*
// (START) alarm section ===========

module alarm_datapath (
    input clk,
    input reset,
    input modify_mode,
    input [3:0] sel_timeslot,
    input up,
    input down,
    input [6:0] i_msec,
    input [5:0] i_sec,
    input [5:0] i_min,
    input [4:0] i_hour,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour,
    output led
);
    
    value_set #(
        .BIT_WIDTH(5),
        .TIMES(24)
    ) U_HOUR_COUNTER (
        .clk(clk),
        .reset(reset),
        .modify_mode( modify_mode & sel_timeslot[3] ),
        .up(up),
        .down(down),
        .o_count(hour)
    );

    value_set #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) U_MIN_SET (
        .clk(clk),
        .reset(reset),
        .modify_mode( modify_mode & sel_timeslot[2] ),
        .up(up),
        .down(down),
        .o_count(min)
    );

    value_set #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) U_SEC_SET (
        .clk(clk),
        .reset(reset),
        .modify_mode( modify_mode & sel_timeslot[1] ),
        .up(up),
        .down(down),
        .o_count(sec)
    );

    value_set #(
        .BIT_WIDTH(7),
        .TIMES(100)
    ) U_MSEC_SET (
        .clk(clk),
        .reset(reset),
        .modify_mode( modify_mode & sel_timeslot[0] ),
        .up(up),
        .down(down),
        .o_count(msec)
    );
    
endmodule

module alarm_system(
    input                   clk,
    input                   reset,
    input [7:0]             
);

endmodule

module value_set #(
    parameter   BIT_WIDTH = 7,
                TIMES = 100
) (
    input                   clk,
    input                   reset,
    input                   modify_mode,
    input                   up,
    input                   down,
    output [BIT_WIDTH-1:0]  o_count
);

    // counter reg
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;

    assign o_count = counter_reg;

    // State reg SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
        end
        else begin
            counter_reg <= counter_next;
        end
    end

    // next CL
    always @(*) begin
        counter_next = counter_reg;
        if (modify_mode) begin
            // modify time
            if (up) begin
                if (counter_reg == (TIMES-1)) begin
                    counter_next = 0;
                end
                else begin
                    counter_next = counter_reg + 1;
                end
            end
            else if (down) begin
                if (counter_reg == 0) begin
                    counter_next = (TIMES-1);
                end
                else begin
                    counter_next = counter_reg - 1;
                end
            end
        end
    end

endmodule

// ====== alarm section (END)
*/