`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.11.2026 15:42:25
// Design Name: 
// Module Name: log2_pla_unpipelined_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Option C: Un-pipelined PLA 8-Segment Architecture
// Purely combinational piecewise linear approximation using Shift-and-Add (0 DSPs)
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module log2_pla_unpipelined_top (
    input  logic [15:0] x_in,
    output logic [15:0] log2_out, // Q4.12 fixed-point format
    output logic        invalid_op
);
    logic [3:0]  k_val;
    logic [11:0] m_val;
    logic [11:0] frac_result;

    // 1. Leading One Detector (LOD)
    lod_16bit lod_inst (
        .in_x(x_in),
        .k_out(k_val),
        .zero_flag(invalid_op)
    );

    // 2. Normalization Barrel Shifter
    barrel_shifter shifter_inst (
        .in_x(x_in),
        .k_in(k_val),
        .m_frac(m_val)
    );

    // 3. PLA 8-Segment Unit (Shared module containing updated PLA logic & Saturation)
    pla_8seg_unit pla_inst (
        .m_frac(m_val),
        .log2_frac(frac_result)
    );

    // 4. Output Result Assembly (Q4.12 format)
    assign log2_out = invalid_op ? 16'h0000 : {k_val, frac_result};

endmodule