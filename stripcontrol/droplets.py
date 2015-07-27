#!/usr/bin/env python

import colorsys, math, sys, time, os, select, errno, random, numpy, scipy.signal

from striplib.strip import Strip

parameters = {"hue-min": 0.0,
	"hue-max": 1.0,
	"hue-shift": 0.0,
	"saturation": 1.0,
	"probability": 0.07}

def set(params):
    print params
    global parameters
    parameters.update(params)

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
	self.initial_colors = numpy.array([0, 0, 0] * self.nleds)
	self.time = time.time()

    def iterate(self):
	global parameters
	p = parameters

        colors = numpy.copy(self.initial_colors)
        if random.random() < p["probability"]:
#        if not self.droplets:
            center = random.randint(0, self.nleds - 1)
            width = random.randint(3, 8)
            hue = random.random() * (p["hue-max"] - p["hue-min"]) + p["hue-min"] + p["hue-shift"]
            hue = [hue, hue - 1][hue > 1]
            time_to_live = random.randint(20, 100)
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
                rgb = numpy.array(colorsys.hsv_to_rgb(droplet.hue, p["saturation"], val))**2.2 * 255
                idx = (pos + i) * 3
                colors[idx:idx + 3] += rgb

        for idx in sorted(garbage, reverse=True):
            self.droplets.pop(idx)
            
        msg = [abs(min(c, 255)) for c in colors]
        return bytearray(msg)


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
    strip.setSize( int(args.num_leds))

    print "Starting effect"
    r = Droplets(int(args.num_leds),
                 float(args.probability))
    min_delay = float(args.min_delay)
    prev = time.time()
    cur = time.time()
    while True:
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
