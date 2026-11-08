`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.11.2026 15:11:00
// Design Name: 
// Module Name: log2_apprx_top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Top-Level Testbench for log2_apprx_top module
// Simulates sending ASCII text via UART RX pin and captures TX responses
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module log2_apprx_top_tb;

    // System Signals
    logic       clk;
    logic       rst_n;
    logic       uart_rx_i;
    logic       uart_tx_o;
    logic [3:0] leds;

    // Timing Constants
    localparam CLK_PERIOD = 8;     // 125 MHz System Clock -> 8 ns period
    localparam BIT_PERIOD = 8680;  // 115200 Baud Rate -> ~8680.5 ns per bit

    // Instantiate Renamed Top-Level Module (log2_apprx_top)
    log2_apprx_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx_i(uart_rx_i),
        .uart_tx_o(uart_tx_o),
        .leds(leds)
    );

    // Clock Generator (125 MHz)
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Background Process: Capture UART TX output and print to Vivado Tcl Console
    logic [7:0] tx_data_captured;
    initial begin
        forever begin
            // Wait for Start bit (falling edge on TX line)
            @(negedge uart_tx_o);
            #(BIT_PERIOD / 2); // Sample at the middle of the Start bit

            // Read 8 Data Bits (LSB First)
            for (int i = 0; i < 8; i++) begin
                #(BIT_PERIOD);
                tx_data_captured[i] = uart_tx_o;
            end

            // Wait for Stop bit
            #(BIT_PERIOD);
            $write("%c", tx_data_captured); // Display captured character in real-time
        end
    end

    // Main Test Stimulus
    initial begin
        clk       = 0;
        rst_n     = 0;
        uart_rx_i = 1; // Idle state for UART RX line (HIGH)

        #40;
        rst_n = 1;
        #100;

        // Allow initial prompt string to be transmitted over UART
        #300000;

        // --- Test 1: Send string "255" followed by Enter (\r) ---
        send_uart_string("255\r");
        #4000000; // Wait for processing and string response transmission

        // --- Test 2: Send string "12" followed by Enter (\r) ---
        send_uart_string("12\r");
        #4000000;

        // --- Test 3: Send string "1024" followed by Enter (\r) ---
        send_uart_string("1024\r");
        #4000000;

        // --- Test 4: Special Boundary Case "0" ---
        send_uart_string("0\r");
        #4000000;

        $display("\n==========================================================================");
        $display("          LOG2_APPRX_TOP SIMULATION COMPLETED SUCCESSFULLY                ");
        $display("==========================================================================");
        $finish;
    end

    // Task to transmit a single ASCII byte over uart_rx_i pin at 115200 Baud
    task send_uart_byte(input [7:0] data_byte);
        begin
            // Start Bit
            uart_rx_i = 1'b0;
            #(BIT_PERIOD);

            // 8 Data Bits (LSB First)
            for (int i = 0; i < 8; i++) begin
                uart_rx_i = data_byte[i];
                #(BIT_PERIOD);
            end

            // Stop Bit
            uart_rx_i = 1'b1;
            #(BIT_PERIOD);
        end
    endtask

    // Task to transmit an entire ASCII string character by character
    task send_uart_string(input string str);
        begin
            for (int i = 0; i < str.len(); i++) begin
                send_uart_byte(str[i]);
                #50000; // Inter-character delay
            end
        end
    endtask

endmodule