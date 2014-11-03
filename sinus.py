#!/usr/bin/env python

import colorsys, math, signal, sys, time, os, select, errno

from striplib import Strip

# parameters for direct connection
speed = 115200
timeout = 1

# parameters for XBee
#speed = 9600
#timeout = 1

# python 2.5 compatibility (i.e. N900)
if not 'bytearray' in dir(__builtins__):
    import array
    def bytearray( bytelist):
        return array.array('b',bytelist)

args = [
    ('num_leds',      5),
    ('max_intensity', 0xf),
    ('min_delay',     1/20.),
    ('stepsize',      math.pi/256.),
]

class Rainbow:
    def __init__(self,nleds,max,stepsize=math.pi/256.):
        self.max      = max
        self.nleds    = nleds
        self.hsv      = [0,1,1]
        self.stepsize = stepsize
    
    def iterateLin(self):
        return [ self.hsv[0]+i*self.stepsize for i in xrange(self.nleds) ]
    def iterateSin(self):
        return [ abs(math.sin(self.hsv[0]+i*self.stepsize))
                 for i in xrange(self.nleds) ]
    def iterateSin2(self):
        return [ math.pow(math.sin(self.hsv[0]+i*self.stepsize), 2)
                 for i in xrange(self.nleds) ]
    def iterate(self):
        val = self.iterateLin()
        self.hsv[0] += self.stepsize
        while self.hsv[0]+self.nleds*self.stepsize > 1: self.hsv[0] -= 1
        while self.hsv[0] < 0: self.hsv[0] += 1
        msg = []
        for i in val:
            msg += [ int(j*self.max)
                     for j in colorsys.hsv_to_rgb(i, *(self.hsv[1:3]))]
        return bytearray(msg)

doIterate = True
def signal_handler(signal, frame):
    global doIterate
    doIterate = False
    print "Caught SIGINT, stopping"

def main():
    global args
    for i, arg in enumerate(args):
        if len(sys.argv) <= i+1:
            break
        val = sys.argv[i+1]
        if isinstance(val,str) and val.startswith('0x'):
            val = int(val, 16)
        args[i] = (arg[0], val)

    size = max( [ len(arg[0]) for arg in args ])
    for arg in args:
        name, val = arg
        name = name.ljust(size)
        if isinstance(val,float):
            print "%s: %.3f" % (name,val)
        else:
            print "%s: %s"   % (name,val)
    print
    
    vars = dict(args)
    
    strip = Strip()
    port = strip.findDevice()
    if not port:
        print "No device found"
        sys.exit(1)

    print "Opening '%s'" % port
    if not strip.connect(port, speed=speed, timeout=timeout):
        sys.exit(1)
    retries = 10
    while retries > 0:
        if strip.pingDevice():
            break
        retries -= 1
        time.sleep(1)
    else:
        print "Error connecting to device"
        sys.exit(1)

    strip.updateConfig(True)
    if int(strip.config['debug']) == 1:
        strip.toggleDebug()
    strip.setSize( int(vars['num_leds']))

    print "Starting effect"
    r = Rainbow( int(  vars['num_leds']     ),
                 int(  vars['max_intensity']),
                 float(vars['stepsize']     ))
    min_delay = float(vars['min_delay'])
    prev = time.time()
    cur = time.time()
    signal.signal(signal.SIGINT, signal_handler)
    while doIterate:
        try:
            s = strip.tryReadSerial()
            if len(s):
                print "Serial hickup, read %d bytes" % len(s)
                time.sleep(1)
            strip.pingDevice()
            cur = time.time()
            diff = cur - prev - min_delay
            if diff < 0: time.sleep(-diff)
            prev = cur
            strip.setState(r.iterate())
        except select.error, v:
            if v[0] != errno.EINTR:
                raise
            else:
                break
    strip.disconnect()
    print "Exiting"
        
if __name__ == "__main__":
    main()
