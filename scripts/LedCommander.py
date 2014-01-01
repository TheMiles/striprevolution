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


COMMAND_CONF = 0x67
COMMAND_DEBUG = 0x68


class LedCommander:
    """
    Send commmands to strip
    """
    
    def __init__(self,port):
        self.port = port
        self.conn = None
        self.speed = 9600    
        self.numleds = 5
        self.connect()
        Thread(target=self.receiveData).start()
        self.buffer=""
        
    def close(self):
        if ( self.conn != None):
            self.conn.close()


    def receiveData(self):

        print "Started Thread"
        while True:
            if ( self.conn == None):
                print "Connection Error"
                return

            buffer = ""


            try:
                buffer += self.conn.read(self.conn.inWaiting())
                buffer_list = buffer.split('\n')
                
                buffer = buffer_list[-1]
                
                print len(buffer)
                self.buffer = buffer
                #line = self.conn.readline()
                #mystr = "".join(map(chr, line))
                
            except Exception, e:
                print e
                print "Could not get config"
                pass

        
    def connect(self):
        print "connect"
        
        if ( self.conn != None):
            self.conn.close()

        try:
            self.conn = serial.Serial(self.port, self.speed)
            print "Connected"
        except serial.serialutil.SerialException, e:
            print e
            self.conn = None
            pass

        time.sleep(2) # see http://playground.arduino.cc/Interfacing/Python
        print "Waiting for serial port"
        if  self.conn != None:
            msg=[0x42, COMMAND_CONF]

            try:
                #print bytearray(msg)
                numwrite = self.conn.write(bytearray(msg))
                self.conn.flush()
                
            except Exception, e:
                print e
                print "Could not send COMMAND_CONF"
                pass
            
                

        return self.conn != None

    

    def sendCommand(self, command):
        if self.conn == None:
            return

        msg =[ 0x42, command]
        try:
            numwrite = self.conn.write(bytearray(msg))
            #self.conn.flush()
        except Exception,e :
            print e
            print "Could not send %s" % command
            pass
            
            
                
    
    
if __name__ == "__main__":
    ledc = LedCommander("/dev/ttyUSB0")
    ledc.connect()
    ledc.sendCommand(COMMAND_DEBUG)
    while True:
        time.sleep(1)
        print "Loop"
        msg=[0x42, COMMAND_CONF]
        numwrite =ledc.conn.write(bytearray(msg))
    
    ledc.close()
