# -*- mode: makefile -*-

# The teensy version to use, 30 or 31
TEENSY = 31
# Set to 24000000, 48000000, or 96000000 to set CPU core speed
TEENSY_CORE_SPEED ?= 48000000

# path location for Teensy Loader, teensy_post_compile and teensy_reboot
TOOLSPATH = $(CURDIR)/tools
# path location for Teensy 3 core
COREPATH = $(CURDIR)/teensy3

# configurable options
OPTIONS  = -DUSB_SERIAL -DLAYOUT_US_ENGLISH



ifeq ($(OS),Windows_NT)
    $(error What is Win Dose?)
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Darwin)
        TOOLSPATH = /Applications/Arduino.app/Contents/Resources/Java/hardware/tools/
        COREPATH  = /Applications/Arduino.app/Contents/Resources/Java/hardware/teensy/cores/teensy3
    endif
endif

# path location for the arm-none-eabi compiler
COMPILERPATH = $(TOOLSPATH)/arm-none-eabi/bin


# compiler and linker flags
CFLAGS   = 
CPPFLAGS = -Wall -g -Os -mcpu=cortex-m4 -mthumb -nostdlib -MMD $(OPTIONS) -DF_CPU=$(TEENSY_CORE_SPEED) -Isrc -I$(COREPATH)
CXXFLAGS = -std=gnu++0x -felide-constructors -fno-exceptions -fno-rtti

# compiler options specific to teensy version
ifeq ($(TEENSY), 30)
    CPPFLAGS += -D__MK20DX128__
    LDSCRIPT = $(COREPATH)/mk20dx128.ld
else
    ifeq ($(TEENSY), 31)
        CPPFLAGS += -D__MK20DX256__
        LDSCRIPT = $(COREPATH)/mk20dx256.ld
    else
        $(error Invalid setting for TEENSY)
    endif
endif

# linker options
LDFLAGS = -Os -Wl,--gc-sections -mcpu=cortex-m4 -mthumb -T$(LDSCRIPT)


# path location for the arm-none-eabi compiler
COMPILERPATH = $(abspath $(TOOLSPATH))/arm-none-eabi/bin
AVRDUDE = $(abspath $(TOOLSPATH))/teensy_post_compile
AVRDUDEFLAGS = -file="$(basename $<)" -path=$(CURDIR) -tools="$(abspath $(TOOLSPATH))"
AVRSIZEFLAGS = 

# names for the compiler programs
CC = $(abspath $(COMPILERPATH))/arm-none-eabi-gcc
CXX = $(abspath $(COMPILERPATH))/arm-none-eabi-g++
OBJCOPY = $(abspath $(COMPILERPATH))/arm-none-eabi-objcopy
AVRSIZE = $(abspath $(COMPILERPATH))/arm-none-eabi-size
AR      = $(abspath $(COMPILERPATH))/arm-none-eabi-ar
RANLIB  = $(abspath $(COMPILERPATH))/arm-none-eabi-gcc-ranlib



include make/common.make 
