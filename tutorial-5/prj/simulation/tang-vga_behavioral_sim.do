#
# Create work library
#
vlib work
#
# Compile sources
#
vlog  C:/Users/jerem/OneDrive/Desktop/Tang/tang-vga/src/vga_top.v
vlog  C:/Users/jerem/OneDrive/Desktop/Tang/tang-vga/src/pll.v
vlog  C:/Users/jerem/OneDrive/Desktop/Tang/tang-vga/src/VGA_Sync_Pulses.v
vlog  C:/Users/jerem/OneDrive/Desktop/Tang/tang-vga/src/Test_Pattern_Gen.v
vlog  C:/Users/jerem/OneDrive/Desktop/Tang/tang-vga/src/Sync_To_Count.v
vlog  C:/Users/jerem/OneDrive/Desktop/Tang/tang-vga/src/VGA_Sync_Porch.v
vlog  C:/Users/jerem/OneDrive/Desktop/Tang/tang-vga/prj/simulation/vga_top_tb.v
#
# Call vsim to invoke simulator
#
vsim -L  -gui -novopt work.vga_top_tb
#
# Add waves
#
add wave *
#
# Run simulation
#
run 1000ns
#
# End