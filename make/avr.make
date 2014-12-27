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

CC         = $(AVRTOOL_PREFIX)/bin/avr-gcc
CXX        = $(AVRTOOL_PREFIX)/bin/avr-g++
AR         = $(AVRTOOL_PREFIX)/bin/avr-ar
RANLIB     = $(AVRTOOL_PREFIX)/bin/avr-ranlib
OBJCOPY    = $(AVRTOOL_PREFIX)/bin/avr-objcopy
OBJSIZE    = $(AVRTOOL_PREFIX)/bin/avr-size

PROGRAMMER_FLAGS = 
OBJSIZE_FLAGS = --mcu=$(DEVICE)

define fw-rule =
$(1):  .$(1).fwstamp $(1).hex
upload-$(1): $(1)
	$$(AVRTOOL_PREFIX)/bin/avrdude -C$$(AVRDUDE_CONF) -p$$(DEVICE) -carduino -b$$(AVRDUDE_BAUDRATE) -P$$(AVRDUDE_DEVICE) -D -V -Uflash:w:$(1).hex
CLEANFILES += $(1).hex
endef

include make/common.make
