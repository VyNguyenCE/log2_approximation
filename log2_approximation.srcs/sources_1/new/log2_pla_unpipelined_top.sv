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
    logic [2:0]  seg_idx;
    logic [11:0] b_coeff;
    logic [11:0] approx_m;
    logic [11:0] frac_result;

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

    assign seg_idx = m_val[11:9];

    // PLA 8-Segment Shift-and-Add Logic
    always_comb begin
        case (seg_idx)
            3'b000: begin b_coeff = 12'd0;   approx_m = m_val - (m_val >> 3); end
            3'b001: begin b_coeff = 12'd62;  approx_m = m_val - (m_val >> 2); end
            3'b010: begin b_coeff = 12'd156; approx_m = (m_val >> 1) + (m_val >> 3); end
            3'b011: begin b_coeff = 12'd280; approx_m = (m_val >> 1) + (m_val >> 4); end
            3'b100: begin b_coeff = 12'd421; approx_m = (m_val >> 1); end
            3'b101: begin b_coeff = 12'd574; approx_m = (m_val >> 1) - (m_val >> 5); end
            3'b110: begin b_coeff = 12'd738; approx_m = (m_val >> 2) + (m_val >> 3); end
            3'b111: begin b_coeff = 12'd910; approx_m = (m_val >> 2) + (m_val >> 4); end
            default: begin b_coeff = 12'd0;  approx_m = m_val; end
        endcase
    end

    assign frac_result = approx_m + b_coeff;
    assign log2_out    = invalid_op ? 16'h0000 : {k_val, frac_result};
endmodule