`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.10.2026 20:23:44
// Design Name: 
// Module Name: log2_apprx_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module log2_apprx_top (
    input  logic       clk,        // System Clock 125 MHz (Pin H16 PYNQ-Z2)
    input  logic       rst_n,      // Reset Active Low (BTN0 - Pin D19)
    input  logic       uart_rx_i,  // UART RX pin
    output logic       uart_tx_o,  // UART TX pin
    output logic [3:0] leds        // Status LEDs LD0-LD3
);

    // Internal UART Signals
    logic [7:0] rx_byte;
    logic       rx_done;
    logic [7:0] tx_byte;
    logic       tx_start;
    logic       tx_busy;

    // Log2 Core Signals
    logic [15:0] x_in_reg;
    logic [15:0] log2_result;
    logic        invalid_flag;

    // Buffers for input digits and output strings
    logic [15:0] x_val;
    logic [7:0]  in_buf [0:4];   // Store up to 5 ASCII digits (0 - 65535)
    logic [2:0]  in_len;

    logic [7:0]  tx_buf [0:63];  // Output string buffer (up to 64 bytes)
    logic [5:0]  tx_len;
    logic [5:0]  tx_idx;

    // Decoding variables from Q4.12 fixed-point to ASCII Decimal
    logic [3:0]  int_part;
    logic [11:0] frac_part;
    logic [25:0] frac_mult;
    logic [13:0] frac_dec;
    logic [7:0]  d1, d2, d3, d4;

    // UART RX Instance (125 MHz, 115200 bps)
    uart_rx #(.CLK_FREQ(125_000_000), .BAUD_RATE(115200)) rx_inst (
        .clk(clk), .rst_n(rst_n), .rx(uart_rx_i),
        .rx_data(rx_byte), .rx_done(rx_done)
    );

    // UART TX Instance (125 MHz, 115200 bps)
    uart_tx #(.CLK_FREQ(125_000_000), .BAUD_RATE(115200)) tx_inst (
        .clk(clk), .rst_n(rst_n),
        .tx_data(tx_byte), .tx_start(tx_start),
        .tx(uart_tx_o), .tx_busy(tx_busy)
    );

    // Pipelined Log2 PLA Core Instance
    log2_pla_core log2_core_inst (
        .clk(clk), .rst_n(rst_n),
        .x_in(x_in_reg),
        .log2_out(log2_result),
        .invalid_op(invalid_flag)
    );

    // Finite State Machine (FSM)
    typedef enum logic [2:0] {
        INIT_PROMPT, // Load prompt string: "Hay nhap so can tinh log2: "
        SEND_BUF,    // Transmit buffer content over UART TX
        RX_DECIMAL,  // Receive ASCII digits from terminal keyboard
        CALC_WAIT,   // Wait for Log2 Pipeline execution
        PREP_RESULT  // Format result string into tx_buf
    } fsm_t;

    fsm_t state, next_state_after_tx;

    // Extract Integer (4 bits) and Fractional part (12 bits Q0.12)
    assign int_part  = log2_result[15:12];
    assign frac_part = log2_result[11:0];

    // Convert Q0.12 fraction to 4 decimal digits: (frac_part * 10000) / 4096
    assign frac_mult = frac_part * 14'd10000;
    assign frac_dec  = frac_mult[25:12]; // Right shift by 12 (equivalent to division by 4096)

    always_comb begin
        d1 = 8'd48 + (frac_dec / 1000) % 10;
        d2 = 8'd48 + (frac_dec / 100)  % 10;
        d3 = 8'd48 + (frac_dec / 10)   % 10;
        d4 = 8'd48 + (frac_dec % 10);
    end

    // FSM State Controller
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state               <= INIT_PROMPT;
            next_state_after_tx <= RX_DECIMAL;
            tx_start            <= 1'b0;
            tx_byte             <= 8'd0;
            tx_idx              <= 6'd0;
            tx_len              <= 6'd0;
            x_val               <= 16'd0;
            x_in_reg            <= 16'd0;
            in_len              <= 3'd0;
        end else begin
            tx_start <= 1'b0;

            case (state)

                // -------------------------------------------------------------
                // 1. LOAD PROMPT STRING: "Hay nhap so can tinh log2: "
                // -------------------------------------------------------------
                INIT_PROMPT: begin
                    tx_buf[0]  <= "H"; tx_buf[1]  <= "a"; tx_buf[2]  <= "y"; tx_buf[3]  <= " ";
                    tx_buf[4]  <= "n"; tx_buf[5]  <= "h"; tx_buf[6]  <= "a"; tx_buf[7]  <= "p"; tx_buf[8]  <= " ";
                    tx_buf[9]  <= "s"; tx_buf[10] <= "o"; tx_buf[11] <= " ";
                    tx_buf[12] <= "c"; tx_buf[13] <= "a"; tx_buf[14] <= "n"; tx_buf[15] <= " ";
                    tx_buf[16] <= "t"; tx_buf[17] <= "i"; tx_buf[18] <= "n"; tx_buf[19] <= "h"; tx_buf[20] <= " ";
                    tx_buf[21] <= "l"; tx_buf[22] <= "o"; tx_buf[23] <= "g"; tx_buf[24] <= "2"; tx_buf[25] <= ":"; tx_buf[26] <= " ";
                    
                    tx_len              <= 6'd27;
                    tx_idx              <= 6'd0;
                    x_val               <= 16'd0;
                    in_len              <= 3'd0;
                    next_state_after_tx <= RX_DECIMAL;
                    state               <= SEND_BUF;
                end

                // -------------------------------------------------------------
                // 2. TRANSMIT BUFFER BYTES OVER UART TX PORT
                // -------------------------------------------------------------
                SEND_BUF: begin
                    if (tx_idx < tx_len) begin
                        if (!tx_busy && !tx_start) begin
                            tx_byte  <= tx_buf[tx_idx];
                            tx_start <= 1'b1;
                            tx_idx   <= tx_idx + 1;
                        end
                    end else begin
                        state <= next_state_after_tx;
                    end
                end

                // -------------------------------------------------------------
                // 3. RECEIVE ASCII DIGITS AND ECHO TO TERMINAL SCREEN
                // -------------------------------------------------------------
                RX_DECIMAL: begin
                    if (rx_done) begin
                        // Check if typed byte is a digit '0' -> '9'
                        if (rx_byte >= "0" && rx_byte <= "9" && in_len < 3'd5) begin
                            in_buf[in_len] <= rx_byte;
                            in_len         <= in_len + 1;
                            x_val          <= (x_val * 10) + (rx_byte - "0");

                            // Echo received byte back to PuTTY terminal
                            if (!tx_busy) begin
                                tx_byte  <= rx_byte;
                                tx_start <= 1'b1;
                            end
                        end
                        // On Enter key press (CR=0x0D / LF=0x0A) or Space key (0x20)
                        else if ((rx_byte == 8'h0D || rx_byte == 8'h0A || rx_byte == 8'h20) && (in_len > 0)) begin
                            x_in_reg <= x_val;
                            state    <= CALC_WAIT;
                        end
                    end
                end

                // -------------------------------------------------------------
                // 4. WAIT FOR LOG2 PIPELINE CALCULATION (2 CLOCK CYCLES)
                // -------------------------------------------------------------
                CALC_WAIT: begin
                    state <= PREP_RESULT;
                end

                // -------------------------------------------------------------
                // 5. FORMAT RESULT STRING "Tinh xap xi Log2 cua <x> la: <res>"
                // -------------------------------------------------------------
                PREP_RESULT: begin
                    // Add Newline + "Tinh xap xi Log2 cua " (23 bytes)
                    tx_buf[0]  <= 8'h0D; tx_buf[1]  <= 8'h0A;
                    tx_buf[2]  <= "T"; tx_buf[3]  <= "i"; tx_buf[4]  <= "n"; tx_buf[5]  <= "h"; tx_buf[6]  <= " ";
                    tx_buf[7]  <= "x"; tx_buf[8]  <= "a"; tx_buf[9]  <= "p"; tx_buf[10] <= " ";
                    tx_buf[11] <= "x"; tx_buf[12] <= "i"; tx_buf[13] <= " ";
                    tx_buf[14] <= "L"; tx_buf[15] <= "o"; tx_buf[16] <= "g"; tx_buf[17] <= "2"; tx_buf[18] <= " ";
                    tx_buf[19] <= "c"; tx_buf[20] <= "u"; tx_buf[21] <= "a"; tx_buf[22] <= " ";

                    // Append input digits
                    tx_buf[23] <= in_buf[0];
                    if (in_len > 1) tx_buf[24] <= in_buf[1];
                    if (in_len > 2) tx_buf[25] <= in_buf[2];
                    if (in_len > 3) tx_buf[26] <= in_buf[3];
                    if (in_len > 4) tx_buf[27] <= in_buf[4];

                    // Append " la: "
                    tx_buf[23 + in_len] <= " ";
                    tx_buf[24 + in_len] <= "l";
                    tx_buf[25 + in_len] <= "a";
                    tx_buf[26 + in_len] <= ":";
                    tx_buf[27 + in_len] <= " ";

                    if (invalid_flag) begin
                        // If x = 0: Output "Khong xac dinh!\r\n\n"
                        tx_buf[28 + in_len] <= "K"; tx_buf[29 + in_len] <= "h"; tx_buf[30 + in_len] <= "o"; tx_buf[31 + in_len] <= "n"; tx_buf[32 + in_len] <= "g"; tx_buf[33 + in_len] <= " ";
                        tx_buf[34 + in_len] <= "x"; tx_buf[35 + in_len] <= "a"; tx_buf[36 + in_len] <= "c"; tx_buf[37 + in_len] <= " ";
                        tx_buf[38 + in_len] <= "d"; tx_buf[39 + in_len] <= "i"; tx_buf[40 + in_len] <= "n"; tx_buf[41 + in_len] <= "h"; tx_buf[42 + in_len] <= "!";
                        tx_buf[43 + in_len] <= 8'h0D; tx_buf[44 + in_len] <= 8'h0A; tx_buf[45 + in_len] <= 8'h0A;
                        tx_len <= 46 + in_len;
                    end else begin
                        // Format real number: [Tens][Ones].[d1][d2][d3][d4]\r\n\n
                        if (int_part >= 4'd10) begin
                            tx_buf[28 + in_len] <= "1";
                            tx_buf[29 + in_len] <= 8'd48 + (int_part - 4'd10);
                            tx_buf[30 + in_len] <= ".";
                            tx_buf[31 + in_len] <= d1;
                            tx_buf[32 + in_len] <= d2;
                            tx_buf[33 + in_len] <= d3;
                            tx_buf[34 + in_len] <= d4;
                            tx_buf[35 + in_len] <= 8'h0D;
                            tx_buf[36 + in_len] <= 8'h0A;
                            tx_buf[37 + in_len] <= 8'h0A;
                            tx_len <= 38 + in_len;
                        end else begin
                            tx_buf[28 + in_len] <= 8'd48 + int_part;
                            tx_buf[29 + in_len] <= ".";
                            tx_buf[30 + in_len] <= d1;
                            tx_buf[31 + in_len] <= d2;
                            tx_buf[32 + in_len] <= d3;
                            tx_buf[33 + in_len] <= d4;
                            tx_buf[34 + in_len] <= 8'h0D;
                            tx_buf[35 + in_len] <= 8'h0A;
                            tx_buf[36 + in_len] <= 8'h0A;
                            tx_len <= 37 + in_len;
                        end
                    end

                    tx_idx              <= 6'd0;
                    next_state_after_tx <= INIT_PROMPT; // Automatically prompt again after printing result
                    state               <= SEND_BUF;
                end

            endcase
        end
    end

    // Status LEDs
    assign leds[0]   = (state != RX_DECIMAL);
    assign leds[1]   = invalid_flag;
    assign leds[3:2] = log2_result[15:14];

endmodule

