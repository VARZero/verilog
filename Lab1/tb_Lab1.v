`timescale 1ns/100ps

module test_mx2;
    reg d0, d1, s;
    wire y;

mx2 mx_top (y, d0, d1, s);

initial
begin
    $dumpfile("test_out.vcd");
    $dumpvars(-1, mx_top);
    #0  d0=0; d1=1; s=0;
    #10 s=1;
    #10 d1=0;
    #10 d0=1;
    #10 s=0;
    #10 $finish;
end

endmodule