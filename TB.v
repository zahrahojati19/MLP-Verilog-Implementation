module TB();
	reg clk = 1, rst =1;
	reg [15:0] iact = 12, weight = 128;
	wire [7:0] outp;
	wire done;

	PE #(16, 1) pe_inst (clk, rst, weight, iact, outp, done);
	
	always #5 clk = ~clk;
	initial begin
		#11 rst = 0;
		repeat (256) begin
			weight = $random; #10;	
		end
		repeat (256) begin
			weight = $random; #10;	
		end
		#4200;
		$stop;
	end
endmodule
