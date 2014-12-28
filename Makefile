ifneq (4.0,$(firstword $(sort $(MAKE_VERSION) 4.0)))
$(error Need make version 4.0)
endif

TARGETS = striplib teensy

RPI_TARGET := $(shell [ -e /proc/cpuinfo ] && grep -q BCM2708 /proc/cpuinfo && echo rpi)

TARGETS += $(RPI_TARGET)
all: $(TARGETS)

avr rpi teensy: 
	$(MAKE) -f Makefile.$@

AVR_TARGETS = avr-std avr-xbee upload upload-avr-std upload-avr-xbee

define avr_target =
$(1):
	$$(MAKE) -f Makefile.avr $$@
endef
$(foreach t,$(AVR_TARGETS),$(eval $(call avr_target,$(t))))

clean:
	for t in $(TARGETS:build-%=%); do \
	  [ -e Makefile.$$t ] && $(MAKE) -f Makefile.$$t $@; true; \
	done
	find . -name '*~' | xargs rm -f
	rm -f striplib/commands.py

striplib: striplib/commands.py

striplib/commands.py: common/Commands.h
	scripts/make_commands.sh $< > $@

.PHONY: avr rpi teensy
