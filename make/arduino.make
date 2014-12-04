# -*- mode: makefile -*-

# compiler and linker flags
CFLAGS   = -Os -ffunction-sections -fdata-sections
CFLAGS  += -mmcu=$(DEVICE) -DF_CPU=$(F_CPU) -mcall-prologues
CFLAGS  += -g
CXXFLAGS = $(CFLAGS) -fno-exceptions
LDFLAGS  = -Wl,--gc-sections

# set up avr tools and arduino installation
PLATFORM := $(shell uname -s)
ifeq ($(PLATFORM),Darwin)
	ARDUINO_BASEDIR := /Applications/Arduino.app/Contents/Resources/Java
	AVRTOOL_PREFIX  := $(ARDUINO_BASEDIR)/hardware/tools/avr
	AVRDUDE_CONF    := $(AVRTOOL_PREFIX)/etc/avrdude.conf
else
	AVRTOOL_PREFIX  := /usr
	ARDUINO_BASEDIR := /usr/share/arduino
	AVRDUDE_CONF    := /etc/avrdude.conf
#	AVRDUDE_CONF    := $(ARDUINO_BASEDIR)/hardware/tools/avrdude.conf
endif

CC      = $(AVRTOOL_PREFIX)/bin/avr-gcc
CXX     = $(AVRTOOL_PREFIX)/bin/avr-g++
AR      = $(AVRTOOL_PREFIX)/bin/avr-ar
RANLIB  = $(AVRTOOL_PREFIX)/bin/avr-ranlib
AVRDUDE = $(AVRTOOL_PREFIX)/bin/avrdude
OBJCOPY = $(AVRTOOL_PREFIX)/bin/avr-objcopy
AVRSIZE = $(AVRTOOL_PREFIX)/bin/avr-size

########################
# internal code
########################
%.fwstamp:
	[ -e $@ ] || $(MAKE) clean
	touch $@
CLEANFILES += .*.fwstamp

define fw-rule =
$(1):  .arduino-$(1).fwstamp arduino-$(1).hex
upload-$(1): $(1)
	$$(AVRDUDE) -C$$(AVRDUDE_CONF) -p$$(DEVICE) -carduino -b$$(AVRDUDE_BAUDRATE) -P$$(AVRDUDE_DEVICE) -D -V -Uflash:w:arduino-$(1).hex
CLEANFILES += arduino-$(1).hex
endef
$(foreach fw,$(FIRMWARES),$(eval $(call fw-rule,$(fw))))

OBJDIR = obj
$(OBJDIR):
	@mkdir -p $(OBJDIR)

define compile =
$$(addprefix $$(OBJDIR)/$(1)-,$$(notdir $(2))).o: $(2)
	mkdir -p $$(OBJDIR)
	$(3) $(4) -c -o $$@ $$<
	@$(3) -MM $(4) -MQ $$@ $$< > $$@.d 
endef

define avr-size =
$(AVRSIZE) --mcu=$(DEVICE) $(1) | \
awk 'NR<2 {print $$0;next} {sumtext += $$1; sumdata += $$2; sumbss += $$3; sumdec += $$4; print $$0| "sort -k4 -n"} END { printf "%7s %7s %7s %7s %11s\n", sumtext, sumdata, sumbss, sumdec, "SUM" }'
endef

define PROGRAM_template =
 PROGRAM_SRCS += $$($(1)_SRCS)
 $$(foreach src,$$(filter %.c,$$($(1)_SRCS)),$$(eval $$(call compile,$(1),$$(src),$$(CC),$$(CFLAGS) $$(value $(1)_FLAGS))))
 $$(foreach src,$$(filter %.cpp,$$($(1)_SRCS)),$$(eval $$(call compile,$(1),$$(src),$$(CXX),$$(CXXFLAGS) $$(value $(1)_FLAGS))))

 $(1)_OBJS := $$(notdir $$($(1)_SRCS))
 $(1)_OBJS := $$(addprefix $$(OBJDIR)/,$$($(1)_OBJS:%=$(1)-%.o))
 PROGRAM_OBJS += $$($(1)_OBJS)
 OBJECTS += $$($(1)_OBJS)

 $$($(1)_OBJS): CXXFLAGS += $$($(1)_FLAGS)
 .$(1).stamp: $$($(1)_OBJS)
	@echo "Calculating sizes for $(1) objects"
	@$$(call avr-size,$$($(1)_OBJS))
	touch $$@
 CLEANFILES +=  .$(1).stamp
 $(1): .$(1).program
endef

define LIBRARY_template =
 LDLIBS     += $$(OBJDIR)/$(1).a
 $$(foreach src,$$(filter %.c,$$($(1)_SRCS)),$$(eval $$(call compile,$(1),$$(src),$$(CC),$$(CFLAGS) $$(value $(1)_FLAGS))))
 $$(foreach src,$$(filter %.cpp,$$($(1)_SRCS)),$$(eval $$(call compile,$(1),$$(src),$$(CXX),$$(CXXFLAGS) $$(value $(1)_FLAGS))))

 $(1)_OBJS := $$(notdir $$($(1)_SRCS))
 $(1)_OBJS := $$(addprefix $$(OBJDIR)/,$$($(1)_OBJS:%=$(1)-%.o))
 OBJECTS += $$($(1)_OBJS)

 $$($(1)_OBJS):  CFLAGS   += $$(value $(1)_FLAGS)
 $$($(1)_OBJS):  CXXFLAGS += $$(value $(1)_FLAGS)

 $(1): $$(OBJDIR)/$(1).a
 $$(OBJDIR)/$(1).a: $$($(1)_OBJS)
	@echo "Calculating sizes for $$@ objects"
	@$$(call avr-size,$$($(1)_OBJS))
	@$$(AR) cr $$@ $$($(1)_OBJS)
	@$$(RANLIB) $$@
endef


$(foreach prog,$(PROGRAMS),$(eval $(call PROGRAM_template,$(prog))))
$(foreach lib,$(LIBRARIES),$(eval $(call LIBRARY_template,$(lib))))

%.hex: %.elf
	@echo "Creating $@"
	@$(OBJCOPY) -O ihex -R .eeprom $^ $@

%.elf: $(LDLIBS) $(PROGRAM_OBJS) 
	@echo "Linking $@"
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $(PROGRAM_OBJS) $(LDLIBS) -lc -lm
	@echo
	@$(AVRSIZE) --mcu=$(DEVICE) -C $@

clean:
	rm -rf $(OBJDIR)
	rm -f $(CLEANFILES)
	rm -f *.elf

.PRECIOUS: %.elf

-include $(OBJECTS:%=%.d)

#.PHONY: $(PROGRAM_SRCS)