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
        // Align bit k_in of in_x to bit 31 of shifted_x
        shifted_x = {in_x, 16'b0} << (15 - k_in);
        // Extract 12 bits immediately following the MSB 1-bit (bits [30:19])
        m_frac    = shifted_x[30:19];
    end
endmodule