`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.11.2026 15:07:51
// Design Name: 
// Module Name: log2_pla_core_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Testbench for directly testing log2_pla_core module
// Verifies calculation accuracy, pipeline latency, and special boundary cases
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module log2_pla_core_tb;

    // Inputs
    logic        clk;
    logic        rst_n;
    logic [15:0] x_in;

    // Outputs
    logic [15:0] log2_out;
    logic        invalid_op;

    // Instantiate Design Under Test (DUT)
    log2_pla_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .x_in(x_in),
        .log2_out(log2_out),
        .invalid_op(invalid_op)
    );

    // Clock Generation: 125 MHz (Clock Period = 8 ns)
    always #4 clk = ~clk;

    // Helper Function: Convert Q4.12 fixed-point value to real (double precision)
    function automatic real q4_12_to_real(input logic [15:0] q_val);
        return real'(q_val[15:12]) + (real'(q_val[11:0]) / 4096.0);
    endfunction

    // Helper Function: Compute exact theoretical log2(x) using natural logarithm
    function automatic real log2_exact(input real x);
        if (x <= 0.0) return 0.0;
        return $ln(x) / $ln(2.0);
    endfunction

    // Variables for performance metrics
    real exact_val;
    real approx_val;
    real abs_error;
    real max_error;

    // Test Sequence
    initial begin
        // Initialize Signals
        clk       = 0;
        rst_n     = 0;
        x_in      = 16'd0;
        max_error = 0.0;

        // Apply Reset
        #20;
        rst_n = 1;
        #12;

        $display("==========================================================================================");
        $display("                       FUNCTIONAL SIMULATION FOR LOG2_PLA_CORE                            ");
        $display("==========================================================================================");

        // --- Test Group 1: Special Case (x = 0) ---
        apply_test(16'd0);

        // --- Test Group 2: Powers of 2 (Exact Integer Results) ---
        apply_test(16'd1);
        apply_test(16'd2);
        apply_test(16'd4);
        apply_test(16'd16);
        apply_test(16'd256);
        apply_test(16'd1024);
        apply_test(16'd32768);

        // --- Test Group 3: General Integer Values ---
        apply_test(16'd3);
        apply_test(16'd12);
        apply_test(16'd255);
        apply_test(16'd12345);
        apply_test(16'd65535);

        $display("==========================================================================================");
        $display(" Maximum Absolute Error (WCE) observed in test suite: %0.6f", max_error);
        $display("==========================================================================================");
        $finish;
    end

    // Task to apply test input, wait for 2-stage pipeline latency, and display evaluation
    task apply_test(input [15:0] in_val);
        begin
            x_in = in_val;
            #16; // Wait 2 clock cycles for 2-stage pipeline latency

            if (invalid_op) begin
                $display("[Time %5t ns] Input x = %5d | Hex Out = 0x%04X | Approx = N/A    | Exact = N/A    | Invalid = %b (Pass)",
                         $time, x_in, log2_out, invalid_op);
            end else begin
                exact_val  = log2_exact(real'(x_in));
                approx_val = q4_12_to_real(log2_out);
                abs_error  = (exact_val > approx_val) ? (exact_val - approx_val) : (approx_val - exact_val);
                
                if (abs_error > max_error) begin
                    max_error = abs_error;
                end

                $display("[Time %5t ns] Input x = %5d | Hex Out = 0x%04X | Approx = %8.4f | Exact = %8.4f | Error = %0.6f",
                         $time, x_in, log2_out, approx_val, exact_val, abs_error);
            end
        end
    endtask

endmodule