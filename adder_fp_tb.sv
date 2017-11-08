/* File containing testbench module code for a floating point adder
*/

module adder_fp_tb;
timeunit 1ns;
timeprecision 1ps;

//inputs
logic [31:0] A, B;
logic clk, start, op;

//outputs
logic [31:0] Y;
logic ready, busy;

adder_fp afp (
 	.A(A),
	.B(B),
	.clk(clk),
	.start(start),
	.op(op),
 	.Y(Y),
	.ready(ready),
	.busy(busy)
);

always begin
	#5 clk = 1;
	#5 clk = 0;
end

initial begin

clk = 0;

A=1;#10;
$display("%d %d %d %d %d %d %d %d \n", clk, start, op, A, B, Y, ready, busy);

end

endmodule