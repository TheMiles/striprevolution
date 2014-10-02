#!/usr/bin/env python

import colorsys, math, serial, signal, sys, time, os

# does not work on OSX
try:
    import alsaaudio, audioop
except:
    pass

speed = 9600

ports = ["/dev/ttyUSB0","/dev/tty.usbserial-A4006Fho"]

num_leds=5
max_intensity=0xf
# iteration_delay=1/50.
iteration_delay=1/20.
stepsize=math.pi/32.

def sinus( v, phase ):

    return map( lambda i: int( math.pow( math.sin( phase + i * stepsize * 2), 2 ) * 255.5 ), v )


def clamp( v, max_value , min_value ):

    return map( lambda x: max( min_value, min( max_value, x )), v )



class Rainbow:
    def __init__(self,max,nleds):
        self.max   = max
        self.nleds = nleds
        self.hsv   = [0,1,1]
        self.stepsize=math.pi/64.
    
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
        msg = [0x42, 0x01, chr( self.nleds )]
        for i in val:
            msg += [ int(j*self.max)
                     for j in colorsys.hsv_to_rgb(i, *(self.hsv[1:3]))]
        return bytearray(msg)

class AudioTest:
    def __init__(self,max,nleds):
        self.max   = max
        self.nleds = nleds
        self.inp = alsaaudio.PCM(alsaaudio.PCM_CAPTURE,alsaaudio.PCM_NONBLOCK)
        self.inp.setchannels(1)
        self.inp.setrate(8000)
        self.inp.setformat(alsaaudio.PCM_FORMAT_S16_LE)   
        self.inp.setperiodsize(160)
        self.decay = 0.05
        self.val = 0
        self.audioMin = 1
        self.audioMax = 0


    def iterate(self):
        # Read data from device
        l,data = self.inp.read()
        while not l:
            time.sleep(.001)
            l,data = self.inp.read()
            print type(data)
        val = float(audioop.max(data, 2))
        if val < self.audioMin: self.audioMin = val
        if val > self.audioMax: self.audioMax = val
        mid = (self.audioMin+self.audioMax)/2
        wid = self.audioMax-self.audioMin
        if wid < 1e-6:
            wid = 1
        val = (val-mid)/wid+0.5
        if val > self.val: self.val = val
        msg = [0x42, 0x02]
        for i in xrange(3):
            msg += [ int(self.val*self.max) ]
        self.val -= self.decay
        return bytearray(msg)


doIterate = True
def signal_handler(signal, frame):
    print "Caught SIGINT, stopping"
    globals()['doIterate'] = False

def main():
    conn = None

    port = next( p for p in ports if os.path.exists(p) )
    try:
        print "Opening '%s'" % port
        conn = serial.Serial(port, speed, timeout=1)
        time.sleep(0.1)
    except serial.serialutil.SerialException, e: print e
    if not conn: sys.exit(1)
    print "Starting effect"
    r = Rainbow( max_intensity, num_leds)
    #r = AudioTest( 0x5F, 5)
    
    signal.signal(signal.SIGINT, signal_handler)
    while doIterate:
        avail = conn.inWaiting()
        if avail > 0:
            print "Reading %d bytes" % avail
            print conn.read(avail)
        conn.write(r.iterate())
        time.sleep(iteration_delay)
    print "Sending COMMAND_RESET"
    conn.write( bytearray( [0x42, 0x69] ))
    print "Exiting"
        
if __name__ == "__main__":
    main()
