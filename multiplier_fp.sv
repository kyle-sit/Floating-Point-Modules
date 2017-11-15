/* File containing module code for a floating point multiplier
*/

//multiplier module
module multiplier_fp(
	input logic clk, start,
	input logic [31:0] A, B,
	output logic ready, busy,
	output logic [31:0] Y
);

	logic [3:0] state = 4'd0; // 3 states = 2 bits
	parameter idle = 4'd0, active = 4'd1, checkNaN = 4'd2, checkInfinity = 4'd3, oneInfinity = 4'd4, 
		exponentSum = 4'd5, normalize = 4'd6, shift = 4'd7, round = 4'd8, noRound = 4'd9, stillnormalized = 4'd10, 
		normalizeAgain = 4'd11, chooseSign = 4'd12, finished = 4'd13;
	logic A_sign, B_sign;
	logic [23:0] A_mantissa, B_mantissa;
	logic [24:0] final_mantissa;
	logic [7:0] A_exponent, B_exponent;
	logic signed [9:0] final_exponent;
	logic [47:0] output_mantissa;
	integer i = 47;
	integer x = 0;
	
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
					i <= 0;
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
				i <= 0;
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
					final_exponent <= (A_exponent + B_exponent) - 127;
					state <= exponentSum;
				end
			end
			
			exponentSum: begin
				//final_exponent <= (A_exponent + B_exponent) - 127;
				if((final_exponent > 254) || (final_exponent < 1)) begin
					Y <= {1'b0,8'b11111111,22'b0,1'b1};
					state <= finished;
				end
				else begin
					output_mantissa <= A_mantissa * B_mantissa;
					state <= normalize;
				end
			end
			
			// 6
			normalize: begin
				if (output_mantissa[47] == 1) begin
					i <= 1; // i represents if we need to round or not
					state <= shift;
				end
				else begin
					state <= shift;
				end
			end
			
			// 7
			shift: begin
				if (i == 1) begin
					final_exponent <= final_exponent + 1;
					output_mantissa <= output_mantissa >> 23;
					state <= round;
				end
				else begin
					output_mantissa <= output_mantissa >> 23;
					state <= noRound;
				end
			end
			
			// 8
			round: begin
				if(final_exponent[8] == 1) begin
					Y <= {1'b0,8'b11111111,22'b0,1'b1};
					state <= finished;
				end
				else begin
					if (output_mantissa[0] == 1) begin
						final_mantissa <= output_mantissa[24:1] + 1;
					end
					else begin
						final_mantissa <= output_mantissa[24:1];
					end
				end
				state <= stillnormalized;
			end
			
			//9
			noRound: begin
				final_mantissa <= output_mantissa[23:0];
				state <= chooseSign;
			end
			
			// 10
			stillnormalized: begin
				if(final_exponent[8] == 1) begin
					Y <= {1'b0,8'b11111111,22'b0,1'b1};
					state <= finished;
				end
				else if(final_mantissa[24] == 1) begin
					state <= normalizeAgain;
				end
				else begin
					state <= chooseSign;
				end
			end
			
			// 11
			normalizeAgain: begin
				if (final_mantissa[0] == 0) begin
					final_mantissa <= final_mantissa >> 1;
					final_exponent <= final_exponent + 1;
					state <= chooseSign;
				end
				else begin
					final_mantissa <= final_mantissa[24:1] + 1;
					final_exponent <= final_exponent + 1;
					state <= stillnormalized;
				end
			end
			
			// 12
			chooseSign: begin
				if( A_sign == B_sign ) begin
					Y <= {1'b0, final_exponent[7:0], final_mantissa[22:0]};
				end
				else begin
					Y <= {1'b1, final_exponent[7:0], final_mantissa[22:0]};
				end
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