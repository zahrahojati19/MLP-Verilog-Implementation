module Controller (clk, rst, full_write1, full_read1, full_write2, full_read2, wr_en1, rd_en1, wr_en2, rd_en2, demux_sel, mux_sel, write_addr1, read_addr1, write_addr2, read_addr2);
	input clk, rst, full_write1, full_read1, full_write2, full_read2;
	output reg wr_en1, rd_en1, wr_en2, rd_en2, demux_sel, mux_sel;
	output reg [6:0] write_addr1, read_addr1, write_addr2, read_addr2;

	reg cnt_write1, cnt_read1, cnt_write2, cnt_read2;
	wire co_write1, co_read1, co_write2, co_read2;

	reg [1:0] ps, ns;
	parameter [1:0] first_read = 2'b00, s1r_s2w = 2'b01, s1w_s2r = 2'b10;

	always @(ps, full_write1, full_read1, full_write2, full_read2) begin
		{wr_en1, rd_en1, wr_en2, rd_en2, demux_sel, mux_sel, cnt_write1, cnt_read1, cnt_write2, cnt_read2} <= 0;
		case(ps)
			first_read: begin wr_en1 <= 1'b1; demux_sel <= 1'b0; cnt_write1 <= 1'b1; ns <= full_write1 ? s1r_s2w : first_read; end
			s1r_s2w: begin wr_en2 <= 1'b1; rd_en1 <= 1'b1; demux_sel <= 1'b1; mux_sel <= 1'b0; cnt_read1 <= 1'b1; cnt_write2 <= 1'b1; ns <= (full_write2&&full_read1) ? s1w_s2r : s1r_s2w; end
			s1w_s2r: begin wr_en1 <= 1'b1; rd_en2 <= 1'b1; demux_sel <= 1'b0; mux_sel <= 1'b1; cnt_read2 <= 1'b1; cnt_write1 <= 1'b1; ns <= (full_write1&&full_read2) ? first_read : s1w_s2r; end
		endcase
	end
	always @(posedge clk, posedge rst) begin
		if(rst) ps <= first_read;
		else ps <= ns;
	end

	// Counters
	always @(posedge clk, posedge rst) begin
		if(rst) write_addr1 <= 0;
		else if (cnt_write1) write_addr1 <= write_addr1 + 1'b1;
	end
	assign co_write1 = &write_addr1;
	
	always @(posedge clk, posedge rst) begin
		if(rst) write_addr2 <= 0;
		else if (cnt_write2) write_addr2 <= write_addr2 + 1'b1;
	end
	assign co_write2 = &write_addr2;

	always @(posedge clk, posedge rst) begin
		if(rst) read_addr1 <= 0;
		else if (cnt_read1) read_addr1 <= read_addr1 + 1'b1;
	end
	assign co_read1 = &read_addr1;

	always @(posedge clk, posedge rst) begin
		if(rst) read_addr2 <= 0;
		else if (cnt_read2) read_addr2 <= read_addr2 + 1'b1;
	end
	assign co_read2 = &read_addr2;
endmodule
