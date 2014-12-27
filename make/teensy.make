# -*- mode: makefile -*-

# The teensy version to use, 30 or 31
TEENSY = 31
# Set to 24000000, 48000000, or 96000000 to set CPU core speed
TEENSY_CORE_SPEED ?= 48000000
# configurable options
OPTIONS  = -DUSB_SERIAL -DLAYOUT_US_ENGLISH

# set up avr tools and arduino installation
PLATFORM := $(shell uname -s)
ifeq ($(PLATFORM),Darwin)
	ARDUINO_BASEDIR := /Applications/Arduino.app/Contents/Resources/Java
        TOOLSPATH    := $(ARDUINO_BASEDIR)/hardware/tools
        COREPATH     := $(ARDUINO_BASEDIR)/hardware/teensy/cores/teensy3
	COMPILERPATH := $(TOOLSPATH)/arm-none-eabi/bin
else
	ARDUINO_BASEDIR := $(HOME)/teensy/arduino-1.0.6
        TOOLSPATH    := $(ARDUINO_BASEDIR)/hardware/tools
        COREPATH     := $(ARDUINO_BASEDIR)/hardware/teensy/cores/teensy3
	COMPILERPATH := /usr/bin
endif

# path location for the arm-none-eabi compiler
COMPILERPATH = $(TOOLSPATH)/arm-none-eabi/bin

# compiler options specific to teensy version
ifeq ($(TEENSY), 30)
    OPTIONS += -D__MK20DX128__
    LDSCRIPT = $(COREPATH)/mk20dx128.ld
else
    ifeq ($(TEENSY), 31)
        OPTIONS += -D__MK20DX256__
        LDSCRIPT = $(COREPATH)/mk20dx256.ld
    else
        $(error Invalid setting for TEENSY)
    endif
endif

# linker options
# compiler and linker flags
CPPFLAGS = -Wall -g -Os -mcpu=cortex-m4 -mthumb -nostdlib -MMD $(OPTIONS) -DF_CPU=$(TEENSY_CORE_SPEED) -I$(COREPATH)
CFLAGS   = $(CPPFLAGS)
CXXFLAGS = $(CPPFLAGS) -std=gnu++0x -felide-constructors -fno-exceptions -fno-rtti
LDFLAGS = -Os -Wl,--gc-sections -mcpu=cortex-m4 -mthumb -T$(LDSCRIPT)

CC      = $(COMPILERPATH)/arm-none-eabi-gcc
CXX     = $(COMPILERPATH)/arm-none-eabi-g++
AR      = $(COMPILERPATH)/arm-none-eabi-ar
RANLIB  = $(COMPILERPATH)/arm-none-eabi-gcc-ranlib
AVRDUDE = $(TOOLSPATH)/teensy_post_compile
OBJCOPY = $(COMPILERPATH)/arm-none-eabi-objcopy
OBJSIZE = $(COMPILERPATH)/arm-none-eabi-size

define fw-rule =
$(1):  .$(1).fwstamp $(1).hex 
upload-$(1): $(1)
	$$(TOOLSPATH)/teensy_post_compile -file=$(1).hex -path=$$(CURDIR) -tools=$$(TOOLSPATH)
CLEANFILES += $(1).hex
endef

include make/common.make 
