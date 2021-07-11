// FSM 관련 연습 진행
// FSM을 verilog로 작성할때 어떻게 하는지 알아봅시다.

// 일단은 Binary Encoding 방식을 사용하여 작성

// Verilog 로 작성하는 5-way counter
// inc가 high이면 앞으로 진행, inc가 low이면 뒤로 진행

// 코드 시작

// Coding Module Header

module cnt5_b(cnt, clk, rb, inc);
	input clk, rb, inc;
	output [2:0] cnt;

	parameter zero = 3'b000; // parameter: 베릴로그에서 상수를 정의할 때 사용
	parameter one = 3'b001;
	parameter two = 3'b010;
	parameter three = 3'b011;
	parameter four = 3'b100;

	// Sequential Circuits 부분
	reg [2:0] cnt;
	reg [2:0] next_cnt;

	always @ (posedge clk or negedge rb) begin
		if (rb == 1'b0) cnt <= zero;
		else cnt <= next_cnt;
	end

	// Combinational Circuit 부분
	always @ (inc or cnt) begin
		case ({cnt, inc}) // {}를 이용하여 결합형식으로 사용할 수 있음
			{zero, 1'b0}: next_cnt <= four;
			{one, 1'b0}: next_cnt <= zero;
			{two, 1'b0}: next_cnt <= one;
			{three, 1'b0}: next_cnt <= two;
			{four, 1'b0}: next_cnt <= three;
			
			{zero, 1'b1}: next_cnt <= one;
			{one, 1'b1}: next_cnt <= two;
			{two, 1'b1}: next_cnt <= three;
			{three, 1'b1}: next_cnt <= four;
			{four, 1'b1}: next_cnt <= zero;

			default: next_cnt <= 3'bx;
		endcase
	end
endmodule
