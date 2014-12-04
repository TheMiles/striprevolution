#!/usr/bin/python

# might lose additional RAM for lookup tables, or have to write smarter
# LED interface, e.g. use nops for calculation of next pixel
# LUTs might be possible to approximate with simpler (asm) code?
# 
# potential LUT sizes:
#   16-bit: 2^5 + 2^6 bytes -> 96 bytes
#    8-bit: 2^3 + 2^2 bytes -> 12 bytes
#
# types:
#   RGB    - triplet of 8-bit unsigned integers red, green, blue
#   RGB888 - 24-bit unsigned integer
#   RGB565 - 16-bit unsigned integer
#   RGB332 - 8-bit unsigned integer

def RGBtoRGB888(red,green,blue):
    return (red << 16) | (green << 8) | blue

def RGB888toRGB( rgb888):
    return [(rgb888 >> 16) & 0xff, (rgb888 >> 8) & 0xff, rgb888 & 0xff]

# 16-bit hicolor
# constants are added to ensure proper quantization
# c = 256/maxval(channel)/2
def RGBtoRGB565(red,green,blue):
    val = (((31*(red  +4))/255) << 11) | \
          (((63*(green+2))/255) <<  5) | \
          ( (31*(blue +4))/255)
    return val

def RGB888toRGB565(rgb888):
    red, green, blue = RGB888toRGB(rgb888)
    return RGBtoRGB565(red,green,blue)

def RGB565toRGB888( rgb565):
    red   = (((rgb565 >> 11) & 0x1f)*255)/31
    green = (((rgb565 >>  5) & 0x3f)*255)/63
    blue  = ( (rgb565        & 0x1f)*255)/31
    return RGBtoRGB888(red,green,blue)

# 8-bit 'truecolor'
# constants are added to ensure proper quantization
# c = 256/maxval(channel)/2
def RGBtoRGB332(red,green,blue):
    val = (((7*(red  +16))/255)<<5) | \
          (((7*(green+16))/255)<<2) | \
          ( (3*(blue +32))/255)
    return val

def RGB888toRGB332(rgb888):
    red, green, blue = RGB888toRGB(rgb888)
    return RGBtoRGB332(red,green,blue)

def RGB332toRGB888( rgb332):
    red   = (((rgb332 >> 5) & 0x7)*255)/7
    green = (((rgb332 >> 2) & 0x7)*255)/7
    blue  = ( (rgb332       & 0x3)*255)/3
    return RGBtoRGB888(red,green,blue)

def testRGB565():
    for i in xrange(256):
        v1 = RGBtoRGB565(i,i,i)
        v2 = RGB565toRGB888(v1)
        rgb = RGB888toRGB(v2)
        print i, v1, rgb

def testRGB332():
    for i in xrange(256):
        v1 = i
        v2 = RGB332toRGB888(v1)
        rgb = RGB888toRGB(v2)
        print i, v1, rgb

# TODO: 8-bit palettes? see first how RGB332 performs
#
# http://en.wikipedia.org/wiki/List_of_software_palettes#256_colors
# http://en.wikipedia.org/wiki/List_of_8-bit_computer_hardware_palettes#MSX2

testRGB565()
#testRGB332()
