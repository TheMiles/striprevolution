#!/usr/bin/env python

import colorsys, math, serial, signal, sys, time, os, select, errno

# python 2.5 compatibility (i.e. N900)
if not 'bytearray' in dir(__builtins__):
    import array
    def bytearray( bytelist):
        return array.array('b',bytelist)

speed = 115200

args = [
    ('num_leds',      5),
    ('max_intensity', 0xf),
    ('min_delay',     1/20.),
    ('stepsize',      math.pi/256.),
]

MAGIC = 0x42

# import command codes from Commands.h
command = None
if not os.path.exists('Commands.h'):
    print "Commands.h not found"
    sys.exit(0)
else:
    f = open('Commands.h')
    commands = {}
    for line in f:
        if line.startswith("#define COMMAND_"):
            tmp, cmd, byte = line.split()
            cmd = cmd[cmd.find('_')+1:]
            commands[cmd] = int(byte,16)
    command = type('Command', (object,), commands)

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
        msg = [MAGIC, 0x01, self.nleds]
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
    
    conn = None
    ports = sorted([ os.path.join('/dev', d)
                     for d in os.walk("/dev").next()[2]
                     if d.startswith('tty.usbserial') or
                     d.startswith('ttyUSB') or
                     d.startswith('ttyAMA') ])
    if os.path.exists('vmodem0'):
        ports = ['vmodem0'] + ports
    port = ports[0] if len(ports) else None
    if not port:
        print "No device found"
        sys.exit(1)

    try:
        print "Opening '%s'" % port
        conn = serial.Serial(port, speed)
        retries = 10
        while retries > 0:
            conn.write( bytearray( [MAGIC,command.PING] ))
            time.sleep(0.1)
            avail = conn.inWaiting()
            if avail and conn.read(avail) == "0":
                break
            retries -= 1
            time.sleep(1)
        else:
            conn.close()
            print "Device is not READY, exiting"
            sys.exit(1)
    except serial.serialutil.SerialException, e: print e
    if not conn: sys.exit(1)
    
    # set number of leds
    conn.write(bytearray( [MAGIC, command.SETSIZE, int(vars['num_leds']) ]))
    
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
            avail = conn.inWaiting()
            if avail > 0:
                s = conn.read(avail)
                print "Serial hickup, read %d bytes" % avail
                #print repr(s)
                time.sleep(1)
            conn.write(bytearray( [MAGIC, command.PING] ))
            conn.read()
            cur = time.time()
            diff = cur - prev - min_delay
            if diff < 0: time.sleep(-diff)
            prev = cur
            conn.write(r.iterate())
        except select.error, v:
            if v[0] != errno.EINTR:
                raise
            else:
                break
    print "Sending COMMAND_RESET"
    conn.write( bytearray( [MAGIC, command.RESET] ))
    conn.close()
    print "Exiting"
        
if __name__ == "__main__":
    main()
