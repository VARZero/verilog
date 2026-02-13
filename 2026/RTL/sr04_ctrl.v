`timescale 1ns / 1ps

module top_sr04(
    input               clk,
    input               rst,
    input               start_btn,
    input               echo,
    output              trigger,
    output      [3:0]   fnd_digit,
    output      [7:0]   fnd_data
);
    wire tick_us, w_btn;
    wire [8:0] w_dist;

    btn_debounce U_BTN_DEBOUNCE(
        .clk(clk),
        .reset(rst),
        .i_btn(start_btn),
        .o_btn(w_btn)
    );

    tick_gen #(.CLOCK_CYCLE_1SEC(100000000), .TARGET_TIME(1000000)) 
        U_TICK_GET (
            .clk(clk),
            .rst(rst),
            .b_tick(tick_us)
        );

    sr04_ctrl U_SR04_CTRL(
        .clk(clk),
        .rst(rst),
        .tick_us(tick_us),
        .start(w_btn),
        .echo(echo),
        .dist(w_dist),
        .trigger(trigger)
    );

    fnd_controller U_FND_CTRL(
        .clk(clk),
        .reset(rst),
        .sel_display(1'b0),
        .fnd_in_data({15'b0, w_dist}),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );
    
endmodule

module sr04_ctrl(
    input               clk,
    input               rst,
    input               tick_us,
    input               start,
    input               echo,
    output [8:0]        dist,
    output              trigger
);
    // Constant
    parameter CLOCK_CYCLE_1SEC = 100_000_000; // to ns
    parameter TRIG_TIME = 10_000_000; // to ns
    parameter TICK_TIME = 1_000; // to ns
    parameter CLOCK_TIME = 10; // to ns
    parameter MIN_OVER_MEASURE_TIME = 60_000_000; // to ns
    parameter MEASUREING_TYPE = 1_000; // to ns
    parameter CENTIMITER_TICK = 58; // Tick num
    parameter MAXIMUM_MM = 400;
    
    localparam TRIG_TICK = TRIG_TIME / TICK_TIME;
    localparam BITWIDTH_TRIG_TICK = $clog2(TRIG_TICK+1);

    localparam TICK_CYCLES = CLOCK_CYCLE_1SEC / TICK_TIME;
    
    localparam MIN_OVER_MEASURE_TICK = MIN_OVER_MEASURE_TIME / TICK_TIME;
    localparam BITWIDTH_MEASURE_TICK = $clog2(MIN_OVER_MEASURE_TICK);

    localparam BITWIDTH_CENTIMITER_TICK = $clog2(CENTIMITER_TICK);

    localparam BITWIDTH_MAXIMUM_MM = $clog2(MAXIMUM_MM);

    // States
    localparam IDLE = 2'd0, START = 2'd1, WAIT = 2'd2, GET_DIST = 2'd3;

    // Registers
    reg [BITWIDTH_TRIG_TICK-1:0] trig_cnt_reg, trig_cnt_next;
    reg [1:0] state, state_next;
    reg [BITWIDTH_CENTIMITER_TICK-1:0] cm_tick_reg, cm_tick_next;
    reg [BITWIDTH_MAXIMUM_MM-1:0] cm_reg, cm_next;
    reg [BITWIDTH_MEASURE_TICK:0] min_run_cnt_reg, min_run_cnt_next; // MSB is OVER TIME
    reg trig_reg, trig_next; 

    reg [8:0] dist_reg, dist_next;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= IDLE;
            trig_cnt_reg <= 0;
            cm_tick_reg <= 0;
            cm_reg <= 0;
            min_run_cnt_reg[BITWIDTH_MEASURE_TICK] <= 1;
            min_run_cnt_reg[BITWIDTH_MEASURE_TICK-1:0] <= 0;
            trig_reg <= 0;

            dist_reg <= 0;
        end
        else begin
            state <= state_next;
            trig_cnt_reg <= trig_cnt_next;
            cm_tick_reg <= cm_tick_next;
            cm_reg <= cm_next;
            min_run_cnt_reg <= min_run_cnt_next;
            trig_reg <= trig_next;

            dist_reg <= dist_next;
        end
    end

    // Next or output
    always @(*) begin
        state_next = state;
        trig_cnt_next = trig_cnt_reg;
        cm_tick_next = cm_tick_reg;
        cm_next = cm_reg;
        min_run_cnt_next = min_run_cnt_reg;

        dist_next = dist_reg;
        trig_next = trig_reg;

        // min measure cycle checker
        if (tick_us) begin
            if (min_run_cnt_reg[BITWIDTH_MEASURE_TICK]) begin
                min_run_cnt_next = min_run_cnt_reg;
            end
            else if ((min_run_cnt_reg == (MIN_OVER_MEASURE_TICK-1))) begin
                min_run_cnt_next[BITWIDTH_MEASURE_TICK] = 1;
                min_run_cnt_next[BITWIDTH_MEASURE_TICK-1:0] = 0;
            end
            else begin
                min_run_cnt_next = min_run_cnt_reg + 1;
            end 
        end
        
        case(state)
            IDLE: begin
                // Initialization Registers
                trig_cnt_next = 0;
                cm_tick_next = 0;
                cm_next = 0;
                trig_next = 0;

                if (start & min_run_cnt_reg[BITWIDTH_MEASURE_TICK]) begin
                    state_next = START;

                    min_run_cnt_next = 0;
                end
            end
            START: begin
                if (tick_us) begin
                    trig_cnt_next = trig_cnt_reg + 1;
                    if (trig_cnt_reg == TRIG_TICK) begin
                        state_next = WAIT;
                        trig_next = 1'b0;
                    end
                    else if (trig_cnt_reg == 0) trig_next = 1'b1;
                end
            end
            WAIT: if (echo) state_next = GET_DIST;
            GET_DIST: begin
                if (tick_us) begin
                    cm_tick_next = cm_tick_reg + 1;
                    if (cm_tick_reg == (CENTIMITER_TICK-1)) begin
                        cm_next = cm_reg + 1;
                        cm_tick_next = 0;
                    end
                end

                if (~echo) begin
                    state_next = IDLE;

                    dist_next[6:0] = cm_reg % 100;
                    dist_next[8:7] = cm_reg / 100;
                end
            end
        endcase
    end
    
    assign dist = dist_reg;
    assign trigger = trig_reg;

endmodule

module tick_gen #(
    parameter CLOCK_CYCLE_1SEC = 100_000_000,
    parameter TARGET_TIME = 1_000
) (
    input clk,
    input rst,
    output reg b_tick
);
    localparam TICK_CYCLES = CLOCK_CYCLE_1SEC / TARGET_TIME;
    localparam TICK_CNT_WIDTH = $clog2(TICK_CYCLES);

    // Counter Register
    reg [TICK_CNT_WIDTH-1:0] cnt, cnt_next;  // Feed-Back

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            cnt <= 0;
        end else begin
            cnt <= cnt_next;
        end
    end

    always @(*) begin
        b_tick   = 0;
        cnt_next = cnt + 1;
        if (cnt == (TICK_CYCLES - 1)) begin
            b_tick   = 1;
            cnt_next = 0;
        end
    end

endmodule