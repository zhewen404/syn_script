# ECE552 Extra Credit
read_file -format sverilog {dut.sv}
set current_design dut
link

###########################################
# Define clock and set don't mess with it #
###########################################
# clk with frequency of 33.55 MHz
create_clock -name "clk" -period 2.5 -waveform { 0 1.25 } { clk }
# clk with frequencey of 0.13 MHz
#create_clock -name "clk" -period 7600 -waveform { 0 3800 } { clk }
set_dont_touch_network [find port clk]
# pointer to all inputs except clk
set prim_inputs [remove_from_collection [all_inputs] [find port clk]]
# pointer to all inputs except clk and rst_n
set prim_inputs_no_rst [remove_from_collection $prim_inputs [find port rst_n]]
# Set clk uncertainty (skew)
set_clock_uncertainty 0.15 clk

#########################################
# Set input delay & drive on all inputs #
#########################################
set_input_delay -clock clk 0.25 [copy_collection $prim_inputs]
#set_driving_cell -lib_cell ND2D2BWP -library tcbn40lpbwptc $prim_inputs_no_rst
# rst_n goes to many places so don't touch
set_dont_touch_network [find port rst_n]

##########################################
# Set output delay & load on all outputs #
##########################################
set_output_delay -clock clk 0.5 [all_outputs]
set_load 0.1 [all_outputs]

#############################################################
# Wire load model allows it to estimate internal parasitics #
#############################################################
# set_wire_load_model -name TSMC32K_Lowk_Conservative -library tcbn40lpbwptc

######################################################
# Max transition time is important for Hot-E reasons #
######################################################
set_max_transition 0.1 [current_design]

########################################
# Now actually synthesize for 1st time #
########################################
compile -map_effort medium
check_design

# Unflatten design now that its compiled
# ungroup -all -flatten
# force hold time to be met for all flops
set_fix_hold clk

# Compile again with higher effort
compile -map_effort high
check_design

#############################################
# Take a look at area, max, and min timings #
#############################################
report_area -hierarchy > dut_hier_area.txt
report_power -hierarchy > dut_hier_power.txt
report_timing -delay min > dut_hier_min_delay.txt
report_timing -delay max > dut_hier_max_delay.txt

########################################
# Now actually synthesize for 2nd time #
########################################
compile -map_effort medium
check_design

# Unflatten design now that its compiled
ungroup -all -flatten
# force hold time to be met for all flops
set_fix_hold clk

# Compile again with higher effort
compile -map_effort high
check_design

#############################################
# Take a look at area, max, and min timings #
#############################################
report_area > dut_flat_area.txt
report_power > dut_flat_power.txt
report_timing -delay min > dut_flat_min_delay.txt
report_timing -delay max > dut_flat_max_delay.txt

#### write out final netlist ######
write -format verilog dut -output dut.vg
exit
