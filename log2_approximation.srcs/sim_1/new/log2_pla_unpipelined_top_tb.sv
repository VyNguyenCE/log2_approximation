`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.11.2026 16:02:47
// Design Name: 
// Module Name: log2_pla_unpipelined_top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Testbench for Option C: Un-pipelined PLA 8-Segment (Pure Combinational)
// Evaluates calculation accuracy, WCE (Worst Case Error), and invalid operations
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module log2_pla_core_tb;

    // Testbench Signals
    logic        clk;
    logic        rst_n;
    logic [15:0] x_in;
    logic [15:0] log2_out;
    logic        invalid_op;

    // Clock Generation (10ns period = 100 MHz)
    always #5 clk = ~clk;

    // Instantiate Design Under Test (DUT)
    log2_pla_core dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .x_in       (x_in),
        .log2_out   (log2_out),
        .invalid_op (invalid_op)
    );

    // Helper Function: Convert Q4.12 fixed-point format to real number
    function automatic real q4_12_to_real(input logic [15:0] q_val);
        return real'(q_val[15:12]) + (real'(q_val[11:0]) / 4096.0);
    endfunction

    // Helper Function: Compute exact theoretical log2(x)
    function automatic real log2_exact(input real x);
        if (x <= 0.0) return 0.0;
        return $ln(x) / $ln(2.0);
    endfunction

    // Metrics variables
    real exact_val;
    real approx_val;
    real abs_error;
    real max_error;

    initial begin
        // Initialize Signals
        clk       = 1'b0;
        rst_n     = 1'b0;
        x_in      = 16'd0;
        max_error = 0.0;

        // Reset Sequence
        #20;
        rst_n = 1'b1;
        #10;

        $display("==========================================================================================");
        $display("                       SIMULATION FOR 3-STAGE PIPELINED LOG2_PLA_CORE                     ");
        $display("==========================================================================================");

        // --- Test Vectors ---
        apply_test(16'd0);
        apply_test(16'd1);
        apply_test(16'd2);
        apply_test(16'd4);
        apply_test(16'd16);
        apply_test(16'd256);
        apply_test(16'd1024);
        apply_test(16'd32768);
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

    // Task to apply test input and evaluate accuracy metrics after 3 clock cycles of latency
    task apply_test(input [15:0] in_val);
        begin
            // Drive input on falling edge of clock to ensure stable setup time
            @(negedge clk);
            x_in = in_val;

            // Wait for 3 clock cycles to account for 3-stage pipeline latency
            repeat (3) @(posedge clk);
            #1; // Small margin to sample output stably after register update

            if (invalid_op) begin
                $display("[Time %5t ns] Input x = %5d | Hex Out = 0x%04X | Approx = N/A    | Exact = N/A    | Invalid = %b (Pass)",
                         $time, in_val, log2_out, invalid_op);
            end else begin
                exact_val  = log2_exact(real'(in_val));
                approx_val = q4_12_to_real(log2_out);
                abs_error  = (exact_val > approx_val) ? (exact_val - approx_val) : (approx_val - exact_val);
                
                if (abs_error > max_error) begin
                    max_error = abs_error;
                end

                $display("[Time %5t ns] Input x = %5d | Hex Out = 0x%04X | Approx = %8.4f | Exact = %8.4f | Error = %0.6f",
                         $time, in_val, log2_out, approx_val, exact_val, abs_error);
            end
        end
    endtask

endmodule