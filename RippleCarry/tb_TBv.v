module RCAtv;
    reg clk, rst;
    reg [31:0] a, b, sExp;
    reg cin, coExp;
    wire [31:0] s;
    wire cout;
    reg [31:0] vectornum, errors;
    reg [98:0] tvs[10000:0]; // testvectors

    RCA32 adder(s, cout, a, b, cin);

    always
        begin
            clk = 1; #5; clk = 0; #5;
        end
    
    initial
        begin
            $readmemh("testvalues.txt", tvs)
            vectornum = 0; errors = 0;
            rst = 1; #27# rst = 0;
        end
    
    always @(posedge clk)
        begin
            #1; {a[31:0], b[31:0], cin, s[31:0], cout, coExp} = tvs[vectornum];
        end
    
    always @(negedge clk)
        begin
            if (~rst) begin
                if (s !== sExp) begin
                    $display("Error: input = %h", {a[31:0], b[31:0], cin});
                    $display("  output = %h, %b (Expected - %h, %b)", s[31:0], cout, sExp[31:0], coExp);
                end

                vectornum = vectornum + 1;
                if (tvs[vectornum] === 99'bx) begin
                    $display("%d tests complete, %d errors", vectornum, errors);
                end
            end
        end
endmodule