`timescale 1ns / 1ps
module tb_ascii_sender ();
    reg clk;
    reg rst;
    reg type_sw_w; // sw: 0, w: 1
    reg [23:0] time_value;
    reg s_active;
    reg tx_busy;
    reg tx_done;
    wire [7:0] new_tx_data;
    wire tx_start;
    wire running;

    integer scen_no = 0;

    ascii_sender dut (
        .clk            (clk),
        .rst            (rst),
        .type_sw_w      (type_sw_w),
        .time_value     (time_value),
        .s_active       (s_active),
        .tx_busy        (tx_busy),
        .tx_done        (tx_done),
        .new_tx_data    (new_tx_data),
        .tx_start       (tx_start),
        .running        (running)
    );

    always #5 clk = ~clk;

    initial begin
        #0; 
        clk = 1;
        rst = 1;
        type_sw_w = 1'b0;
        time_value = 24'b0;
        s_active = 1'b0;
        tx_busy = 1'b0;
        tx_done = 1'b0;

        @(negedge clk); rst = 0;

        // Scenario 1: SW Send 12:43:05.96
        scen_no = 1;
        type_sw_w = 1'b0; time_value = {5'd12, 6'd43, 6'd05, 7'd96};
        s_active = 1'b1; tx_done = 1'b0; tx_busy = 1'b0;
        @(negedge clk); s_active = 1'b0;
        while(running) begin
            @(negedge clk);
            @(negedge clk);
            @(negedge clk); tx_done = 1'b1;
            @(negedge clk); tx_done = 1'b0;
        end
        @(negedge clk);

        // Scenario 2: W Send 12:43:05.96
        scen_no = 2;
        type_sw_w = 1'b1; time_value = {5'd12, 6'd43, 6'd05, 7'd96};
        s_active = 1'b1; tx_done = 1'b0; tx_busy = 1'b1;
        @(negedge clk); s_active = 1'b0; 
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk); tx_busy = 1'b0;
        while(running) begin
            @(negedge clk);
            @(negedge clk);
            @(negedge clk); tx_done = 1'b1;
            @(negedge clk); tx_done = 1'b0;
        end
        @(negedge clk);

        // Scenario 3: W Send 23:59:59.00
        scen_no = 3;
        type_sw_w = 1'b1; time_value = {5'd23, 6'd59, 6'd59, 7'd00};
        s_active = 1'b1; tx_done = 1'b0; tx_busy = 1'b0;
        @(negedge clk); s_active = 1'b0;
        while(running) begin
            @(negedge clk);
            @(negedge clk);
            @(negedge clk); tx_done = 1'b1;
            @(negedge clk); tx_done = 1'b0;
        end
        @(negedge clk);

        $stop;
    end
endmodule
