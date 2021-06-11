// Procedural Assignments - 절차적 할당
module mx2_Procedural(y, d0, d1, s);
    input d0, d1, s;
    output y;

    always @ (d0 or d1 or s) begin
        y = (s == 1'b0) ? d0 : d1; // assign을 사용하지 않음
    end
endmodule

// Continuous Assignments - 연속적 할당
module mx2_Continuous(y, d0, d1, s);
    input d0, d1, s;
    output s;

    assign y = (s == 1'b0) ? d0 : d1; // assign을 사용함.
endmodule