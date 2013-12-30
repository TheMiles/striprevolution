import colorsys, math,serial, sys, time
import alsaaudio, time, audioop

speed = 9600
port = "/dev/ttyUSB0"

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
        msg = [0x42, 0x01, 0x05]
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

def main():
    conn = None
    try:
        conn = serial.Serial(port, speed, timeout=0,
                             stopbits=serial.STOPBITS_ONE)
    except serial.serialutil.SerialException, e: print e
    if not conn: sys.exit(1)
    #r = Rainbow( 0x5F, 5)
    r = AudioTest( 0x5F, 5)
    while True:
        conn.write(r.iterate())
        time.sleep(1/50.)
        
if __name__ == "__main__":
    main()
