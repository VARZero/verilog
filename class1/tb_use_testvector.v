module testbench3();
    reg clk, reset;
    reg a, b, c, yexpected;
    wire y;
    reg [31:0] vectornum, errors;   // bookkeeping variables
    reg [3:0] testvectors[10000:0]; // array of testvectors

    // instantiate device under test
    sillyfunction dut(a, b, c, y);

    // generate clock (클럭 만들기 - 클럭은 이렇게 만들면 된다)
    always  // no sensitivity list, so it always executes
        begin
            clk = 1; #5; clk = 0; #5;
        end
    
    // at start of test, load vectors
    // and pulse reset

    initial 
        begin
            $readmemb("testvector.tv", testvectors);
            $dumpfile("testout.vcd");
            $dumpvars(-1, dut);
            vectornum = 0; errors = 0;
            reset = 1; #27; reset = 0;
        end

    // Note: $readmemh reads testvector files written in hexadecimal
    // $readmemb는 값을 binary로 고려하여 읽음

    // apply test vectors on rising edge of clk
    always @(posedge clk) // @()는 "괄호 안에 조건을 만족할 때마다 begin-end를 실행 해라"와 같다. (sensitivity list)
    // posedge - rising edge일때 | negedge - falling edge일때
        begin
            #1; {a, b, c, yexpected} = testvectors[vectornum]; 
        end
    
    // check results on falling edge of clk
    always @(negedge clk)
        if (~reset) begin // skip during reset
            if (y !== yexpected) begin
                $display("Error: input = %b", {a, b, c});
                $display("  outputs = %b (%b expected)", y, yexpected);
                errors = errors + 1;
            end
    
            // Note: to print in hexadecimal, use %h. For example,
            //      $display("Error: input = %h", {a, b, c});
            // %h => hex | %b => binaty

            // increment array index and read next testvector
            vectornum = vectornum + 1;
            if (testvectors[vectornum] === 4'bx) begin
                $display("%d tests completed witch %d errors", vectornum, errors);
                $finish;
            end
        end
endmodule