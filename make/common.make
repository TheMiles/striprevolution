# -*- mode: makefile -*-

########################
# internal code
########################

print-%: ; @echo $* is $($*)

# objects, compilation and helpers
OBJDIR = obj
$(OBJDIR):
	@mkdir -p $(OBJDIR)

define compile =
$$(addprefix $$(OBJDIR)/$(1)-,$$(notdir $(2))).o: $(2)
	mkdir -p $$(OBJDIR)
	$(3) $(4) -c -o $$@ $$<
	@$(3) -MM $(4) -MQ $$@ -MF $$@.d $$<
endef

define obj-size =
$(OBJSIZE) $(OBJSIZE_FLAGS) $(1) | \
awk 'NR<2 {print $$0;next} {sumtext += $$1; sumdata += $$2; sumbss += $$3; sumdec += $$4; print $$0| "sort -k4 -n"} END { printf "%7s %7s %7s %7s %11s\n", sumtext, sumdata, sumbss, sumdec, "SUM" }'
endef

# program rules
define PROGRAM_template =
 PROGRAM_SRCS += $$($(1)_SRCS)
 $$(foreach src,$$(filter %.c,$$($(1)_SRCS)),$$(eval $$(call compile,$(1)-$(2),$$(src),$$(CC),$$(CFLAGS) $$(value $(1)_FLAGS))))
 $$(foreach src,$$(filter %.cpp,$$($(1)_SRCS)),$$(eval $$(call compile,$(1)-$(2),$$(src),$$(CXX),$$(CXXFLAGS) $$(value $(1)_FLAGS))))

 $(1)-$(2)_OBJS := $$(notdir $$($(1)_SRCS))
 $(1)-$(2)_OBJS := $$(addprefix $$(OBJDIR)/,$$($(1)-$(2)_OBJS:%=$(1)-$(2)-%.o))
 OBJECTS += $$($(1)-$(2)_OBJS)

 $$($(1)-$(2)_OBJS): CXXFLAGS += $$($(1)_FLAGS)
 .$(1)-$(2).stamp: $$($(1)-$(2)_OBJS)
	@echo "Calculating sizes for $(1)-$(2) objects"
	@$$(call obj-size,$$($(1)-$(2)_OBJS))
	touch $$@
 CLEANFILES +=  .$(1)-$(2).stamp
endef

# library rules
define LIBRARY_template =
 LDLIBS     += $$(OBJDIR)/$(1)$$($(1)_SUFFIX).a
 $$(foreach src,$$(filter %.c,$$($(1)_SRCS)),$$(eval $$(call compile,$(1)$$($(1)_SUFFIX),$$(src),$$(CC),$$(CFLAGS) $$(value $(1)_FLAGS))))
 $$(foreach src,$$(filter %.cpp,$$($(1)_SRCS)),$$(eval $$(call compile,$(1)$$($(1)_SUFFIX),$$(src),$$(CXX),$$(CXXFLAGS) $$(value $(1)_FLAGS))))

 $(1)_OBJS := $$(notdir $$($(1)_SRCS))
 $(1)_OBJS := $$(addprefix $$(OBJDIR)/,$$($(1)_OBJS:%=$(1)$$($(1)_SUFFIX)-%.o))
 OBJECTS += $$($(1)_OBJS)

 $$($(1)_OBJS):  CFLAGS   += $$(value $(1)_FLAGS)
 $$($(1)_OBJS):  CXXFLAGS += $$(value $(1)_FLAGS)

 $(1): $$(OBJDIR)/$(1).a
 $$(OBJDIR)/$(1)$$($(1)_SUFFIX).a: $$($(1)_OBJS)
	@echo "Calculating sizes for $$@ objects"
	@$$(call obj-size,$$($(1)_OBJS))
	@$$(AR) cr $$@ $$($(1)_OBJS)
	@$$(RANLIB) $$@
endef

# firmware rules
.%.fwstamp: %.hex
	touch $@

define fw-rule =
$(1):  .$(1).fwstamp $(1).hex
$(eval $(call upload-rule,$(1)))
CLEANFILES += $(1).hex .$(1).fwstamp
$(eval $(call PROGRAM_template,$(PROGRAM),$(1)))
endef

$(foreach fw,$(FIRMWARES),$(eval $(call fw-rule,$(fw))))
$(foreach lib,$(LIBRARIES),$(eval $(call LIBRARY_template,$(lib))))

%.hex: %.elf
	@echo "Creating $@"
	@$(OBJCOPY) -O ihex -R .eeprom $^ $@

%.elf: .$(PROGRAM)-%.stamp $(LDLIBS)
	@echo "Linking $@"
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $(OBJDIR)/$(PROGRAM)-$(patsubst %.elf,%,$@)*.o $(LDLIBS) -lc -lm
	@echo
	@$(OBJSIZE) $(OBJSIZE_FLAGS) $@

clean:
	rm -rf $(OBJDIR)
	rm -f $(CLEANFILES)
	rm -f *.elf

.PRECIOUS: %.elf

-include $(OBJECTS:%=%.d)

#.PHONY: $(PROGRAM_SRCS)
