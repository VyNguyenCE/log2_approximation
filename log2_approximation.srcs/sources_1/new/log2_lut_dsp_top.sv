`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.11.2026 15:42:25
// Design Name: 
// Module Name: log2_lut_dsp_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Option B: LUT + DSP Linear Interpolation Architecture
// Uses 8-segment LUT for base_y/slope_s and DSP multiplier for interpolation
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module log2_lut_dsp_top (
    input  logic [15:0] x_in,
    output logic [15:0] log2_out, // Q4.12 fixed-point format
    output logic        invalid_op
);
    logic [3:0]  k_val;
    logic [11:0] m_val;
    logic [2:0]  lut_idx;
    logic [8:0]  delta_m;

    logic [11:0] base_y;
    logic [11:0] slope_s;
    logic [20:0] interp_product; // Multiplier output mapped to DSP48E1
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

    assign lut_idx = m_val[11:9]; // 3 MSBs select LUT segment index
    assign delta_m = m_val[8:0];  // 9 LSBs represent sub-segment offset

    // LUT storing base_y (y_i) and slope_s (Δy_i) in Q0.12 format
    always_comb begin
        case (lut_idx)
            3'b000: begin base_y = 12'd0;    slope_s = 12'd696; end // [0.000, 0.125)
            3'b001: begin base_y = 12'd696;  slope_s = 12'd623; end // [0.125, 0.250)
            3'b010: begin base_y = 12'd1319; slope_s = 12'd563; end // [0.250, 0.375)
            3'b011: begin base_y = 12'd1882; slope_s = 12'd514; end // [0.375, 0.500)
            3'b100: begin base_y = 12'd2396; slope_s = 12'd473; end // [0.500, 0.625)
            3'b101: begin base_y = 12'd2869; slope_s = 12'd438; end // [0.625, 0.750)
            3'b110: begin base_y = 12'd3307; slope_s = 12'd408; end // [0.750, 0.875)
            3'b111: begin base_y = 12'd3715; slope_s = 12'd381; end // [0.875, 1.000)
            default: begin base_y = 12'd0;   slope_s = 12'd0;   end
        endcase
    end

    // Multiplication inferred into DSP48E1: slope_s * delta_m
    assign interp_product = slope_s * delta_m;
    assign frac_result    = base_y + interp_product[20:9]; // Right shift 9 (divide by 512)

    assign log2_out = invalid_op ? 16'h0000 : {k_val, frac_result};
endmodule