set_global_assignment -entity "clock_100" -library "lib_clock_100" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "clock_100" -library "lib_clock_100" -name IP_TOOL_VERSION "23.1"
set_global_assignment -entity "clock_100" -library "lib_clock_100" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_clock_100" -name SPD_FILE [file join $::quartus(sip_path) "clock_100.spd"]

set_global_assignment -library "lib_clock_100" -name MISC_FILE [file join $::quartus(sip_path) "clock_100_sim/clock_100.vo"]
