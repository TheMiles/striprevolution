import time, sys

from PyQt4.QtCore import QTimer, QSignalMapper

from PyQt4.QtGui import QWidget, QColorDialog, QDialog, QHBoxLayout, QVBoxLayout, \
    QPlainTextEdit, QFont, QLineEdit, QPushButton, QTextCursor, QApplication, \
    QGridLayout, QInputDialog, QColor, QPalette

from striplib.strip    import Strip, MAGIC
from striplib.commands import Command

# python 2.5 compatibility (i.e. N900)
if not 'bytearray' in dir(__builtins__):
    from striplib.bytearray import bytearray

class ColorChooserDialog(QColorDialog):

    def __init__(self, strip, parent=None):
        super(ColorChooserDialog,self).__init__(parent)
        self.strip      = strip
        self.nleds      = int(self.strip.config['nleds'])
        self.backupLEDs = self.strip.state()
        self.rejected.connect( self.cancel )
        self.currentColorChanged.connect( self.colorChanged )

    def cancel(self):
        self.strip.setState(self.backupLEDs)

    def colorChanged(self, color):
        if color.isValid():
            self.strip.setUnicolor( color.red(), color.green(), color.blue())
            time.sleep(0.04)

class LEDDialog(QDialog):
    rowwidth = 20
    def __init__(self, strip, parent=None):
        super(LEDDialog,self).__init__(parent)
        self.strip = strip
        self.buttons = []
        layout = QVBoxLayout()
        btnlayout = QGridLayout()
        self.btnmapper = QSignalMapper()
        for i in xrange(int(self.strip.config['nleds'])):
            p = QPushButton()
            p.setFixedWidth(40)
            p.setFlat(True)
            p.setAutoFillBackground(True)
            self.btnmapper.setMapping( p, i)
            p.clicked.connect( self.btnmapper.map)
            self.buttons += [[p,QColor()]]
            btnlayout.addWidget(p, i/self.rowwidth, i%self.rowwidth)
        self.btnmapper.mapped['int'].connect(self.chooseColor)
        layout.addLayout(btnlayout)
        ctrllayout = QHBoxLayout()
        p = QPushButton("Refresh")
        p.clicked.connect(self.refresh)
        ctrllayout.addWidget(p)
        p = QPushButton("Set")
        p.clicked.connect(self.set)
        ctrllayout.addWidget(p)
        p = QPushButton("Close")
        p.clicked.connect(self.close)
        ctrllayout.addWidget(p)
        layout.addLayout(ctrllayout)
        self.setLayout( layout)
        self.refresh()

    def refresh(self):
        tmp = self.strip.state()
        for i in xrange(len(self.buttons)):
            c = QColor(int(tmp[i*3+0]),int(tmp[i*3+1]),int(tmp[i*3+2]))
            pal = self.buttons[i][0].palette()
            pal.setBrush( QPalette.Button, QColor(c.red(),c.green(),c.blue()))
            self.buttons[i][0].setPalette(pal)
            self.buttons[i][1] = c
        
    def set(self):
        leds = []
        for b,c in self.buttons:
            leds += [ c.red(), c.green(), c.blue() ]
        self.strip.setState(leds)
        time.sleep(0.1)
        self.refresh()
        
    def chooseColor(self, i):
        if not i < len(self.buttons): return
        initial = self.buttons[i][1]
        c = QColorDialog.getColor(initial,self)
        if initial == c: return
        pal = self.buttons[i][0].palette()
        pal.setBrush( QPalette.Button, QColor(c.red(),c.green(),c.blue()))
        self.buttons[i][0].setPalette(pal)
        self.buttons[i][1] = c
        
class StripWidget(QWidget):
    timer_timeout = 100

    def __init__(self, device,speed=115200,timeout=1,debug=True):
        super(StripWidget,self).__init__()
        self.device  = device
        self.speed   = speed
        self.timeout = timeout
        self.strip       = Strip()
        self.strip.debug = debug
        self.initGUI()
        self.setInputState(False)
        self.setMinimumSize( 600, 400)
        self.timer = None
        QTimer.singleShot( 500, self.initSerial)
        
    def closeEvent(self,e):
        e.accept()
        self.closeSerial()
            
    def initSerial(self):
        if self.strip.isConnected():
            return
        if not self.device:
            self.device = self.strip.findDevice()
        if not self.device:
            self.printLog("No device found")
            return
        self.printLog("Opening '%s'" % self.device)
        if not self.strip.connect(self.device, self.speed, self.timeout):
            sys.exit(1)
        self.printLog("Opened  '%s' with speed %i" %
                      (self.device, self.strip.baudrate()))
        
        retries = 10
        while retries > 0:
            if self.strip.pingDevice():
                break
            retries -= 1
            QApplication.processEvents()
            time.sleep(1)
        else:
            print "Error connecting to device"
            sys.exit(1)
        self.printLog("Device is READY")
        self.setInputState(True)
        self.timer = self.startTimer(self.timer_timeout)
        self.updateConfig(True)
        
    def closeSerial(self):
        if self.strip.isConnected():
            self.setInputState(False)
            if self.timer:
                self.killTimer(self.timer)
            self.printLog("Disconnecting")
            self.strip.disconnect()
    
    def reconnect(self):
        self.closeSerial()
        self.initSerial()
        
    def printLog(self, s):
        if not s.endswith("\n"): s+="\n"
        self.log.moveCursor( QTextCursor.End)
        self.log.insertPlainText(s)
        self.log.moveCursor( QTextCursor.End)
        self.log.ensureCursorVisible()
    
    def initGUI(self):
        self.inputs = []
        layout = QHBoxLayout()
        
        textLayout = QVBoxLayout()
        self.log = QPlainTextEdit()
        f = QFont("Monospace")
        f.setStyleHint(QFont.TypeWriter)
        self.log.setFont(f)
        self.log.setReadOnly(True)
        textLayout.addWidget( self.log)
        self.input = QLineEdit()
        self.input.returnPressed.connect(self.sendSerial)
        self.setFocusProxy( self.input)
        textLayout.addWidget(self.input)
        self.inputs += [self.input]
        layout.addLayout( textLayout)
 
        buttonLayout = QVBoxLayout()
        p = QPushButton("Reconnect")
        p.clicked.connect(self.reconnect)
        buttonLayout.addWidget(p)
        p = QPushButton("Rainbow")
        p.clicked.connect(
            lambda: self.strip.write( bytearray( [MAGIC,Command.RAINBOW] )))
        buttonLayout.addWidget(p)
        self.inputs += [p]
        p = QPushButton("Test")
        p.clicked.connect(
            lambda: self.strip.write( bytearray( [MAGIC,Command.TEST] )))
        buttonLayout.addWidget(p)
        self.inputs += [p]
        p = QPushButton("Blank")
        p.clicked.connect(
            lambda: self.strip.write( bytearray( [MAGIC,Command.BLANK] )))
        buttonLayout.addWidget(p)
        self.inputs += [p]
        p = QPushButton("UniColor")
        p.clicked.connect( self.openUnicolor )
        buttonLayout.addWidget(p)
        self.inputs += [p]
        p = QPushButton("LED State")
        p.clicked.connect( self.getLEDState)
        buttonLayout.addWidget(p)
        self.inputs += [p]
        p = QPushButton("Conf")
        p.clicked.connect( lambda: self.updateConfig(True))
        buttonLayout.addWidget(p)
        self.inputs += [p]
        p = QPushButton("Debug")
        p.clicked.connect( self.strip.toggleDebug)
        buttonLayout.addWidget(p)
        self.inputs += [p]
        p = QPushButton("Reset")
        p.clicked.connect(
            lambda: self.strip.write( bytearray( [MAGIC,Command.RESET] )))
        buttonLayout.addWidget(p)
        self.inputs += [p]
        p = QPushButton("Set Size")
        p.clicked.connect( self.setSize)
        buttonLayout.addWidget(p)
        self.inputs += [p]
        p = QPushButton("Speed Test")
        p.clicked.connect( self.speedTest)
        buttonLayout.addWidget(p)
        self.inputs += [p]
        p = QPushButton("Free Mem")
        p.clicked.connect( self.freeMemory)
        buttonLayout.addWidget(p)
        self.inputs += [p]
        buttonLayout.addStretch(1)
        p = QPushButton("Quit")
        p.clicked.connect( self.close)
        buttonLayout.addWidget(p)
        layout.addLayout(buttonLayout)
       
        self.setLayout(layout)

    def setInputState(self,state):
        for i in self.inputs:
            i.setEnabled(state)
        if state: self.input.setFocus()
        
    def updateConfig(self, printConfig):
        self.killTimer( self.timer)
        if not self.strip.updateConfig():
            self.printLog( "Error retrieving config: " + str(self.strip.config))
        else:
            if printConfig:
                self.printLog( "Config: " + str(self.strip.config))
        self.timer = self.startTimer( self.timer_timeout)
        
    def speedTest(self):
        self.killTimer(self.timer)
        msg = self.strip.speedTest()
        if not len(msg):
            self.printLog("Error testing serial speed")
        else:
            self.printLog(msg)
        self.timer = self.startTimer(self.timer_timeout)
        
    def sendSerial(self):
        if not len(self.input.text()): return
        try:
            c = [ int(s,16) for s in str(self.input.text()).split(" ") ]
            s = bytearray( c)
            self.printLog( "Sending %s\n" % repr([hex(i) for i in s]))
            self.strip.write(s)
            self.input.selectAll()
        except ValueError:
            self.printLog( "Invalid input")
        
    def tryReadSerial(self,printData=True):
        try:
            s = self.strip.tryReadSerial()
            if printData and len(s):
                self.printLog(s)
        except:
            self.killTimer(self.timer)
            self.setInputState(False)
        
    def timerEvent(self,e):
        e.accept()
        self.tryReadSerial()

    def openUnicolor(self):
        self.killTimer(self.timer)
        debug = False
        if self.strip.config['debug'] == '1':
            self.strip.toggleDebug()
            debug = True
        d = ColorChooserDialog(self.strip,self)
        d.exec_()
        if debug: self.strip.toggleDebug()
        self.timer = self.startTimer(self.timer_timeout)

    def getLEDState(self):
        self.killTimer(self.timer)
        debug = False
        if self.strip.config['debug'] == '1':
            self.strip.toggleDebug()
            debug = True
        d = LEDDialog(self.strip,self)
        d.exec_()
        if debug: self.strip.toggleDebug()
        self.timer = self.startTimer(self.timer_timeout)

    def setSize(self):
        oldsize = int(self.strip.config['nleds'])
        maxsize = int(self.strip.config['nleds_max'])
        newsize = int(QInputDialog.getInt(
            self, "Set Size", "Enter Size (0-%d):" % maxsize, oldsize,
            0, maxsize)[0])
        self.strip.setSize(newsize)

    def freeMemory(self):
        self.killTimer( self.timer)
        self.printLog(self.strip.freeMemory())
        self.timer = self.startTimer( self.timer_timeout)
        
