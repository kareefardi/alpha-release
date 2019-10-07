#DESIGN_CONFIG=./designs/spm_nangate.mk

DESIGN_CONFIG?=./designs/spm_nangate.mk

# Link flute data files
./PORT9.dat:
	ln -sf $(OPENROAD)/share/replace/$@ $@
./POST9.dat:
	ln -sf $(OPENROAD)/share/replace/$@ $@
./POWV9.dat:
	ln -sf $(OPENROAD)/share/replace/$@ $@
../etc/PORT9.dat:
	mkdir -p ../etc
	ln -sf $(OPENROAD)/share/replace/PORT9.dat $@
../etc/POST9.dat:
	mkdir -p ../etc
	ln -sf $(OPENROAD)/share/replace/POST9.dat $@
../etc/POWV9.dat:
	mkdir -p ../etc
	ln -sf $(OPENROAD)/share/replace/POWV9.dat $@




include $(DESIGN_CONFIG)
include ./platforms/$(PLATFORM)/config.mk

export LOG_DIR     = ./new_logs/$(PLATFORM)/$(DESIGN_NAME)
export RESULTS_DIR = ./new_results/$(PLATFORM)/$(DESIGN_NAME)
export OBJECTS_DIR = ./new_objects/$(PLATFORM)/$(DESIGN_NAME)
export REPORTS_DIR = ./new_reports/$(PLATFORM)/$(DESIGN_NAME)
export SCRIPTS_DIR = ./scripts

all: $(RESULTS_DIR)/netlist.v

# Pre-process libraries
# ==============================================================================
$(OBJECTS_DIR)/merged.lib: $(DESIGN_LIB_FILES)
	mkdir -p $(OBJECTS_DIR)
	$(SCRIPTS_DIR)/mergeLib.pl $(PLATFORM)_merged \
	                           $(LIB_FILES) \
	                           > $@.tmp
	$(SCRIPTS_DIR)/markDontUse.pl -p "$(DONT_USE_CELLS)" -i $@.tmp -o $@


# SYNTHESIS
# ==============================================================================
SYNTH_SCRIPT ?= scripts/synth.tcl
$(RESULTS_DIR)/1_1_yosys.v: $(OBJECTS_DIR)/merged.lib
	mkdir -p $(RESULTS_DIR) $(LOG_DIR) $(REPORTS_DIR) $(OBJECTS_DIR)
	yosys -l $(LOG_DIR)/yosys.log -c $(SYNTH_SCRIPT)

$(RESULTS_DIR)/netlist.v: $(RESULTS_DIR)/1_1_yosys.v
	cp $< $@


# FLOORPLAN
# ==============================================================================
DB_UNITS ?= 2000

	
$(RESULTS_DIR)/floorplan.def: $(RESULTS_DIR)/netlist.v 
	verilog2def \
		-lef $(MERGED_LEF) \
		-liberty $(OBJECTS_DIR)/merged.lib \
		-verilog $(RESULTS_DIR)/netlist.v \
		-units $(DB_UNITS) \
		-site $(PLACE_SITE) \
		-def $@ \
		-tracks $(TRACKS_INFO_FILE) \
		-die_area "$(DIE_AREA)" -core_area "$(CORE_AREA)" \
		-top_module $(DESIGN_NAME) \
		2>&1 | tee $(LOG_DIR)/verilog2def.log

HMETAL ?= 5
VMETAL ?= 6
$(RESULTS_DIR)/floorplan_pins.def: $(RESULTS_DIR)/floorplan.def
	ioPlacer \
		-l $(MERGED_LEF) \
		-d $(RESULTS_DIR)/floorplan.def \
		-o $@ \
		-h $(HMETAL) \
		-v $(VMETAL) \
		-r 2 \
		2>&1 | tee $(LOG_DIR)/ioPlacer.log


floorplan: $(RESULTS_DIR)/floorplan_pins.def

# PLACEMENT
# ==============================================================================
place:  $(RESULTS_DIR)/placed_gp_dp.def

$(OBJECTS_DIR)/padded.lef:
	$(SCRIPTS_DIR)/modifyLefSpacing.py -i $(MERGED_LEF) -o $@

$(RESULTS_DIR)/placed_gp.def:  $(RESULTS_DIR)/floorplan_pins.def $(OBJECTS_DIR)/padded.lef
	RePlAce \
		-bmflag etc \
		-lef $(OBJECTS_DIR)/padded.lef \
		-def $(RESULTS_DIR)/floorplan_pins.def \
		-output $(RESULTS_DIR)/replace \
		-plot \
		-onlyGP \
		-experi output
		cp $(RESULTS_DIR)/replace/etc/floorplan_pins/output/floorplan_pins_final.def $@

$(RESULTS_DIR)/placed_gp_dp.def: $(RESULTS_DIR)/placed_gp.def
	opendp \
		-lef $(OBJECTS_DIR)/padded.lef \
		-def $< \
		-output_def $@ \
		2>&1 | tee $(LOG_DIR)/opendp.log


# ROUTING
# ==============================================================================
PADDED_LEF ?= $(OBJECTS_DIR)/padded.lef
PLACED_DEF ?= $(RESULTS_DIR)/placed_gp_dp.def
export PLACED_DEF 
export PADDED_LEF


$(RESULTS_DIR)/route.guide: $(RESULTS_DIR)/placed_gp_dp.def $(OBJECTS_DIR)/padded.lef POWV9.dat POST9.dat
	envsubst < $(SCRIPTS_DIR)/fastroute_mod.rsyn > $(OBJECTS_DIR)/fastroute.rsyn
	FRlefdef --no-gui --script $(OBJECTS_DIR)/fastroute.rsyn \
		2>&1 | tee $(LOG_DIR)/FRlefdef.log

$(OBJECTS_DIR)/TritonRoute.param: $(RESULTS_DIR)/route.guide
	echo "lef:$(MERGED_LEF)" > $@
	echo "def:$(RESULTS_DIR)/placed_gp_dp.def" >> $@
	echo "guide:$(RESULTS_DIR)/route.guide" >> $@
	echo "output:$(RESULTS_DIR)/placed_gp_dp_dr.def" >> $@
	echo "outputTA:$(RESULTS_DIR)/TritonRoute_TA.def" >> $@
	echo "verbose:1" >> $@

$(RESULTS_DIR)/placed_gp_dp_dr.def: $(OBJECTS_DIR)/TritonRoute.param
	TritonRoute \
		$< \
		2>&1 | tee $(LOG_DIR)/TritonRoute.log


route: $(RESULTS_DIR)/placed_gp_dp_dr.def

clean:
	rm -rf ./new_results ./new_logs ./new_reports ./new_objects
