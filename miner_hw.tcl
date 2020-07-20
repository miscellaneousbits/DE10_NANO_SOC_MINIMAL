# TCL File Generated by Component Editor 18.1
# Mon Jul 20 09:20:20 EDT 2020
# DO NOT MODIFY


# 
# miner "miner" v1.1
# jcyr 2020.07.20.09:20:20
# SHA3-256 Miner Avalon Slave
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module miner
# 
set_module_property DESCRIPTION "SHA3-256 Miner Avalon Slave"
set_module_property NAME miner
set_module_property VERSION 1.1
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR jcyr
set_module_property DISPLAY_NAME miner
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL miner
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file miner.v VERILOG PATH miner_ip/miner.v TOP_LEVEL_FILE
add_fileset_file sha3_256_miner.v VERILOG PATH miner_ip/sha3_256_miner.v
add_fileset_file permutation.v VERILOG PATH miner_ip/permutation.v


# 
# documentation links
# 
add_documentation_link miner file:///doc/miner.html


# 
# parameters
# 
add_parameter MINER_CLK_MHZ STRING "60 MHz" "Miner clock frequency"
set_parameter_property MINER_CLK_MHZ DEFAULT_VALUE "60 MHz"
set_parameter_property MINER_CLK_MHZ DISPLAY_NAME MINER_CLK_MHZ
set_parameter_property MINER_CLK_MHZ TYPE STRING
set_parameter_property MINER_CLK_MHZ UNITS None
set_parameter_property MINER_CLK_MHZ DESCRIPTION "Miner clock frequency"
set_parameter_property MINER_CLK_MHZ HDL_PARAMETER true
add_parameter MINER_MAJ_VER INTEGER 1 "Miner major version"
set_parameter_property MINER_MAJ_VER DEFAULT_VALUE 1
set_parameter_property MINER_MAJ_VER DISPLAY_NAME MINER_MAJ_VER
set_parameter_property MINER_MAJ_VER TYPE INTEGER
set_parameter_property MINER_MAJ_VER ENABLED false
set_parameter_property MINER_MAJ_VER UNITS None
set_parameter_property MINER_MAJ_VER ALLOWED_RANGES -2147483648:2147483647
set_parameter_property MINER_MAJ_VER DESCRIPTION "Miner major version"
set_parameter_property MINER_MAJ_VER HDL_PARAMETER true
add_parameter MINER_MIN_VER INTEGER 1 "Miner minor version"
set_parameter_property MINER_MIN_VER DEFAULT_VALUE 1
set_parameter_property MINER_MIN_VER DISPLAY_NAME MINER_MIN_VER
set_parameter_property MINER_MIN_VER TYPE INTEGER
set_parameter_property MINER_MIN_VER ENABLED false
set_parameter_property MINER_MIN_VER UNITS None
set_parameter_property MINER_MIN_VER ALLOWED_RANGES -2147483648:2147483647
set_parameter_property MINER_MIN_VER DESCRIPTION "Miner minor version"
set_parameter_property MINER_MIN_VER HDL_PARAMETER true


# 
# module assignments
# 
set_module_assignment embeddedsw.dts.compatible dev,miner
set_module_assignment embeddedsw.dts.group miner
set_module_assignment embeddedsw.dts.vendor cyr


# 
# display items
# 


# 
# connection point clock_sink
# 
add_interface clock_sink clock end
set_interface_property clock_sink clockRate 0
set_interface_property clock_sink ENABLED true
set_interface_property clock_sink EXPORT_OF ""
set_interface_property clock_sink PORT_NAME_MAP ""
set_interface_property clock_sink CMSIS_SVD_VARIABLES ""
set_interface_property clock_sink SVD_ADDRESS_GROUP ""

add_interface_port clock_sink clk clk Input 1


# 
# connection point reset_sink
# 
add_interface reset_sink reset end
set_interface_property reset_sink associatedClock clock_sink
set_interface_property reset_sink synchronousEdges DEASSERT
set_interface_property reset_sink ENABLED true
set_interface_property reset_sink EXPORT_OF ""
set_interface_property reset_sink PORT_NAME_MAP ""
set_interface_property reset_sink CMSIS_SVD_VARIABLES ""
set_interface_property reset_sink SVD_ADDRESS_GROUP ""

add_interface_port reset_sink rst reset Input 1


# 
# connection point avalon_slave
# 
add_interface avalon_slave avalon end
set_interface_property avalon_slave addressUnits WORDS
set_interface_property avalon_slave associatedClock clock_sink
set_interface_property avalon_slave associatedReset reset_sink
set_interface_property avalon_slave bitsPerSymbol 8
set_interface_property avalon_slave burstOnBurstBoundariesOnly false
set_interface_property avalon_slave burstcountUnits WORDS
set_interface_property avalon_slave explicitAddressSpan 0
set_interface_property avalon_slave holdTime 0
set_interface_property avalon_slave linewrapBursts false
set_interface_property avalon_slave maximumPendingReadTransactions 0
set_interface_property avalon_slave maximumPendingWriteTransactions 0
set_interface_property avalon_slave readLatency 0
set_interface_property avalon_slave readWaitTime 1
set_interface_property avalon_slave setupTime 0
set_interface_property avalon_slave timingUnits Cycles
set_interface_property avalon_slave writeWaitTime 0
set_interface_property avalon_slave ENABLED true
set_interface_property avalon_slave EXPORT_OF ""
set_interface_property avalon_slave PORT_NAME_MAP ""
set_interface_property avalon_slave CMSIS_SVD_VARIABLES ""
set_interface_property avalon_slave SVD_ADDRESS_GROUP ""

add_interface_port avalon_slave address address Input 5
add_interface_port avalon_slave read read Input 1
add_interface_port avalon_slave readdata readdata Output 32
add_interface_port avalon_slave write write Input 1
add_interface_port avalon_slave writedata writedata Input 32
set_interface_assignment avalon_slave embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave embeddedsw.configuration.isPrintableDevice 0


# 
# connection point interrupt_sender
# 
add_interface interrupt_sender interrupt end
set_interface_property interrupt_sender associatedAddressablePoint avalon_slave
set_interface_property interrupt_sender associatedClock clock_sink
set_interface_property interrupt_sender associatedReset reset_sink
set_interface_property interrupt_sender bridgedReceiverOffset ""
set_interface_property interrupt_sender bridgesToReceiver ""
set_interface_property interrupt_sender ENABLED true
set_interface_property interrupt_sender EXPORT_OF ""
set_interface_property interrupt_sender PORT_NAME_MAP ""
set_interface_property interrupt_sender CMSIS_SVD_VARIABLES ""
set_interface_property interrupt_sender SVD_ADDRESS_GROUP ""

add_interface_port interrupt_sender irq irq Output 1

