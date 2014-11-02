#=============================================================================#
# Author: QueezyTheGreat                                                      #
# Date:   26.04.2011                                                          #
#                                                                             #
# Description: Arduino CMake example                                          #
#                                                                             #
#=============================================================================#
set(CMAKE_TOOLCHAIN_FILE arduino-cmake/cmake/ArduinoToolchain.cmake) # Arduino Toolchain


cmake_minimum_required(VERSION 2.8)
#====================================================================#
#  Setup Project                                                     #
#====================================================================#
project(ArduinoExample C CXX)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")

# disable for proper debug logging
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DSAVEMEM")

# enable for serial debugging
#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DSERIALDEBUG")

# override default baudrate of 115200
#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DBAUDRATE=9600")

#print_board_list()
#print_programmer_list()

set(ARDUINO_DEFAULT_BOARD atmega328) # Default Board ID, when not specified
set(ARDUINO_DEFAULT_PORT /dev/ttyUSB0) # Default Port, when not specified


generate_arduino_firmware(striprevolution
                          SRCS striprevolution.cpp
                          HDRS Buffer.h Commands.h CommandParser.h
                         )
