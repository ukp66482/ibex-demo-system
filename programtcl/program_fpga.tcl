open_hw_manager
connect_hw_server
open_hw_target
set device [lindex [get_hw_devices] 0]
current_hw_device $device
set_property PROGRAM.FILE {build/lowrisc_ibex_demo_system_0/synth_nexysa7-vivado/lowrisc_ibex_demo_system_0.runs/impl_1/top_nexysa7.bit} $device
program_hw_devices $device
close_hw_manager