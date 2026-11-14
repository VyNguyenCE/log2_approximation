`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.10.2026 20:23:44
// Design Name: 
// Module Name: pla_8seg_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Piecewise Linear Approximation (PLA) 8-Segment Unit
// Approximates log2(1+m) using Shift-and-Add operations (0 DSPs used)
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pla_8seg_unit (
    input  logic [11:0] m_frac,     // Fractional part m (Q0.12 format)
    output logic [11:0] log2_frac   // Approximated log2(1+m) (Q0.12 format)
);
    logic [2:0]  seg_idx;
    logic [11:0] b_coeff;
    logic [11:0] approx_m;
    logic [12:0] sum_temp;

    assign seg_idx = m_frac[11:9];  // 3 MSBs select 1 of 8 segments

    always_comb begin
        case (seg_idx)
            // Segment 0: m in [0.000, 0.125) -> slope ~1.375
            3'b000: begin b_coeff = 12'd0;    approx_m = m_frac + (m_frac >> 2) + (m_frac >> 3); end
            
            // Segment 1: m in [0.125, 0.250) -> slope ~1.250
            3'b001: begin b_coeff = 12'd56;   approx_m = m_frac + (m_frac >> 2); end
            
            // Segment 2: m in [0.250, 0.375) -> slope ~1.125
            3'b010: begin b_coeff = 12'd167;  approx_m = m_frac + (m_frac >> 3); end
            
            // Segment 3: m in [0.375, 0.500) -> slope ~1.000
            3'b011: begin b_coeff = 12'd346;  approx_m = m_frac; end
            
            // Segment 4: m in [0.500, 0.625) -> slope ~0.9375
            3'b100: begin b_coeff = 12'd476;  approx_m = m_frac - (m_frac >> 4); end
            
            // Segment 5: m in [0.625, 0.750) -> slope ~0.875
            3'b101: begin b_coeff = 12'd629;  approx_m = m_frac - (m_frac >> 3); end
            
            // Segment 6: m in [0.750, 0.875) -> slope ~0.8125
            3'b110: begin b_coeff = 12'd811;  approx_m = m_frac - (m_frac >> 3) - (m_frac >> 4); end
            
            // Segment 7: m in [0.875, 1.000) -> slope ~0.750
            3'b111: begin b_coeff = 12'd1027; approx_m = (m_frac >> 1) + (m_frac >> 2); end
            
            default: begin b_coeff = 12'd0;   approx_m = m_frac; end
        endcase
    end
    
    // Compute sum with 13-bit precision
    assign sum_temp = approx_m + b_coeff;

    // Saturation Logic: Clamp output to 4095 (12'hFFF) if sum exceeds 12-bit max range
    assign log2_frac = (sum_temp > 13'd4095) ? 12'hFFF : sum_temp[11:0];
endmodule