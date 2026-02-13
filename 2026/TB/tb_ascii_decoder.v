`timescale 1ns / 1ps
module tb_ascii_decoder ();
    reg clk;
    reg rst;
    reg [7:0] rx_data;
    reg rx_done;
    wire [7:0] opcode;

    ascii_decoder dut (
        .clk    (clk),
        .rst    (rst),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .opcode (opcode) // s_2_1_0_d_u_l_r
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 1;
        rst = 1;
        rx_data = 8'd0;
        rx_done = 0;

        @(negedge clk) rst = 0;

        // Scenario 1: non-input rx_done
        @(negedge clk); rx_done = 0; rx_data = 8'h72; // "r"
        @(negedge clk); rx_done = 0; rx_data = 8'h6C; // "l"
        @(negedge clk); rx_done = 0; rx_data = 8'h75; // "u"
        @(negedge clk); rx_done = 0; rx_data = 8'h64; // "d"
        @(negedge clk); rx_done = 0; rx_data = 8'h30; // "0"
        @(negedge clk); rx_done = 0; rx_data = 8'h31; // "1"
        @(negedge clk); rx_done = 0; rx_data = 8'h32; // "2"
        @(negedge clk); rx_done = 0; rx_data = 8'h73; // "s"

        // Scenario 2: input rx_done
        @(negedge clk); rx_done = 1; rx_data = 8'h72; // "r"
        @(negedge clk); rx_done = 1; rx_data = 8'h6C; // "l"
        @(negedge clk); rx_done = 1; rx_data = 8'h75; // "u"
        @(negedge clk); rx_done = 1; rx_data = 8'h64; // "d"
        @(negedge clk); rx_done = 1; rx_data = 8'h30; // "0"
        @(negedge clk); rx_done = 1; rx_data = 8'h31; // "1"
        @(negedge clk); rx_done = 1; rx_data = 8'h32; // "2"
        @(negedge clk); rx_done = 1; rx_data = 8'h73; // "s"

        // Scenario 3: non-define ascii input
        @(negedge clk); rx_done = 1; rx_data = 8'h33; // "3"
        @(negedge clk); rx_done = 1; rx_data = 8'h39; // "9"
        @(negedge clk); rx_done = 1; rx_data = 8'h61; // "a"
        @(negedge clk); rx_done = 1; rx_data = 8'h7a; // "z"
        
        @(negedge clk); $stop;
    end

endmodule
