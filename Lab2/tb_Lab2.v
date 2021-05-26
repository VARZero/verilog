`timescale 1ns/100ps

module test_fad4;
    reg [3:0] a, b;
    wire [3:0] y;
    wire Co;

fadder_4bit fad4(y, Co, a, b);

initial
begin
    $dumpfile("adder_out.vcd");
    $dumpvars(-1, fad4);
    #0  a=4'b0001; b=4'b0110;
    #10 a=4'b1101;
    #10 $finish;
end

endmodule