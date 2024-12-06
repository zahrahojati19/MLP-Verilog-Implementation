module Controller #(parameter itr) (clk, rst, full_write1, full_read1, full_write2, full_read2, wr_en1, rd_en1, wr_en2, rd_en2, demux_sel, mux_sel, done, write_addr1, read_addr1, write_addr2, read_addr2);
	input clk, rst, full_write1, full_read1, full_write2, full_read2;
	output reg wr_en1, rd_en1, wr_en2, rd_en2, demux_sel, mux_sel, done;
	output reg [7:0] write_addr1, read_addr1, write_addr2, read_addr2;

	reg cnt_write1, cnt_read1, cnt_write2, cnt_read2;
	wire co_write1, co_read1, co_write2, co_read2;

	/*reg [itr - 1'b1 : 0] count_itr;
	reg cnt_itr;
	wire co_itr;*/

	reg [2:0] ps, ns;
	parameter [2:0] first_read = 3'b000, s1r_s2w = 3'b001, s1w_s2r = 3'b010, itr_counter = 3'b011, done_state = 3'b100;

	always @(ps, co_write1, co_read1, co_write2, co_read2) begin
		{wr_en1, rd_en1, wr_en2, rd_en2, demux_sel, mux_sel, cnt_write1, cnt_read1, cnt_write2, cnt_read2, done} <= 0;
		case(ps)
			first_read: begin wr_en1 <= 1'b1; demux_sel <= 1'b0; cnt_write1 <= 1'b1; ns <= co_write1 ? s1r_s2w : first_read; end
			s1r_s2w: begin wr_en2 <= 1'b1; rd_en1 <= 1'b1; demux_sel <= 1'b1; mux_sel <= 1'b0; cnt_read1 <= 1'b1; cnt_write2 <= 1'b1; ns <= (co_write2&&co_read1) ? s1w_s2r : s1r_s2w; end
			s1w_s2r: begin wr_en1 <= 1'b1; rd_en2 <= 1'b1; demux_sel <= 1'b0; mux_sel <= 1'b1; cnt_read2 <= 1'b1; cnt_write1 <= 1'b1; ns <= (co_write1&&co_read2) ? done_state : s1w_s2r; end
			//itr_counter: begin 
			done_state: begin done <= 1'b1; ns <= done_state; end ////////////////////
		endcase
	end
	always @(posedge clk, posedge rst) begin
		if(rst) ps <= first_read;
		else ps <= ns;
	end

	// Counters
	/*always @(posedge clk, posedge rst) begin
		if(rst) count_itr <= 0;
		else if (cnt_itr) count_itr <= count_itr + 1'b1;
	end
	assign co_itr = (count_itr == itr) ? 1'b1 : 1'b0;*/

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
