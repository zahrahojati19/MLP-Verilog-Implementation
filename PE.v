module PE #(parameter N) (clk, rst, weight, iact, outp);
	input clk, rst;
	input [N-1:0] weight, iact;
	output [(N/2)-1:0] outp;

	wire [N-1:0] sram1_data, sram2_data, out_sram1, out_sram2, iact_reg, weight_mult, adder_in, reg_out, reg_in, relu_out, quantized_out;
	wire [7:0] write_addr1, write_addr2, read_addr1, read_addr2;
	wire full_write1, full_write2, full_read1, full_read2, wr_en1, wr_en2, rd_en1, rd_en2, demux_sel, mux_sel;

	Demux #(N) demux_inst(.weight(weight), .sel(demux_sel), .out0(sram1_data), .out1(sram2_data));
	SRAM #(N) sram1(.clk(clk), .rst(rst), .write_data(sram1_data), .write_addr(write_addr1), .read_addr(read_addr1), .wr_en(wr_en1), .rd_en(rd_en1), .full_write(full_write1), .full_read(full_read1), .read_data(out_sram1));
	SRAM #(N) sram2(.clk(clk), .rst(rst), .write_data(sram2_data), .write_addr(write_addr2), .read_addr(read_addr2), .wr_en(wr_en2), .rd_en(rd_en2), .full_write(full_write2), .full_read(full_read2), .read_data(out_sram2));
	assign weight_mult = mux_sel ? out_sram2 : out_sram1;
	
	Register #(N) register_mult(.clk(clk), .rst(rst), .inp(iact), .out(iact_reg));
	Multiplier #(N) mult(.clk(clk), .rst(rst), .inp(iact_reg), .weight(weight_mult), .out(adder_in));
	Adder #(N) add(.inp(adder_in), .reg1(reg_out), .out(reg_in));
	Register #(N) register_add(.clk(clk), .rst(rst), .inp(reg_in), .out(reg_out));

	ReLu #(N) relu_inst(.clk(clk), .rst(rst), .inp(reg_in), .out(relu_out));
	Quantizer #(N) quant_inst(.fixed_in(relu_out), .quantized_out(outp));
	
	Controller cntrl (.clk(clk), .rst(rst), .full_write1(full_write1), .full_read1(full_read1), .full_write2(full_write2), .full_read2(full_read2), .wr_en1(wr_en1), .rd_en1(rd_en1), .wr_en2(wr_en2), .rd_en2(rd_en2), .demux_sel(demux_sel), .mux_sel(mux_sel), .write_addr1(write_addr1), .read_addr1(read_addr1), .write_addr2(write_addr2), .read_addr2(read_addr2));
endmodule
