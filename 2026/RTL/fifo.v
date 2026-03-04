`timescale 1ns / 1ps
module fifo #(
    parameter DEPTH = 8,
    parameter BIT_WIDTH = 8
) (
    input                           clk,
    input                           rst,
    input                           push,
    input                           pop,
    input      [BIT_WIDTH-1:0]      push_data,
    output     [BIT_WIDTH-1:0]      pop_data,
    output                          full,
    output                          empty
);
    
    wire [$clog2(DEPTH)-1:0] wptr;
    wire [$clog2(DEPTH)-1:0] rptr;
    wire                     we;
    
    assign we = (~full) & push;

    register_file #(.DEPTH(DEPTH), .BIT_WIDTH(BIT_WIDTH))
        U_REG_FI (
                    .clk(clk),
                    .r_addr(rptr),
                    .w_addr(wptr),
                    .we(we),
                    .push_data(push_data),
                    .pop_data(pop_data)
    );

    control_unit #(.DEPTH(DEPTH)) 
        U_CTRL_UNIT(
            .clk    (clk),
            .rst    (rst),
            .push   (push),
            .pop    (pop),
            .wptr   (wptr),
            .rptr   (rptr),
            .full   (full),
            .empty  (empty)
    );

endmodule

module register_file #(
    parameter DEPTH = 4,
    parameter BIT_WIDTH = 8
) (
    input                           clk,
    input      [$clog2(DEPTH)-1:0]  r_addr,
    input      [$clog2(DEPTH)-1:0]  w_addr,
    input                           we,
    input      [BIT_WIDTH-1:0]      push_data,
    output     [BIT_WIDTH-1:0]      pop_data
);
    reg [BIT_WIDTH-1:0] register_file [0:DEPTH-1];

    // push (write) => Register file
    always @(posedge clk) begin
        if (we) register_file[w_addr] <= push_data; // push
        //else pop_data <= register_file[r_addr];
    end

    // read
    assign pop_data = register_file[r_addr];

endmodule

module control_unit #(
    parameter DEPTH = 4
) (
    input                           clk,
    input                           rst,
    input                           push,
    input                           pop,
    output     [$clog2(DEPTH)-1:0]  wptr,
    output     [$clog2(DEPTH)-1:0]  rptr,
    output                          full,
    output                          empty
);  
    reg [1:0] c_state, n_state;

    // pointer registers
    reg [$clog2(DEPTH)-1:0] wptr_reg, wptr_next;
    reg [$clog2(DEPTH)-1:0] rptr_reg, rptr_next;
    reg full_reg, full_next;
    reg empty_reg, empty_next;
    assign wptr = wptr_reg;
    assign rptr = rptr_reg;
    assign full = full_reg;
    assign empty = empty_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= 2'b00;
            
            wptr_reg <= 0;
            rptr_reg <= 0;
            full_reg <= 0;
            empty_reg <= 1;
        end
        else begin
            c_state <= n_state;

            wptr_reg <= wptr_next;
            rptr_reg <= rptr_next;
            full_reg <= full_next;
            empty_reg <= empty_next;
        end
    end

    // next st, output
    always @(*) begin
        n_state = c_state;
        
        wptr_next = wptr_reg;
        rptr_next = rptr_reg;
        full_next = full_reg;
        empty_next = empty_reg;
        
        case ({push, pop})
            2'b10: begin
                // push only
                if (!full_reg) begin
                    wptr_next = wptr_reg + 1;
                    empty_next = 1'b0;
                    if (wptr_next == rptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end
            2'b01: begin
                // pop only
                if (!empty_reg) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                    if (wptr_reg == rptr_next) begin
                        empty_next = 1'b1;
                    end
                end
            end
            2'b11: begin
                // push pop at same time
                if (full_reg == 1) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end
                else if (empty_reg == 1) begin
                    wptr_next = wptr_reg + 1;
                    empty_next = 1'b0;
                end
                else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase
    end

endmodule
