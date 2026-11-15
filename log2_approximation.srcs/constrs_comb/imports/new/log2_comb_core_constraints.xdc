
################################################################################
# LOG2 COMBINATIONAL CORE CONSTRAINTS
# Mitchell / LUT + Interpolation / PLA Unpipelined
# Target timing period: 8 ns (125 MHz reference)
################################################################################

# Virtual clock: no physical clock port in combinational cores
create_clock -name core_virt_clk -period 8.000

# Input timing
set_input_delay -clock core_virt_clk -max 0.000 [get_ports {x_in[*]}]
set_input_delay -clock core_virt_clk -min 0.000 [get_ports {x_in[*]}]

# Output timing
set_output_delay -clock core_virt_clk -max 0.000 [get_ports {log2_out[*]}]
set_output_delay -clock core_virt_clk -min 0.000 [get_ports {log2_out[*]}]

set_output_delay -clock core_virt_clk -max 0.000 [get_ports invalid_op]
set_output_delay -clock core_virt_clk -min 0.000 [get_ports invalid_op]
