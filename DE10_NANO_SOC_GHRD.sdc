create_clock -period "50.0 MHz" [get_ports FPGA_CLK1_50]

#create_clock -name {altera_reserved_tck} -period 40 {altera_reserved_tck}
#set_input_delay -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tdi]
#set_input_delay -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tms]
#set_output_delay -clock altera_reserved_tck 3 [get_ports altera_reserved_tdo]

derive_pll_clocks
derive_clock_uncertainty

set_clock_groups -asynchronous \
   -group [get_clocks {FPGA_CLK1_50}] \
	-group [get_clocks {u0|miner_0|altera_pll_0|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]
