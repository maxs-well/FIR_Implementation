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
// @function: FIR最基础的运算结构，实现乘加
// @data: 2020年3月19日14:02:33
module fir_base
#(
	parameter DATA_BITS = 16,
	parameter COEF_BITS = 16,
	parameter EXTEND_BITS = 5,
	parameter OUT_BITS = DATA_BITS + COEF_BITS + EXTEND_BITS
)
(
	// System signal
	input							clk			,
	input							rst			,
	// Control and data input signal
	input							en			,
	input	signed [DATA_BITS-1:0]	data_in_A	,
	input	signed [DATA_BITS-1:0]	data_in_B	,
	input	signed [COEF_BITS-1:0]	coef		,
	// Output signal 
	output	reg						fir_busy	,	//no use
	output	signed 	[OUT_BITS-1:0]	data_out	,
	output	reg						output_vld	
);
// 乘法器结果位宽扩展为两个信号位宽之和
// https://zhuanlan.zhihu.com/p/92828553
reg signed [DATA_BITS + COEF_BITS - 1:0]	data_mult;
// 因为FIR系数是中心对称的，所以直接把中心对称的数据相加乘以系数
// 相加符号位扩展一位
wire signed [DATA_BITS:0]	data_in ;
assign data_in = {data_in_A[DATA_BITS-1], data_in_A} + {data_in_B[DATA_BITS-1], data_in_B};

// 为了防止后续操作导致符号位溢出，这里扩展符号位
assign data_out = {{EXTEND_BITS{data_mult[DATA_BITS + COEF_BITS - 1]}},data_mult };

// en拉高，输出相乘结果
always @(posedge clk or posedge rst) begin
	if (rst) begin
		// reset
		fir_busy	<=	1'b0;
		data_mult	<= 	0 ;
		output_vld	<=	1'b0;
	end
	else if (en) begin
		//如果coef为0，不需要计算直接得0
		data_mult	<=	coef != 0 ? data_in * coef : 0;
		output_vld	<=	1'b1;
	end
	else begin
		data_mult	<=	'd0;
		output_vld	<=	1'b0;
	end
end


endmodule