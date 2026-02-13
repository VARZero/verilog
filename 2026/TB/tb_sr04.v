`timescale 1ns / 1ps

module tb_top_sr04();
    reg clk;
    reg rst;
    reg start;
    reg echo;
    wire trigger;
    wire [3:0] fnd_digit;
    wire [7:0] fnd_data;

    reg run_available;

    top_sr04 dut (
        .clk(clk),
        .rst(rst),
        .start_btn(start),
        .echo(echo),
        .trigger(trigger),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );

    parameter CLOCK_TIME = 10;
    parameter CLOCK_CYCLE_1SEC = 100_000_000;
    
    parameter TRIGGER_TIME = 10_000_000; // to ns
    parameter MIN_OVER_MEASURE_TIME = 60_000_000; // to ns
    parameter MEASUREING_TYPE = 1_000; // to ns
    parameter CENTIMITER_TICK = 58; // Tick num

    parameter WAIT_TIME = 40_000 * 8;
    
    localparam TRIGGER_CYCLE = TRIGGER_TIME / CLOCK_TIME;
    localparam MIN_OVER_MEASURE_CYCLE = MIN_OVER_MEASURE_TIME / CLOCK_TIME;
    localparam MEASUREING_WAIT_CYCLE = (MEASUREING_TYPE / CLOCK_TIME) * CENTIMITER_TICK;

    // Create Clock, Tick, Available
    integer available_cnt_tb = 0;
    always #(CLOCK_TIME/2) begin 
        clk = ~clk;

        available_cnt_tb = available_cnt_tb + 1;
        if (available_cnt_tb == (MIN_OVER_MEASURE_CYCLE*2) ) begin
            run_available = 1'b1; available_cnt_tb = 0;
        end
    end

    integer scen_no = 0, check_cycle_time = 999;
    integer display_100 = 0, display_10 = 0, display_1 = 0;
    reg [31:0] wait_cycle;    

    // Centimitors
    reg [9:0] cm_random;

    initial begin
        #0; clk = 1; rst = 1;
            start = 0; echo = 0;
            run_available = 1;

        available_cnt_tb = 0;

        @(negedge clk); rst = 0;

        // run 10 times
        for (scen_no = 1; scen_no < 10; scen_no = scen_no + 1) begin
            // Scenario N: start
            
            while (~run_available) @(negedge clk);
            run_available = 0;
            
            start = 1;
            #1500000;
            @(negedge clk); start = 0;

                // Check Trigger
            while (trigger) @(negedge clk);

                // Wait
            for (check_cycle_time = 0; check_cycle_time < WAIT_TIME; check_cycle_time = check_cycle_time + 1) begin
                @(negedge clk);
            end
            echo = 1;
                // Create Random Centimiter and echo injection
            cm_random = ($random % 400);
            cm_random = (cm_random[9])? (-1 * cm_random) : cm_random;
            wait_cycle = cm_random * MEASUREING_WAIT_CYCLE;
            for (check_cycle_time = 0; check_cycle_time < wait_cycle; check_cycle_time = check_cycle_time + 1) begin
                @(negedge clk);
            end
            wait_cycle = $random % MEASUREING_WAIT_CYCLE;
            wait_cycle = (wait_cycle[31])? (-1 * wait_cycle) : wait_cycle;
            for (check_cycle_time = 0; check_cycle_time < wait_cycle; check_cycle_time = check_cycle_time + 1) begin
                @(negedge clk);
            end
            echo = 0;
            @(negedge clk);
            @(negedge clk);

            // ============ Scenario N END )
        end
        $stop;
    end
endmodule

module tb_sr04_ctrl();
    reg clk;
    reg rst;
    reg tick_us;
    reg start;
    reg echo;
    wire [8:0] dist;
    wire trigger;

    reg run_available;

    sr04_ctrl dut (
        .clk(clk),
        .rst(rst),
        .tick_us(tick_us),
        .start(start),
        .echo(echo),
        .dist(dist),
        .trigger(trigger)
    );

    parameter CLOCK_TIME = 10;
    parameter CLOCK_CYCLE_1SEC = 100_000_000;
    parameter TICK_TIME = 1_000; // to ns
    
    parameter TRIGGER_TIME = 10_000_000; // to ns
    parameter MIN_OVER_MEASURE_TIME = 60_000_000; // to ns
    parameter MEASUREING_TYPE = 1_000; // to ns
    parameter CENTIMITER_TICK = 58; // Tick num

    parameter WAIT_TIME = 40_000 * 8;
    
    localparam TICK_CYCLES = TICK_TIME / CLOCK_TIME;
    
    localparam TRIGGER_CYCLE = TRIGGER_TIME / CLOCK_TIME;
    localparam MIN_OVER_MEASURE_CYCLE = MIN_OVER_MEASURE_TIME / CLOCK_TIME;
    localparam MEASUREING_WAIT_CYCLE = (MEASUREING_TYPE / CLOCK_TIME) * CENTIMITER_TICK;

    // Create Clock, Tick, Available
    integer tick_cnt_tb = 0, available_cnt_tb = 0;
    always #(CLOCK_TIME/2) begin 
        clk = ~clk;
        tick_cnt_tb = tick_cnt_tb + 1;
        if (tick_cnt_tb == (TICK_CYCLES*2) ) begin
            tick_us = 1'b1; tick_cnt_tb = 0;
        end
        else if (tick_cnt_tb == 2) tick_us = 1'b0;

        available_cnt_tb = available_cnt_tb + 1;
        if (available_cnt_tb == (MIN_OVER_MEASURE_CYCLE*2) ) begin
            run_available = 1'b1; available_cnt_tb = 0;
        end
    end

    integer scen_no = 0, check_cycle_time = 999;
    integer display_100 = 0, display_10 = 0, display_1 = 0;
    reg [31:0] wait_cycle;    

    // Centimitors
    reg [9:0] cm_random;

    initial begin
        #0; clk = 1; rst = 1;
            tick_us = 0; start = 0; echo = 0;
            run_available = 1;

        tick_cnt_tb = 0;
        available_cnt_tb = 0;

        @(negedge clk); rst = 0;

        // run 10 times
        for (scen_no = 1; scen_no <= 10; scen_no = scen_no + 1) begin
            // Scenario N: start
            
            while (~run_available) @(negedge clk);
            run_available = 0;
            
            start = 1;
            @(negedge clk); start = 0;

                // Check Trigger
            while (~tick_us) @(negedge clk);
            for (check_cycle_time = 0; check_cycle_time < TRIGGER_CYCLE; check_cycle_time = check_cycle_time + 1) begin
                if (trigger == 0) begin
                    $display("ERROR! unexpect trigger down %d %t", check_cycle_time, $time); $stop;
                end
                @(negedge clk);
            end

                // Check wait
            if (trigger) begin
                $display("ERROR! unexpect trigger up %t", $time); $stop;
            end
            @(negedge clk);

                // Wait
            for (check_cycle_time = 0; check_cycle_time < WAIT_TIME; check_cycle_time = check_cycle_time + 1) begin
                @(negedge clk);
            end
            echo = 1;
                // Create Random Centimiter and echo injection
            cm_random = ($random % 400);
            cm_random = (cm_random[9])? (-1 * cm_random) : cm_random;
            wait_cycle = cm_random * MEASUREING_WAIT_CYCLE;
            for (check_cycle_time = 0; check_cycle_time < wait_cycle; check_cycle_time = check_cycle_time + 1) begin
                @(negedge clk);
            end
            wait_cycle = $random % MEASUREING_WAIT_CYCLE;
            wait_cycle = (wait_cycle[31])? (-1 * wait_cycle) : wait_cycle;
            for (check_cycle_time = 0; check_cycle_time < wait_cycle; check_cycle_time = check_cycle_time + 1) begin
                @(negedge clk);
            end
            echo = 0;
            @(negedge clk);

            display_100 = dist[8:7] % 10;
            display_10 = (dist[6:0] / 10) % 10;
            display_1 = dist[6:0] % 10;

            if ((display_100 == ((cm_random/100) % 10)) && (display_10 == ((cm_random/10) % 10)) && (display_1 == (cm_random % 10)))
                $display("\t PASS: %d [%t]", scen_no, $time);
            else begin
                $display("\t FAIL: %d [%t]", scen_no, $time); $stop;
            end
            // ============ Scenario N END )
        end

        $stop;
    end
endmodule
