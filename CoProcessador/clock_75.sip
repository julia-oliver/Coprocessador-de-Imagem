set_global_assignment -entity "clock_75" -library "lib_clock_75" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "clock_75" -library "lib_clock_75" -name IP_TOOL_VERSION "23.1"
set_global_assignment -entity "clock_75" -library "lib_clock_75" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_clock_75" -name SPD_FILE [file join $::quartus(sip_path) "clock_75.spd"]

set_global_assignment -library "lib_clock_75" -name MISC_FILE [file join $::quartus(sip_path) "clock_75_sim/clock_75.vo"]
