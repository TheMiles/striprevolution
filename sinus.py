import colorsys, math,serial, sys, time

speed = 9600
port = "/dev/ttyUSB0"
max=0x5F
conn = None
try:
    conn = serial.Serial(port, speed, timeout=0, stopbits=serial.STOPBITS_ONE)
except serial.serialutil.SerialException, e:
    print e
if not conn:
    sys.exit(1)
stepsize=math.pi/32.
x=0
while True:
    #v = [ int(abs( math.sin(x+i*stepsize*2))*max) for i in xrange(5) ]
    v = [ int(math.pow( math.sin(x+i*stepsize*2),2)*0xF) for i in xrange(5) ]
    x+=stepsize
    if x > 2*math.pi: x -= 2*math.pi
    #msg = [0x42, 0x02] + 3*[int(v*v*0xFF)]
    msg = [0x42, 0x01, 0x05]
    for i in v:
        msg += [0, i, 0]
    conn.write( bytearray(msg))
    time.sleep(1/32.)
