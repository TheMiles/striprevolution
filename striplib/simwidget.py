from striplib.strip    import Strip, MAGIC
from striplib.commands import Command

from PyQt4.QtGui import QWidget, QGridLayout, QLabel, QApplication

class SimWidget(QWidget):
    def __init__(self, args):
        super(SimWidget,self).__init__()

        self.nleds     = args.nleds
        self.ncols     = args.ncols
        self.nrows     = args.nrows
        self.maxwidth  = args.width
        self.maxheight = args.height

        if self.maxwidth == -1 or self.maxheight == -1:
            d = QApplication.desktop()
            r = d.availableGeometry()
            if self.maxwidth == -1:
                self.maxwidth = r.width()
            if self.maxheight == -1:
                self.maxheight = r.height()

        self.ledwidth = self.maxwidth / (2*self.ncols-1)

        if args.debug: self.print_vars()
        
        self.leds = []
        self.setStyleSheet("* { background-color : black; }")
        self.initLEDs()

    def initLEDs(self):
        l = QGridLayout(self)
        l.setContentsMargins( 0,0,0,0)
        l.setHorizontalSpacing(self.ledwidth)
        for row in xrange(self.nrows):
            for col in xrange(self.ncols):
                label = QLabel()
                label.setFixedSize(self.ledwidth, self.ledwidth)
                label.setStyleSheet("* { background-color : red; }")
                label.show()
                self.leds.append(label)
                l.addWidget(label,row,col)
        self.setLayout(l)

    def print_vars(self):
        for k,v in self.__dict__.items():
            print k, v
