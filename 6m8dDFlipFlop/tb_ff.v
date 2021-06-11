`timescale 1ns/100ps

module tb_ff;
    reg clk, rst, st, d;
    wire q1, q2, q3;

    DF1 dff1(clk, d, q1); // 일반적인 저장만 존재하는 DFF
    DFR1 dff2(clk, rst, d, q2); // 리셋이 추가된 DFF
    DFSR1 dff3(clk, st, rst, d, q3); // 셋과 리셋이 추가된 DFF

    initial forever #10 clk = ~clk; // 클럭 주기가 20ns 인 클럭 생성

    initial begin
        $dumpfile("testout.vcd");
        $dumpvars(-1, dff1);
        $dumpvars(-1, dff2);
        $dumpvars(-1, dff3);
        #0 clk = 0; d = 1; rst = 0; st = 1; 
        #10 rst = 1;
        #20 d = 0;
        #25 st = 0;
        #5 d = 1; st = 1;
        #20 d = 0;
        #30 $finish;
    end
endmodule