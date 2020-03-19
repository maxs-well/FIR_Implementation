// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// @author: woodfan
// @function: Testbench
// @data: 2020年3月19日14:02:33
module tb_fir;

reg clk;
reg rst;
reg [15:0] data_mem [1:64000];
reg	[15:0] data_in ;
wire signed [38:0] data_out;
reg		   data_in_vld;
wire 			   data_out_vld;

parameter LEN = 64000;
integer i, j;

initial begin
	clk = 1'b1;
	rst = 1'b1;
	data_in = 12'd0;
	data_in_vld = 1'b1;
	#20
	rst = 1'b0;
	#10000000
	$finish;
end

initial begin
	$fsdbDumpfile("tb.fsdb");
	$fsdbDumpvars;
	$fsdbDumpMDA();
end

always #10 clk = ~clk;

initial begin
	$readmemb("cos.txt", data_mem);
	i = 0;
	
	repeat(LEN)
	begin
		i = i +1;
		data_in = data_mem[i];
		#20;
	end
end

integer file;
initial begin
	file = $fopen("output.txt");
	if (!file)
	begin
		$display("could not open file");
		$finish;
	end
end

always @ (posedge clk)
	if (data_out_vld)
		$fdisplay(file, "%d", data_out);

fir_inst inst_fir
(
	.clk			(clk),
	.rst			(rst),

	.data_in_vld		(data_in_vld),
	.data_in 		(data_in),

	.data_out		(data_out),
	.data_out_vld	(data_out_vld)
);

endmodule
