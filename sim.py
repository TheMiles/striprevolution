#!/usr/bin/env python

import sip
# avoid QTextStream::hex shadowing built-in function
sip.setapi('QTextStream',2)
from PyQt4.QtGui import QApplication

import argparse, os, serial, sys, time, math

from striplib.simwidget   import SimWidget

def main():
    a = QApplication(sys.argv)

    parser = argparse.ArgumentParser(description='striprevolution strip simulator')
    parser.add_argument('--port', type=int, default=7777,
                        help='server tcp port')
    parser.add_argument('--nleds', type=int, default=5,
                        help='number of leds')
    parser.add_argument('--nrows', type=int, default=1,
                        help='number of rows')
    parser.add_argument('--ncols', type=int, default=-1,
                        help='number of cols')
    parser.add_argument('--width', type=int, default=-1,
                        help='width')
    parser.add_argument('--height', type=int, default=-1,
                        help='height')
    parser.add_argument('--debug',  action='store_true',
                        help='enable debug output')
    args = parser.parse_args()

    if args.ncols == -1:
        if args.nrows == 1:
            args.ncols = args.nleds
        else:
            args.ncols = int(math.ceil(args.nleds / args.nrows))

    w = SimWidget(args)
    w.show()

    return a.exec_()

if __name__ == '__main__':
    import signal
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    main()
