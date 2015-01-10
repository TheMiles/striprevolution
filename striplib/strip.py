import os, serial, sys, time

from striplib.commands import Command

MAGIC = 0x42

class Strip(object):
    def __init__(self):
        self.conn = None
        self.debug = False
        self.config = {}
        
    def findDevice(self):
        ports = sorted([ os.path.join('/dev', d)
                         for d in os.walk("/dev").next()[2]
                         if d.startswith('tty.usbserial') or
                         d.startswith('ttyUSB') or
                         d.startswith('tty.usbmodem') or
                         d.startswith('ttyAMA') ],reverse=True)
        if os.path.exists('vmodem0'):
            ports = ['vmodem0'] + ports
        return ports[0] if len(ports) else None

    def connect(self,device=None,speed=115200,timeout=1):
        if self.conn:
            self.conn.close()
        
        if not device:
            device = self.findDevice()
            if not device:
                return False
        try:
            self.conn = serial.Serial(device, speed, timeout=timeout)
        except serial.serialutil.SerialException, e:
            print e
            return False
        if not self.conn:
            return False
        
        return True
        
    def disconnect(self):
        if not self.isConnected():
            return
        self.write( bytearray( [MAGIC, Command.BLANK] ))
        self.conn.close()
        self.conn = None
     
    def isConnected(self):
        return not (self.conn == None)

    def pingDevice(self):
        self.write( bytearray( [MAGIC, Command.PING] ))
        #time.sleep(0.1)
        #avail = self.conn.inWaiting()
        #if avail and self.conn.read(avail) == "0":
        if self.conn.read(1) == "0":
            return True
        return False
        
    def write(self, array, debug=False):
        if self.debug:
            print "Sending",
            for i in array:
                print hex(i),
            print
        self.conn.write(array)
        
    def baudrate(self):
        return self.conn.baudrate if self.conn else 0

    def updateConfig(self, printConfig=False):
        self.write( bytearray( [MAGIC,Command.CONF] ))
        time.sleep(0.5)
        config = ""
        avail = self.conn.inWaiting()
        while avail > 0:
            config += self.conn.read(avail)
            time.sleep(0.1)
            avail = self.conn.inWaiting()
        try:
            d = dict([ i.strip().split(':')
                       for i in config.strip().split('\n') ])
            self.config = dict([ (k.strip(), v.strip())
                                 for k,v in d.iteritems() ])
            if printConfig: print "Config: " + str(self.config)
            return True
        except:
            print "Error retrieving config:", config
        
        return False

    def toggleDebug( self):
        self.write( bytearray( [MAGIC,Command.DEBUG] ))
        time.sleep(0.1)
        self.tryReadSerial()
        self.updateConfig()

    def tryReadSerial(self):
        s = ''
        try:
            bytesRead = 0
            while True:
                avail = self.conn.inWaiting()
                if not avail > 0:
                    break
                s += self.conn.read(avail)
                bytesRead += avail
                if s.endswith('\r\n'):
                    break
            if self.debug and bytesRead > 0:
                print "Read %d bytes" % bytesRead
                print repr(s)
        except:
            self.disconnect()
            raise
        return s

    def setSize(self,newsize):
        oldsize = int(self.config['nleds'])
        maxsize = int(self.config['nleds_max'])
        if oldsize == newsize: return
        cmd = [MAGIC,Command.SETSIZE]
        if maxsize > 255:
            cmd += [ (newsize >> 8) & 0xff, newsize & 0xff ]
        else:
            cmd += [ newsize ]
        self.write( bytearray(cmd))
        self.config['nleds'] = str(newsize)

    def freeMemory(self):
        self.write( bytearray([MAGIC,Command.MEMFREE]))
        time.sleep(0.1)
        s = ""
        avail = self.conn.inWaiting()
        while avail > 0:
            s += self.conn.read(avail)
            avail = self.conn.inWaiting()
        return s

    def speedTest(self):
        start = time.time()
        counter = 0
        self.write( bytearray( [MAGIC,Command.PING] ))
        c = self.conn.read()
        if c != "0":
                return ""
        while counter < 1000:
            self.write( bytearray( [MAGIC,Command.PING] ))
            self.conn.read()
            counter += 1
        stop = time.time()
        elapsed = stop-start
        return "%.4f seconds per call (%.2f kHz)" % (elapsed/1.e3,1./elapsed)

    def state(self):
        nleds = int(self.config['nleds'])
        self.write( bytearray( [MAGIC,Command.STATE]))
        time.sleep(0.1)
        avail = self.conn.inWaiting()
        tmp = ''
        while avail > 0:
            tmp += self.conn.read(avail)
            avail = self.conn.inWaiting()
        if len(tmp) != nleds*3:
            print "LED strip length mismatch: got %d, need %d" % \
                (len(tmp), nleds*3)
            return [0] * nleds * 3
        return bytearray(tmp)

    def setState(self, leds):
        nleds = int(self.config['nleds'])
        if nleds != len(leds)/3:
            print "WARNING: trying to set %d of %d LEDs" % (nleds,len(leds)/3)
        nleds = min(nleds,len(leds)/3)
        cmd = [MAGIC,Command.COLOR]
        maxleds = int(self.config['nleds_max'])
        if maxleds > 255:
            cmd += [ nleds >> 8, nleds & 0xff ]
        else:
            cmd += [ nleds ]
        cmd += leds
        self.write( bytearray( cmd))

    def setUnicolor(self, red, green, blue):
        cmd = [ MAGIC, Command.UNICOLOR, red, green, blue ]
        self.write( bytearray( cmd ) )
