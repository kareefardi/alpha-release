read_liberty ${LIB_FILES}
read_verilog ${NETLIST}
link_design ${DESIGN_NAME} 
create_clock -name ${CLOCK_PORT} -period ${CLOCK_PERIOD}
check_setup
# unconstrained for now due to nature of design ?
report_checks -unconstrained
report_checks -unconstrained > ${REPORTS_DIR}/opensta.rpt
