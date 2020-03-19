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
// @function: FIR 顶层实现
// @see 
// @data: 2020年3月19日14:02:33
module fir_inst
#(
	parameter DATA_BITS = 16,	//数据位宽
	parameter COEF_BITS = 16,	//FIR系数位宽
	parameter EXTEND_BITS = 5,	//扩展符号位宽
	parameter FIR_ORDER = 72,	//FIR阶数，这里只能设置为偶数
	parameter OUT_BITS = DATA_BITS + COEF_BITS + EXTEND_BITS	//输出位宽
)
(
	// System Sigal
	input							clk				,
	input							rst				,

	// input signal 
	input							data_in_vld		,
	input	signed	[DATA_BITS-1:0]	data_in 		,
	// output signal
	output	reg signed[OUT_BITS-1:0]data_out		,
	output	 						data_out_vld	
);

`include "fir_coef.v"

// FIR阶数的一半
// 因为FIR系数是中心对称的，所以直接把中心对称的数据相加乘以系数
localparam FIR_HALF_ORDER = FIR_ORDER / 2;  //36

// 流水线第一级相加，计算公式ceil(N/4)
localparam FIR_ADD_ORDER_ONE = (FIR_HALF_ORDER + 3) / 4; //
// 流水线第二级相加，计算公式ceil(N/4)
localparam FIR_ADD_ORDER_TWO = (FIR_ADD_ORDER_ONE + 3) / 4; //3
// localparam FIR_ADD_ORDER_FINAL = (FIR_ADD_ORDER_TWO + 3)/ 4;

// FIR输入数据暂存寄存器组
reg signed 	[DATA_BITS-1:0]	data_tmp [FIR_ORDER:0] ;
// FIR每个数据与参数相乘后输出数据组
wire signed [OUT_BITS-1:0]	data_out_tmp [FIR_HALF_ORDER:0] ;
// FIR输出数据后流水线相加的中间变量，多出部分变量，防止下一级相加过程中index越界
reg signed 	[OUT_BITS-1:0]	dat_out_reg  [FIR_HALF_ORDER+4:0] ; 	//40-0
reg signed [OUT_BITS-1:0]	dat_out_A [FIR_ADD_ORDER_ONE+3:0] ;	//12-0
reg signed [OUT_BITS-1:0]	dat_out_B [FIR_ADD_ORDER_TWO+3:0] ;	//6-0
// 保存每个FIR_BASE的output_vld
wire		[FIR_HALF_ORDER:0]	output_vld_tmp;

// 这些多余的reg直接设为0就可以了
always @ (posedge clk) begin
	dat_out_reg[FIR_HALF_ORDER+1] = 0;
	dat_out_reg[FIR_HALF_ORDER+2] = 0;
	dat_out_reg[FIR_HALF_ORDER+3] = 0;
	dat_out_reg[FIR_HALF_ORDER+4] = 0;

	dat_out_A[FIR_ADD_ORDER_ONE] = 0;
	dat_out_A[FIR_ADD_ORDER_ONE+1] = 0;
	dat_out_A[FIR_ADD_ORDER_ONE+2] = 0;
	dat_out_A[FIR_ADD_ORDER_ONE+3] = 0;

	dat_out_B[FIR_ADD_ORDER_TWO] = 0;
	dat_out_B[FIR_ADD_ORDER_TWO + 1] = 0;
	dat_out_B[FIR_ADD_ORDER_TWO + 2] = 0;
	dat_out_B[FIR_ADD_ORDER_TWO + 3] = 0;
end

//最后一级流水线
always @(posedge clk or posedge rst) begin
	if (rst) begin
		// reset
		data_out 	<=	0;
	end
	else if (data_out_vld) begin
		data_out 	<= dat_out_B[0] + dat_out_B[1] + dat_out_B[2] + dat_out_B[3];
	end
end

// 判定所有FIR_BASE模块完成转换
assign data_out_vld = (&output_vld_tmp[FIR_HALF_ORDER:1] == 1'b1) ? 1'b1 : 1'b0;

// FIR输入数据暂存寄存器组，0 号比较特殊，每次存data_in
// FIR_HALF_ORDER 号特殊
always @(posedge clk or posedge rst) begin
	if (rst) begin
		// reset
		data_tmp[0] <=	0;
		data_tmp[FIR_HALF_ORDER] <= 0;
		data_tmp[FIR_ORDER] <= 0;
	end
	else if (data_in_vld) begin
		data_tmp[0] <=	data_in;
		data_tmp[FIR_HALF_ORDER] <= data_tmp[FIR_HALF_ORDER-1];
		data_tmp[FIR_ORDER]	<=	data_tmp[FIR_ORDER-1];
	end
end

always @(posedge clk or posedge rst) begin
	if (rst) begin
		// reset
		dat_out_reg[FIR_HALF_ORDER] <= 0;
	end
	else if (output_vld_tmp[FIR_HALF_ORDER]) begin
		dat_out_reg[FIR_HALF_ORDER] <= data_out_tmp[FIR_HALF_ORDER];
	end
end

fir_base 
#(
	.DATA_BITS(DATA_BITS),
	.COEF_BITS(COEF_BITS),
	.EXTEND_BITS(EXTEND_BITS)
	)
fir_inst_FIR_HALF_ORDER(
	.clk		(clk),
	.rst		(rst),
	
	.en			(data_in_vld),
	.data_in_A	(data_tmp[FIR_HALF_ORDER]),
	.data_in_B	(12'd0),
	.coef		(get_coef(FIR_HALF_ORDER)),
	
	.fir_busy	(),
	.data_out	(data_out_tmp[FIR_HALF_ORDER]),
	.output_vld	(output_vld_tmp[FIR_HALF_ORDER])
);

generate
	genvar j;
	for (j = 1; j < FIR_HALF_ORDER; j = j + 1)
	begin: fir_base

	//这里无法兼顾0，FIR_HALF_ORDER
	always @(posedge clk or posedge rst) begin
	if (rst) begin
		// reset
		data_tmp[j] <=	0;
		data_tmp[FIR_HALF_ORDER + j] <= 0;
	end
	else if (data_in_vld) begin
		data_tmp[j] <=	data_tmp[j-1];
		data_tmp[FIR_HALF_ORDER + j] <= data_tmp[FIR_HALF_ORDER+j-1];
	end
	end

	fir_base
	#(
	.DATA_BITS(DATA_BITS),
	.COEF_BITS(COEF_BITS),
	.EXTEND_BITS(EXTEND_BITS)
	)
	fir_inst_NORMAL
	(
		.clk		(clk),
		.rst		(rst),
		
		.en			(data_in_vld),
		.data_in_A	(data_tmp[j]),
		.data_in_B	(data_tmp[FIR_ORDER-j]),
		.coef		(get_coef(j)),
		
		.fir_busy	(),
		.data_out	(data_out_tmp[j]),
		.output_vld	(output_vld_tmp[j])
	);

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			// reset
			dat_out_reg[j] <= 0;
		end
		else if (output_vld_tmp[j]) begin
			dat_out_reg[j] <= data_out_tmp[j];
		end
	end

	if (j <= FIR_ADD_ORDER_ONE)
	begin
	//流水线相加 第一级
	//注意j 的范围是[1,FIR_HALF_ORDER]
	//所以dat_out_A[j-1]
		always @(posedge clk or posedge rst) begin
			if (rst) begin
				// reset
				dat_out_A[j-1] <= 0;
			end
			else begin
				dat_out_A[j-1] <= dat_out_reg[4*j-3] + dat_out_reg[4*j-2] + dat_out_reg[4*j-1] + dat_out_reg[4*j];
			end
		end
	end

	if (j <= FIR_ADD_ORDER_TWO)
	begin
	// 流水线相加 第二级
		always @(posedge clk or posedge rst) begin
			if (rst) begin
				// reset
				dat_out_B[j-1] <= 0;
			end
			else begin
				dat_out_B[j-1] <= dat_out_A[4*j - 4] + dat_out_A[4*j- 3] + dat_out_A[4*j - 2] + dat_out_A[4*j - 1];
			end
		end
	end
end	
endgenerate

endmodule 