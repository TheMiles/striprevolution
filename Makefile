TARGETS = build-arduino build-rpi striplib

all: $(TARGETS)

build-arduino:
	$(MAKE) -f Makefile.arduino
build-rpi:
	$(MAKE) -f Makefile.rpi

ARDUINO_TARGETS = std xbee upload upload-std upload-xbee

define arduino_target =
$(1):
	$$(MAKE) -f Makefile.arduino $$@
endef
$(foreach t,$(ARDUINO_TARGETS),$(eval $(call arduino_target,$(t))))

clean:
	for t in $(TARGETS:build-%=%); do \
	  [ -e Makefile.$$t ] && $(MAKE) -f Makefile.$$t $@; true; \
	done
	find . -name '*~' | xargs rm -f
	rm -f striplib/commands.py

striplib: striplib/commands.py

striplib/commands.py: common/Commands.h
	scripts/make_commands.sh $< > $@
