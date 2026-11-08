`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.11.2026 15:42:25
// Design Name: 
// Module Name: log2_mitchell_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Option A: Mitchell Original Architecture (Baseline)
// Direct concatenation of exponent k and fraction m (log2(1+m) ≈ m)
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module log2_mitchell_top (
    input  logic [15:0] x_in,
    output logic [15:0] log2_out, // Q4.12 fixed-point format
    output logic        invalid_op
);
    logic [3:0]  k_val;
    logic [11:0] m_val;

    lod_16bit lod_inst (
        .in_x(x_in),
        .k_out(k_val),
        .zero_flag(invalid_op)
    );

    barrel_shifter shifter_inst (
        .in_x(x_in),
        .k_in(k_val),
        .m_frac(m_val)
    );

    assign log2_out = invalid_op ? 16'h0000 : {k_val, m_val};
endmodule