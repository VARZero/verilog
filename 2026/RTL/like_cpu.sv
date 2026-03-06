`timescale 1ns / 1ps

module like_cpu(
    input clk,
    input rst,
    output [7:0] out
);

    logic w_alt11, w_regsrc, w_aload, w_sumload, w_alusrc, w_outsel;

    control_unit U_CTRL_UNIT (
        .clk(clk),
        .rst(rst),
        .i_al11(w_alt11),
        .o_regsrc(w_regsrc),
        .o_aload(w_aload),
        .o_sumload(w_sumload),
        .o_alusrc(w_alusrc),
        .o_outsel(w_outsel)
    );

    datapath U_DP (
        .clk(clk),
        .rst(rst),
        .i_regsrc(w_regsrc),
        .i_aload(w_aload),
        .i_sumload(w_sumload),
        .i_alusrc(w_alusrc),
        .i_outsel(w_outsel),
        .o_al11(w_alt11),
        .o_sumout(out)
    );

endmodule

module control_unit(
    input clk,
    input rst,
    input i_al11,
    output logic o_regsrc,
    output logic o_aload,
    output logic o_sumload,
    output logic o_alusrc,
    output logic o_outsel
);

    typedef enum logic [2:0] { S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4 } state_t;

    state_t state, state_next;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) state <= S0;
        else state <= state_next;
    end

    // next/output logic
    always_comb begin
        state_next  = state;

        o_regsrc    = 0;
        o_aload     = 0;
        o_sumload   = 0;
        o_alusrc    = 0;
        o_outsel    = 0;

        case(state)
            S0: begin state_next = S1; 
                    o_regsrc = 0; o_aload = 0; o_sumload = 0; o_alusrc = 0; o_outsel = 0; end
            S1: begin state_next = (i_al11)? S2 : S4; 
                    o_regsrc = 0; o_aload = 0; o_sumload = 0; o_alusrc = 0; o_outsel = 0; end
            S2: begin state_next = S3; 
                    o_regsrc = 1; o_aload = 0; o_sumload = 1; o_alusrc = 0; o_outsel = 0; end
            S3: begin state_next = S1; 
                    o_regsrc = 1; o_aload = 1; o_sumload = 0; o_alusrc = 1; o_outsel = 0; end
            S4: begin state_next = S4; 
                    o_regsrc = 0; o_aload = 0; o_sumload = 0; o_alusrc = 0; o_outsel = 1; end
        endcase
    end

endmodule

module datapath(
    input clk,
    input rst,
    input i_regsrc,
    input i_aload,
    input i_sumload,
    input i_alusrc,
    input i_outsel,
    output o_al11,
    output [7:0] o_sumout
);

    logic [7:0] w_mux_a, w_reg_a, w_mux_sum, w_reg_sum, w_mux_alu, w_alu;

    assign o_sumout = (i_outsel)? w_reg_sum : 8'bz;

    mux_2_8bit U_MUX_A_REG_INDATA (
        .a(8'b0),
        .b(w_alu),
        .sel(i_regsrc),
        .out_data(w_mux_a)
    );

    reg_one A_REG (
        .clk(clk),
        .rst(rst),
        .load(i_aload),
        .wdata(w_mux_a),
        .rdata(w_reg_a)
    );

    comp_less_than U_CMP_LT(
        .a(w_reg_a),
        .b(8'd11),
        .lt(o_al11)
    );

    mux_2_8bit U_MUX_SUM_REG_INDATA (
        .a(8'b0),
        .b(w_alu),
        .sel(i_regsrc),
        .out_data(w_mux_sum)
    );

    reg_one SUM_REG (
        .clk(clk),
        .rst(rst),
        .load(i_sumload),
        .wdata(w_mux_sum),
        .rdata(w_reg_sum)
    );

    mux_2_8bit U_MUX_ALU_B_INDATA (
        .a(w_reg_sum),
        .b(8'h1),
        .sel(i_alusrc),
        .out_data(w_mux_alu)
    );

    alu U_ALU (
        .a(w_reg_a),
        .b(w_mux_alu),
        .out_data(w_alu)
    );

endmodule

module reg_one(
    input clk,
    input rst,
    input load,
    input [7:0] wdata,
    output [7:0] rdata
);

    logic [7:0] reg_data;

    assign rdata = reg_data;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            reg_data <= 0;
        end
        else begin
            if (load) reg_data <= wdata;
        end
    end

endmodule

module alu(
    input [7:0] a,
    input [7:0] b,
    output [7:0] out_data
);

    assign out_data = a + b;

endmodule

module mux_2_8bit(
    input [7:0] a,
    input [7:0] b,
    input sel,
    output [7:0] out_data
);

    assign out_data = (sel)? b : a;

endmodule

module comp_less_than(
    input [7:0] a,
    input [7:0] b,
    output lt
);

    assign lt = (a < b)? 1'b1 : 1'b0;

endmodule
