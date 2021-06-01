module RCA1(a, b, cin, cout, y);
    input a, b, cin;
    output cout, y;

    assign y = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

module RCA8(a8, b8, c8in, c8out, y8); // 8bit로 분할한 RCA
    input [7:0] a8, b8;
    input c8in;
    output [7:0] y8;
    output c8out;

    RCA1 add0(a8[0], b8[0], c8in, i0, y8[0]);
    RCA1 add1(a8[1], b8[1], i0, i1, y8[1]);
    RCA1 add2(a8[2], b8[2], i1, i2, y8[2]);
    RCA1 add3(a8[3], b8[3], i2, i3, y8[3]);
    RCA1 add4(a8[4], b8[4], i3, i4, y8[4]);
    RCA1 add5(a8[5], b8[5], i4, i5, y8[5]);
    RCA1 add6(a8[6], b8[6], i5, i6, y8[6]);
    RCA1 add7(a8[7], b8[7], i6, c8out, y8[7]);
endmodule

module RCA32 (S, Cout, A, B, Cin);
    input [31:0] A, B;
    input Cin;
    output [31:0] S;
    output Cout;
    // 8bit로 분할한 RCA 4개를 연결하여 32bit RCA 구현
    RCA8 Add0_7(A[7:0], B[7:0], Cin, w0, S[7:0]);
    RCA8 Add8_15(A[15:8], B[15:8], w0, w1, S[15:8]);
    RCA8 Add16_23(A[23:16], B[23:16], w1, w2, S[23:16]);
    RCA8 Add24_31(A[31:24], B[31:24], w2, Cout, S[31:24]);
endmodule
