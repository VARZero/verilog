module DF1(clk, d, q);
    input clk, d;
    output q;

    reg q;

    always @ (posedge clk) begin
        q <= d;
    end
endmodule

// clk의 상승 엣지에서 d의 값을 non-blocking으로 q에 지정