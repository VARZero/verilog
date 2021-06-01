module tb_RCA;
    reg [31:0] A, B;
    reg Cin;
    wire [31:0] S;
    wire Cout;

    RCA32 Adder(S, Cout, A, B, Cin);

    initial begin
        A = 32'd10; B = 32'd20; Cin = 0; #10;
        if (S !== 32'd30 || Cout !== 0) $display("1.failed");
        A = 32'd53250; #10;
        if (S !== 32'd53270 || Cout !== 0) $display("2.failed");
        A = 32'hffffffff; B = 32'h3; #10;
        if (S !== 32'h2 || Cout !== 1) $display("3.failed");
        A = 32'he3244bbe; B = 32'hd332ff2; #10;
        if (S !== 32'hf0577bb0 || Cout !== 0) $display("4.failed");
        A = 32'hffff0000; B = 32'h205da; #10;
        if (S !== 32'h105da || Cout !== 1) $display("5.failed");
    end
endmodule