module iv(y, a);
    input a;
    output y;

assign y = ~a;

endmodule

module nd2(y, a, b);
    input a, b;
    output y;

assign y = ~(a & b);

endmodule

module mx2(y, d0, d1, s);
    input d0, d1, s;
    output y;

iv iv0 (.y(sb), .a(s));
nd2 nd20 (.y(w0), .a(d0), .b(sb));
nd2 nd21 (.y(w1), .a(d1), .b(s));
nd2 nd22 (y, w0 , w1);

endmodule