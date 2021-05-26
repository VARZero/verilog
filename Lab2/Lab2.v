module fadder_1bit(y, Co, Ci, a, b);
    input a, b, Ci;
    output y, Co;

    assign y = (a ^ b) ^ Ci;
    assign Co = (a & b) | (a & Ci) | (b & Ci);
endmodule

module fadder_4bit(y, Co, a, b);
    input [3:0] a, b;
    output [3:0] y;
    output Co;

    fadder_1bit ab0(.y(y[0]), .Co(w0), .Ci(1'b0), .a(a[0]), .b(b[0]));
    fadder_1bit ab1(.y(y[1]), .Co(w1), .Ci(w0), .a(a[1]), .b(b[1]));
    fadder_1bit ab2(.y(y[2]), .Co(w2), .Ci(w1), .a(a[2]), .b(b[2]));
    fadder_1bit ab3(.y(y[3]), .Co(w3), .Ci(w2), .a(a[3]), .b(b[3]));
    assign Co = w3;
endmodule