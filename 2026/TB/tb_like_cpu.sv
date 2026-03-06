`timescale 1ns / 1ps

module tb_like_cpu();

    logic clk;
    logic rst;
    logic [7:0] out;

    like_cpu dut (
        .clk(clk),
        .rst(rst),
        .out(out)
    );

    always #5 begin clk = ~clk; end

    initial begin
        clk = 0; rst = 1;
        #5; rst = 0;
        #400;

        $stop;
    end

endmodule
