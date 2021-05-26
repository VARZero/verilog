module nand4_if(a,y);
   input [3:0] a;
   output reg y;

   always @(a)
   begin
      if(a == 4'b1111)
      begin
         y=1'b0;
      end
      else
      begin
         y=1'b1;
      end
   end
endmodule