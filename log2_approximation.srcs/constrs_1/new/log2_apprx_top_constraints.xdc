################################################################################
# 1. SYSTEM CLOCK CONSTRAINT (125 MHz System Clock)
################################################################################
# Define 125 MHz system clock (Period = 8.000 ns) on port 'clk'
create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} [get_ports clk]

# Package pin assignment for system clock on PYNQ-Z2 board (Pin H16 - Bank 34)
set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports clk]


################################################################################
# 2. CONTROL SIGNALS (Reset Signal)
################################################################################
# Assign active-low reset 'rst_n' to Switch SW0 on PYNQ-Z2 (Pin M20)
set_property -dict { PACKAGE_PIN M20   IOSTANDARD LVCMOS33 } [get_ports rst_n]


################################################################################
# 3. UART INTERFACE PINS (Serial Communication)
################################################################################
# Assign UART RX and TX pins for serial communication with host PC
# RX Pin (Data input from PC): Assigned to Pin Y18 (Raspberry Pi Header RXD)
set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33 } [get_ports uart_rx_i]

# TX Pin (Data output to PC): Assigned to Pin Y19 (Raspberry Pi Header TXD)
set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33 } [get_ports uart_tx_o]


################################################################################
# 4. BITSTREAM CONFIGURATION PROPERTIES
################################################################################
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]