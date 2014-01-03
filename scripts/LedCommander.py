#!/usr/bin/env python
##########################################################################
#       Title:
#    $RCSfile: abbrev_defs,v $
#   $Revision: 1.1 $$Name:  $
#       $Date: 2008/05/26 15:44:44 $
#   Copyright: $Author: ckeller $
# Description:
#
#
#
#------------------------------------------------------------------------
#
#  $Log: abbrev_defs,v $
#
#
##########################################################################


import serial, sys, time
from threading import Thread, Lock
import random

COMMAND_COLOR        =  0x1
COMMAND_CONF         = 0x67
COMMAND_DEBUG        = 0x68

      

class LedColor:
    """
    Represents the LED Color
    """
    def __init__(self, rgb = (255,100,0)):
        self.rgb = rgb

    def getString(self):
        msg = self.rgb
        return bytearray(msg)


class LedStripe:

    def __init__(self,numel):
        self.numel = numel
        self.leds =[]
        for i in range(numel):
            self.leds.append(LedColor())
        
    def getString(self):
        msg = [ COMMAND_COLOR, self.numel]
        msg = bytearray(msg)
        for i in self.leds:
            msg += i.getString()
        return msg
        
    
class LedCommander:
    """
    Send commmands to strip
    """
    
    def __init__(self,port):
        self.port = port
        self.conn = None
        self.speed = 9600    
        self.numleds = None

        self.ALLSTATES = { 'INIT': 1 ,
                           'CONNECTED': 2,
                           'CONFIGOK' : 3,
                           'CONFIGERROR' : 4}
        self.STATE = self.ALLSTATES['INIT']
        
        self.connect()
        Thread(target=self.receiveData).start()
        self.buffer=""
        self.mutex_buffer = Lock()

        self.ledstripe = None

        
    def close(self):
        if ( self.conn != None):
            self.conn.close()


    def receiveData(self):
        """
        Background thread polling the data
        """
        print "Started Thread"
        while True:
            if ( self.conn == None):
                print "Connection Error"
                return

            try:
                line = self.conn.readline()
                if (len(line) > 0):
                    self.mutex_buffer.acquire()
                    self.buffer = line
                    self.mutex_buffer.release()

                print line
                    
            except Exception, e:
                print e
                print "Could not get config"
                pass

        
    def connect(self):
        """
        Open serial port and send config command
        """
        
        print "connect"
        
        if ( self.conn != None):
            self.conn.close()

        try:
            self.conn = serial.Serial(self.port, self.speed)
            self.STATE = self.ALLSTATES['CONNECTED']
            print "Connected"
        except serial.serialutil.SerialException, e:
            print e
            self.conn = None
            pass
        
        time.sleep(2) # see http://playground.arduino.cc/Interfacing/Python
        print "Waiting for serial port"
        return self.conn != None


    def getConfig(self):
       """
       Send the config command and wait until we go the parameters
       """
       if self.STATE != self.ALLSTATES['CONNECTED'] :
           self.STATE = self.ALLSTATES['CONFIGERROR']
           return False

       # wait until the config has been received
       while self.STATE != self.ALLSTATES['CONFIGOK']:
           print "Waiting for config"
           line = ""
           self.sendCommand(COMMAND_CONF)
           time.sleep(1)
           self.mutex_buffer.acquire()
           line = self.buffer
           self.mutex_buffer.release()
           print line

           # Now check if we got the config
           if line.startswith('#NUMLEDS'):
               idx = line.find("=")
               self.numleds = int(line[idx+1])
               print self.numleds
               self.STATE = self.ALLSTATES['CONFIGOK']
               self.ledstripe = LedStripe(self.numleds)
               return True

    def show(self):
        if self.conn == None:
            return
        msg =bytearray([0x42])
        msg += self.ledstripe.getString()
        self.conn.write(msg)        


        
    def sendCommand(self, command):
        """
        Send the command
        note: the magic byte is added
        """
        if self.conn == None:
            return

        msg =bytearray([0x42, command])
        try:
            numwrite = self.conn.write(msg)
            #self.conn.flush()
        except Exception,e :
            print e
            print "Could not send %s" % command
            pass
            
            
                
    
    
if __name__ == "__main__":

    import signal
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    signal.signal(signal.SIGTERM, signal.SIG_DFL)

    ledc = LedCommander("/dev/ttyUSB0")
    ledc.connect()
    ledc.getConfig()
    time.sleep(1)
    ledc.show()
    #ledc.sendCommand(COMMAND_DEBUG)
    while False:
        time.sleep(0.2)
        print "Loop"
        for i  in range(ledc.numleds):

            cur_col = []
            for c in range(3):
                cur_col.append( int(random.random()*100) % 255)
            
            lc = LedColor(cur_col)
            ledc.ledstripe.leds[i]= lc 
        
        ledc.show()
        
        #ledc.sendCommand(COMMAND_DEBUG)
        
    ledc.close()
