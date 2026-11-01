`timescale 1ns / 1ps

// Pipelined Log2 Core (2 Pipeline Stages)
// Computes log2(x) using LOD, Barrel Shifter, and 8-Segment PLA
module log2_pla_core (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] x_in,
    output logic [15:0] log2_out,   // Output in Q4.12 fixed-point format
    output logic        invalid_op
);
    // Stage 1 Signals
    logic [3:0]  k_s1;
    logic [11:0] m_s1;
    logic        zero_s1;

    // Pipeline Registers (Stage 1 -> Stage 2)
    logic [3:0]  k_s2;
    logic [11:0] m_s2;
    logic        zero_s2;

    // Stage 2 Signals
    logic [11:0] log2_frac_s2;

    // ----- Stage 1: LOD & Normalization -----
    lod_16bit lod_inst (
        .in_x(x_in), .k_out(k_s1), .zero_flag(zero_s1)
    );

    barrel_shifter shifter_inst (
        .in_x(x_in), .k_in(k_s1), .m_frac(m_s1)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            k_s2    <= 4'd0;
            m_s2    <= 12'd0;
            zero_s2 <= 1'b1;
        end else begin
            k_s2    <= k_s1;
            m_s2    <= m_s1;
            zero_s2 <= zero_s1;
        end
    end

    // ----- Stage 2: PLA Calculation & Result Assembly -----
    pla_8seg_unit pla_inst (
        .m_frac(m_s2), .log2_frac(log2_frac_s2)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            log2_out   <= 16'd0;
            invalid_op <= 1'b0;
        end else begin
            invalid_op <= zero_s2;
            if (zero_s2)
                log2_out <= 16'h0000;
            else
                log2_out <= {k_s2, log2_frac_s2}; // Combine 4-bit integer k and 12-bit fraction
        end
    end
endmodule