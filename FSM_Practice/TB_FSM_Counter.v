// Counter의 테스트벤치

module tb_cnt5;
	reg clk, rb, inc;
	wire [2:0] c_b;
	wire [4:0] c_o;
	
	cnt5_b counterBin(c_b, clk, rb, inc);
	cnt5_o counterOneHot(c_o, clk, rb, inc);

	always begin
		clk = 1; #5; clk = 0; #5;
	end

	initial begin
		$dumpfile("FSMvcd.vcd");
		$dumpvars(-1, counterBin);
		$dumpvars(-1, counterOneHot);
		inc = 1; rb = 0; #15; rb = 1; #60;
		inc = 0; #70;
		$finish;
	end
endmodule 
