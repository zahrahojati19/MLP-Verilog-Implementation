module Multiplier #(parameter N) (clk, rst, inp, weight, out);
	input clk, rst;
	input [N-1:0] inp, weight;
	output reg [N-1:0] out;
	
	always @(posedge clk, posedge rst) begin
		if(rst) out <= 0;
		else out <= inp * weight;
	end
endmodule

module Adder #(parameter N) (inp, reg1, out);
	input [N-1:0] inp, reg1;
	output [N-1:0] out;
	
	assign out = inp + reg1;
endmodule

module ReLu #(parameter N)(clk, rst, inp, out); //clk, rst
	input clk, rst;
	input [N-1:0] inp;
	output reg[N-1:0] out;	

	//assign out = (inp > 0) ? inp : 16'b0;
	always @(posedge clk, posedge rst) begin
		if(rst) out <= 0;
		else if (inp > 0) out <= inp;
		else out <= 0;
	end
endmodule

module Quantizer #(parameter N) (fixed_in, quantized_out);
	input [N-1:0] fixed_in;
    	output [(N/2)-1:0] quantized_out;

	wire [1:0] int_part;
	wire [N-3:0] frac_part;

	wire reduced_int_part;
	wire [(N-2)/2-1:0] reduced_frac_part;

	assign int_part = fixed_in[N-1:N-2];
	assign reduced_int_part = int_part[1]; 
	assign frac_part = fixed_in[N-3:0];
	assign reduced_frac_part = frac_part[N-3:(N-2)/2-1];

    	assign quantized_out = {reduced_int_part, reduced_frac_part};

endmodule

module Register #(parameter N)(clk, rst, inp, out);
	input clk, rst;
	input [N-1:0] inp;
	output reg [N-1:0] out;
	
	always @(posedge clk, posedge rst) begin
		if (rst) out <= 0;
		else out <= inp;
	end
endmodule

module Demux #(parameter N)(weight, sel, out0, out1);
	input [N-1:0] weight;
	input sel;
	output reg [N-1:0] out0, out1;

	always @(weight, sel) begin
		{out0 , out1} <= 0;
		case(sel)
			1'b0: out0 <= weight;
			1'b1: out1 <= weight;
		endcase
	end
endmodule

module SRAM #(parameter N) (clk, rst, write_data, write_addr, read_addr, wr_en, rd_en, full_write, full_read, read_data);
	input clk, rst;
	input [N-1:0] write_data;
	input [7:0] write_addr, read_addr;
	input wr_en, rd_en;
	output reg full_write, full_read;
	output reg [N-1:0] read_data;

	reg [N-1:0] sram [0:255];

	integer i;

	//read
	always @(posedge clk, posedge rst) begin
		if(rst) begin 
			 full_read <= 1'b0; read_data <= 0;
		end
		else if (rd_en) begin 
			read_data <= sram[read_addr];
			if(read_addr == 8'd255) full_read = 1'b1;
			else full_read <= 1'b0;
		end
		else read_data <= read_data;
	end

	//write
	always @(posedge clk, posedge rst) begin
		if (rst) begin 
			full_write <= 1'b0;
			for(i = 0; i < 256; i=i+1'b1)
				sram[i] = 0;
		end
		else if (wr_en) begin 
			sram[write_addr] <= write_data;
			if (write_addr == 8'd255) full_write = 1'b1;
			else full_write <= 1'b0;
		end
	end
endmodule

module SRAM_Controller (
    input  wire         clk,         
    input  wire         rst,          
    input  wire [15:0]  weights_in,   
    input  wire         weights_valid,
    output wire [15:0]  weights_out,  
    output reg          sram_sel     
);

    reg [15:0] sram1 [0:255];  // ????? SRAM ????? 1
    reg [15:0] sram2 [0:255];  // ????? SRAM ????? 2

    reg [7:0] addr_write;      // ???? ????? ??????
    reg [7:0] addr_read;       // ???? ?????? ??????

    reg active_compute;        // ?????????? ????? ??????? PE

    // ?????? ?????????? ??????
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_write <= 8'd0;
            sram_sel <= 1'b0;
        end else if (weights_valid) begin
            if (!sram_sel) begin
                sram1[addr_write] <= weights_in; // ????? ?? SRAM-1
            end else begin
                sram2[addr_write] <= weights_in; // ????? ?? SRAM-2
            end
            addr_write <= addr_write + 1;
        end
    end

    // ?????? ?????? ?????? ???? PE
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_read <= 8'd0;
            active_compute <= 1'b0;
        end else begin
            if (active_compute) begin
                addr_read <= addr_read + 1;
            end
        end
    end

    // ????? ??? ????????
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            active_compute <= 1'b0;
            sram_sel <= 1'b0;
        end else if (addr_write == 8'd255) begin
            active_compute <= 1'b1;
            sram_sel <= ~sram_sel; // ????? ?????
            addr_write <= 8'd0;    // ???????? ???? ?????
            addr_read <= 8'd0;     // ???????? ???? ??????
        end else if (addr_read == 8'd255) begin
            active_compute <= 1'b0;
        end
    end

    // ????? ????? ??????
    assign weights_out = (!sram_sel) ? sram1[addr_read] : sram2[addr_read];

endmodule


/*module MAC (clk, rst, inp, weight, out);
	input clk, rst;
	input [15:0] inp, weight;
	output reg [15:0] out;
	
	always @(posedge clk, posedge rst) begin
		if(rst) out <= 16'b0;
		else out <= out + inp * weight;
	end
endmodule*/
