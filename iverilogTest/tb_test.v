`timescale 1ns/1ps
module tb_nand4;
   reg [3:0] a;
   wire y;
   integer i;

   nand4_if tb(a,y);

   //------여기서 부터 아래 선까지는 waveform을 보기위한 파일을 만드는 코드이다.---- 
   initial
   begin
      $dumpfile("test_out.vcd");
      $dumpvars(-1,tb);  // tb는 위에 nand4_if tb(a,y)의 tb를 말한다. 
      $monitor("%b",y);
   end
   //------------------------------------------------------------------------------

   initial
   begin
      a=0;
      for(i=0; i<32; i = i+1)
      begin
         #20;
         a=i;
      end
      $finish;
   end
endmodule