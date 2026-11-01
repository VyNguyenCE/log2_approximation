`timescale 1ns / 1ps

// Normalization Barrel Shifter
// Extracts 12 fractional bits immediately following the MSB 1-bit (Q0.12 format)
module barrel_shifter (
    input  logic [15:0] in_x,
    input  logic [3:0]  k_in,
    output logic [11:0] m_frac      // 12-bit fractional part m (Q0.12 format)
);
    logic [31:0] shifted_x;

    always_comb begin
        // Shift left to align the MSB 1-bit to bit position 31
        shifted_x = {16'b0, in_x} << (16 - k_in);
        // Extract 12 bits immediately after the MSB 1-bit
        m_frac    = shifted_x[30:19];
    end
endmodule