module flipflopEx(CLK, D, Reset, Q);
    input CLK, D, Q;
    output reg Q;

    always @(posedge CLK or negedge Reset) begin
        if (!Reset) begin
            Q <= 0;
        end
        else begin
            Q <= D;
        end
    end
endmodule