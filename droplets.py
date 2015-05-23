#!/usr/bin/env python

import colorsys, math, signal, sys, time, os, select, errno, random, numpy, scipy.signal

from striplib.strip import Strip

# python 2.5 compatibility (i.e. N900)
if not 'bytearray' in dir(__builtins__):
    import array
    def bytearray( bytelist):
        return array.array('b',bytelist)


class Droplet(object):
    def __init__(self, hue, center, radius, time_to_live):
        self.hue = hue
        self.center = center
        self.radius = radius
        self.time_to_live = time_to_live
        self.valid = True
        self.values = scipy.signal.gaussian(radius * 2 + 1, radius / 2.0)
        self.iteration = 0

    def fade(self):
        v = float(self.iteration) / self.time_to_live
        scaling = 0.5 - abs(v - 0.5)

        if not self.valid:
            scaling = 0
            
        values = self.values * scaling

        self.iteration += 1
        if self.iteration == self.time_to_live:
            self.valid = False
        return values

    def begin(self):
        return self.center - self.radius

    def end(self):
        return self.center + self.radius + 1

        
class Droplets(object):

    def __init__(self, nleds, probability):
        self.nleds = nleds
        self.probability = probability
        self.droplets = []

    def iterate(self):

        colors = numpy.array([0, 0, 0] * self.nleds)

        if random.random() < self.probability:
            center = random.randint(0, self.nleds - 1)
            width = random.randint(3, 8)
            hue = random.random()
            time_to_live = random.randint(20, 150)
            self.droplets.append(Droplet(hue, center, width, time_to_live))
        
        garbage = list()
        for idx, droplet in enumerate(self.droplets):
            if not droplet.valid:
                garbage.append(idx)
            
            values = droplet.fade()
            pos = droplet.begin()
            if pos < 0:
                values = numpy.copy(values[abs(pos):])
                pos = 0
            if droplet.end() > self.nleds:
                values = numpy.copy(values[:-(droplet.end() - self.nleds)])

            if numpy.empty(values):
                continue

            for i, val in enumerate(values):
                rgb = numpy.array(colorsys.hsv_to_rgb(droplet.hue, 1, val))**2.2 * 255
                idx = (pos + i) * 3
                colors[idx:idx + 3] += rgb

        for idx in garbage:
            self.droplets.pop(idx)
            
        msg = [abs(min(c, 255)) for c in colors]
        return bytearray(msg)

doIterate = True
def signal_handler(signal, frame):
    global doIterate
    doIterate = False
    print "Caught SIGINT, stopping"

def main():
    import argparse
    parser = argparse.ArgumentParser(description='Animate colors.')
    parser.add_argument('device', type=str, default=None, nargs='?',
                        help='serial device')
    parser.add_argument('--speed', type=int, default=115200,
                        help='serial port baud rate')
    parser.add_argument('--timeout', type=int, default=1,
                        help='serial port timeout')
    parser.add_argument('--min_delay', type=float, default=1/20.,
                        help='minimum delay in seconds')
    parser.add_argument('--num_leds', type=int, default=5,
                        help='number of leds')
    parser.add_argument('--probability', type=float, default=0.5,
                        help='probablity for new droplet per iteration')
    args = parser.parse_args()
    size = max( [ len(arg) for arg in vars(args).keys() ])
    for name,val in vars(args).items():
        name = name.ljust(size)
        if isinstance(val,float):
            print "%s: %.3f" % (name,val)
        else:
            print "%s: %s"   % (name,val)
    print
    
    port = args.device
    strip = Strip()
    if not port:
        port = strip.findDevice()
    if not port:
        print "No device found"
        sys.exit(1)

    print "Opening '%s'" % port
    if not strip.connect(port, speed=args.speed, timeout=args.timeout):
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
    strip.setSize( int(args.num_leds))

    print "Starting effect"
    r = Droplets(int(args.num_leds),
                 float(args.probability))
    min_delay = float(args.min_delay)
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
