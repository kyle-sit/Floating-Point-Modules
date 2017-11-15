/* File containing module code for a floating point adder
*/

//adder module
module adder_fp(
	input logic clk, start, op,
	input logic [31:0] A, B,
	output logic ready, busy,
	output logic [31:0] Y	
);

	logic [3:0] state = 4'd0; // 3 states = 2 bits
	parameter idle = 4'd0, active = 4'd1, checkNaN = 4'd2, checkInfinity = 4'd3, oneInfinity = 4'd4, 
		exponentCheck = 4'd5, operation = 4'd6, addition = 4'd7, subtraction = 4'd8, leadingZero = 4'd9, 
		chooseSign = 4'd10, Asign = 4'd11, notAsign = 4'd12, finished = 4'd13;
	logic A_sign, B_sign;
	logic [23:0] A_mantissa, B_mantissa, final_mantissa;
	logic [7:0] A_exponent, B_exponent, final_exponent;
	logic [24:0] output_mantissa;
	
	always_ff @(posedge clk) begin
		case(state)
			idle: begin
				if (start) begin
					state <= active;
					ready <= 0;
					
				end
				else begin
					ready <= 0;
					busy <= 0;
					//Y <= 0;
					state <= state;
				end
			end
			active: begin
				busy <= 1;
				A_sign <= A[31];
				A_exponent <= A[30:23];
				A_mantissa <= {1'b1, A[22:0]};
				B_sign <= B[31];
				B_exponent <= B[30:23];
				B_mantissa <= {1'b1, B[22:0]};
				state <= checkNaN;
			end

				// infinity = 8'b11111111 for exponent, 0 for mantissa
				// NaN = 8'b11111111 for exponent, xxxx... for mantissa
				//case if either input is NaN
			
			checkNaN: begin
				if(((A_exponent == 8'b11111111) && (A_mantissa[22:0] > 0)) || ((B_exponent == 8'b11111111) && (B_mantissa[22:0] > 0))) begin
					Y <= {1'b0,8'b11111111,22'b0,1'b1};
					state <= finished;
				end
				else begin
					state <= checkInfinity;
				end
			end
			
			checkInfinity: begin
				//case if both inputs are infinity
				if ((A_exponent == 8'b11111111 && A_mantissa[22:0] == 0) && (B_exponent == 8'b11111111 && B_mantissa[22:0] == 0)) begin
					if (A_sign == B_sign) begin
						Y <= A;
						state <= finished;
					end
					else begin
						Y <= {1'b0,8'b11111111,22'b0,1'b1};
						state <= finished;
					end
				end
				else begin
					state <= oneInfinity;
				end
			end
			
			oneInfinity: begin
				//case if A input is infinity
				if (A_exponent == 8'b11111111 && A_mantissa[22:0] == 0) begin
					Y <= A;
					state <= finished;
				end
				//case if B input is infinity
				else if (B_exponent == 8'b11111111 && B_mantissa[22:0] == 0) begin
					Y <= B;
					state <= finished;
				end
				else begin
					state <= exponentCheck;
				end
			end
			
			exponentCheck: begin
				// figure out which number is bigger
				if (A_exponent < B_exponent) begin
					A_mantissa <= A_mantissa >> (B_exponent - A_exponent);
					final_exponent <= B_exponent;
				end
				else begin 
					B_mantissa <= B_mantissa >> (A_exponent - B_exponent);
					final_exponent <= A_exponent;
				end
				state <= operation;
			end
			
			// 6
			operation: begin
					// adding same sign or subtracting different signs = addition logic
					if ((!op && !A_sign && !B_sign) || (!op && A_sign && B_sign) || (op && !A_sign && B_sign) || (op && A_sign && !B_sign)) begin
						output_mantissa <= A_mantissa + B_mantissa;
						state <= addition;
					end
					else begin
						state <= subtraction;
					end
			end
			
			// 7
			addition: begin
				// if there's overflow
				if (output_mantissa[24] == 1) begin
					final_exponent <= final_exponent + 1;
					if (output_mantissa[0] == 1) begin
						final_mantissa <= output_mantissa[24:1] + 1;
					end
					else begin
						final_mantissa <= output_mantissa[24:1];
					end
								
					if (final_exponent == 255) begin
						final_mantissa <= 0;
					end
								
				end
				// no overflow
				else begin
					final_mantissa <= output_mantissa[23:0];
				end
	
				state <= Asign;
			end
			
			// 8
			subtraction: begin
				// adding different sign or subtracting same signs
				if (A_mantissa < B_mantissa) begin 
					output_mantissa <= B_mantissa - A_mantissa;
					state <= leadingZero;
				end
				else if (B_mantissa < A_mantissa) begin
					output_mantissa <= A_mantissa - B_mantissa;
					state <= leadingZero;
				end
				else begin
						Y <= 0;
						state <= finished;
				end

			end
			
			// 9
			leadingZero: begin
				if (output_mantissa[23] != 0) begin
					state <= chooseSign;
				end
				else begin
					output_mantissa <= output_mantissa << 1;
					final_exponent <= final_exponent - 1;
					state <= leadingZero;
				end
			end
			
			// 10
			chooseSign: begin
				if (A_mantissa < B_mantissa) begin
					state <= notAsign;
				end
				else begin
					state <= Asign;
				end
				final_mantissa <= output_mantissa[23:0];
			end
			
			// 11
			Asign: begin
				Y <= {A_sign, final_exponent, final_mantissa[22:0]};
				state <= finished;
			end
			
			// 11
			notAsign: begin
				Y <= {!A_sign, final_exponent, final_mantissa[22:0]};
				state <= finished;
			end
			
			// 13
			finished: begin
				ready <= 1;
				//Y <= 0;
				state <= idle; 
			end
			/*default: begin
				ready <= 0;
				busy <= 0;
				Y <= 0;			
			end*/
		endcase
	end

endmodule