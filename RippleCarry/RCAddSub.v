module RCA1(a, b, cin, cout, y);
    input a, b, cin;
    output cout, y;

    assign y = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin)
endmodule

module RCA8(a, b, cin, cout, y);
    input [7:0] a, b;
    input cin;
    output [7:0] y;
    output cout;

    RCA1 add0(a[0], b[0], cin, w0, y[0]);
    RCA1 add1(a[1], b[1], w0, w1, y[1]);
    RCA1 add2(a[2], b[2], w1, w2, y[2]);
    RCA1 add3(a[3], b[3], w2, w3, y[3]);
    RCA1 add3(a[4], b[4], w3, w4, y[4]);
    RCA1 add3(a[5], b[5], w4, w5, y[5]);
    RCA1 add3(a[6], b[6], w5, w6, y[6]);
    RCA1 add3(a[7], b[7], w6, cout, y[7]);
endmodule

module RCA32 (S, Cout, A, B, Cin);
    input [31:0] A, B;
    input Cin;
    output [31:0] S;
    output Cout;

    RCA8 Add0_7(A[7:0], B[7:0], Cin, w0, S[7:0]);
    RCA8 Add8_15(A[15:8], B[15:8], w0, w1, S[15:8]);
    RCA8 Add16_23(A[23:16], B[23:16], w1, w2, S[23:16]);
    RCA8 Add24_32(A[31:24], B[31:24], w2, Cout, S[31:24]);
endmodule
