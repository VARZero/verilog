// 리셋과 셋이 존재하는 D-플립플롭
module DFSR1(clk, st, rst, d, q);
    input clk, st, rst, d;
    output q;
    reg q;

    always @ (posedge clk or negedge rst or negedge st) begin
        // rst이나 st이 0으로 떨어졌을때 초기화
        if (rst == 1'b0) q <= 1'b0;
        else if (st == 1'b0) q <= 1'b1;
        else q <= d; // 클럭 positive edge에서는 D를 Q로
    end
endmodule

// 리셋만 존재하는 D-플립플롭
module DFR1(clk, rst, d, q);
    input clk, rst, d;
    output q;
    reg q;

    always @ (posedge clk or negedge rst) begin
        if (rst == 1'b0) q <= 1'b0;
        else q <= d;
    end
endmodule