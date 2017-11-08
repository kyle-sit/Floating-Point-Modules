/* File containing module code for a floating point adder
*/

//adder module
module adder_fp(
	input logic clk, start, op,
	input logic [31:0] A, B,
	output logic ready, busy,
	output logic [31:0] Y
	
);

	logic [1:0] state; // 3 states = 2 bits
	parameter idle = 2'd0, active = 2'd1, finished = 2'd2;
	logic A_sign, B_sign;
	logic [22:0] A_mantissa, B_mantissa;
	logic [7:0] A_exponent, B_exponent;
	logic [24:0] output_mantissa;
	
	always_ff@(posedge clk) begin
		case(state)
			idle: begin
				if (start) begin
					state <= active;
				end
				else begin
					ready <= 0;
					busy <=0;
					state <= state;
				end
			end
			active: begin
				busy <= 1;
				//A <= A;
				//B <= B;
				A_sign <= A[31];
				A_exponent <= A[30:23];
				A_mantissa <= A[22:0];
				B_sign <= B[31];
				B_exponent <= B[30:23];
				B_mantissa <= B[22:0];

				// infinity = 8'b11111111 for exponent, 0 for mantissa
				// NaN = 8'b11111111 for exponent, xxxx... for mantissa
				if((A_exponent == 8'b11111111 and A_mantissa > 0) or (B_exponent == 8'b11111111 and B_mantissa > 0)) begin
					Y <= {0,8'b11111111,22'b0,1};
				end
				else if ((A_exponent == 8'b11111111 and A_mantissa == 0) and (B_exponent == 8'b11111111 and B_mantissa == 0)) begin
					if (A_sign == B_sign) begin
						Y <= A;
					end
					else begin
						Y <= {0,8'b11111111,22'b0,1};
					end
				end
				else if (A_exponent == 8'b11111111 and A_mantissa == 0) begin
					Y <= A;
				end
				else if (B_exponent == 8'b11111111 and B_mantissa == 0) begin
					Y <= B;
				end
				
				// now we use the adding algorithm
				
				else if (A_exponent < B_exponent) begin
					A_mantissa >> (B_exponent - A_exponent);
				end
				else if (B_exponent < A_exponent) begin
				end
				
				else begin
				end
				
				state = finished;
			end
			finished: begin
				ready <= 1;
				Y <= 0;
				state <= idle; 
			end
	end

endmodule
