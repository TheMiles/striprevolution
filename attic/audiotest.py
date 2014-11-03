# does not work on OSX
try:
    import alsaaudio, audioop
except:
    pass

class AudioTest:
    def __init__(self,nleds):
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
