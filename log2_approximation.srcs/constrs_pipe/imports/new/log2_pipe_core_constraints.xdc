
################################################################################
# LOG2 PLA 3-STAGE PIPELINE CONSTRAINTS
# Target clock frequency: 125 MHz
################################################################################

# Actual clock port
create_clock -name core_clk -period 8.000 [get_ports clk]

# Input timing
set_input_delay -clock core_clk -max 0.000 [get_ports {x_in[*]}]
set_input_delay -clock core_clk -min 0.000 [get_ports {x_in[*]}]

# Output timing
set_output_delay -clock core_clk -max 0.000 [get_ports {log2_out[*]}]
set_output_delay -clock core_clk -min 0.000 [get_ports {log2_out[*]}]

set_output_delay -clock core_clk -max 0.000 [get_ports invalid_op]
set_output_delay -clock core_clk -min 0.000 [get_ports invalid_op]

# Asynchronous active-low reset
set_false_path -from [get_ports rst_n]
