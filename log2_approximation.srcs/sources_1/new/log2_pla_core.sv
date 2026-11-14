`timescale 1ns / 1ps

// Computes log2(x) using LOD, Barrel Shifter, and 8-Segment PLA
// 3-Stage Pipelined Base-2 Logarithm Core
module log2_pla_core (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] x_in,         // 16-bit unsigned integer input
    output logic [15:0] log2_out,     // Output in Q4.12 fixed-point format
    output logic        invalid_op    // High when x_in == 0 (log2(0) is undefined)
);

    // =========================================================================
    // STAGE 1: Leading-One Detection (LOD16) & Zero Flag Extraction
    // =========================================================================
    logic [3:0] lod_k;
    logic       lod_zero;

    // Instantiate lod_16bit
    lod_16bit u_lod_16bit (
        .in_x      (x_in),
        .k_out     (lod_k),
        .zero_flag (lod_zero)
    );

    // Stage 1 Pipeline Registers
    logic [15:0] stage1_x;
    logic [3:0]  stage1_k;
    logic        stage1_invalid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_x       <= 16'd0;
            stage1_k       <= 4'd0;
            stage1_invalid <= 1'b0;
        end else begin
            stage1_x       <= x_in;
            stage1_k       <= lod_k;
            stage1_invalid <= lod_zero;
        end
    end

    // =========================================================================
    // STAGE 2: Normalization & Mantissa Extraction (Barrel Shifter)
    // =========================================================================
    logic [11:0] mantissa_comb;

    // Instantiate barrel_shifter
    barrel_shifter u_barrel_shifter (
        .in_x   (stage1_x),
        .k_in   (stage1_k),
        .m_frac (mantissa_comb)
    );

    // Stage 2 Pipeline Registers
    logic [3:0]  stage2_k;
    logic [11:0] stage2_mantissa;
    logic        stage2_invalid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_k        <= 4'd0;
            stage2_mantissa <= 12'd0;
            stage2_invalid  <= 1'b0;
        end else begin
            stage2_k        <= stage1_k;
            stage2_mantissa <= mantissa_comb;
            stage2_invalid  <= stage1_invalid;
        end
    end

    // =========================================================================
    // STAGE 3: Fractional PLA Correction & Output Assembly
    // =========================================================================
    logic [11:0] pla_frac_comb;

    // Instantiate pla_8seg_unit
    pla_8seg_unit u_pla_8seg_unit (
        .m_frac    (stage2_mantissa),
        .log2_frac (pla_frac_comb)
    );

    // Stage 3 Output Registers
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            log2_out   <= 16'd0;
            invalid_op <= 1'b0;
        end else begin
            // Assemble 4-bit integer part and 12-bit fractional part into Q4.12
            log2_out   <= {stage2_k, pla_frac_comb};
            invalid_op <= stage2_invalid;
        end
    end

endmodule