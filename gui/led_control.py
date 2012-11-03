#!/usr/bin/python -tt
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import os, sys

import serial
import time

from gi.repository import Gtk
from gi.repository import Gdk
from gi.repository import GObject

from threading import Thread, Lock

GObject.threads_init()

SPEED = 9600



class MainWindow:
    
    def __init__(self):

        self.enabled_modules = []
        self.channel_values = {}

        self.builder = Gtk.Builder()
        self.builder.add_from_file(os.path.join(os.getcwd(), 'data/led_control.ui'))
        self.builder.connect_signals(self)

        self.quitting = False

        channel = 0
        while True:
            try:
                adj = self.builder.get_object('channel_%i' % channel)
                adj.channel = channel
                channel += 1
            except:
                break
        
        module_offset = 0
        while True:
            try:
                cb = self.builder.get_object('module_%i' % module_offset)
                cb.module_offset = module_offset
                module_offset += 1
            except:
                break

        self.connect_serial(self.builder.get_object('button1'))


        self.channel_values_lock = Lock()
        Thread(target=self.update_poller).start()
        Thread(target=self.receive_data).start()
        
        self.window = self.builder.get_object('window1')
        self.window.show()

    def module_enable_changed(self, cb):

        is_enabled = cb.get_active()
        module_offset = cb.module_offset

        if( is_enabled ):
            self.enabled_modules.append( module_offset )
        else:
            self.enabled_modules.remove( module_offset )


    def channel_changed(self, channel, value):

        message = "c%iv%i" % (channel, value)
        self.send_command( message )


    def adjustment_changed(self, adjustment):

        if( self.channel_values_lock.acquire() ):
            for offset in self.enabled_modules:
                current_channel = offset * 3 + adjustment.channel
                current_value   = adjustment.get_value()
                if current_value > 0:
                    current_value   = ((current_value/adjustment.get_upper())**(2.2)) * adjustment.get_upper()
                self.channel_values[ current_channel ] = current_value
            self.channel_values_lock.release()


    def update_poller(self):

        while True:
            time.sleep(0.01)

            if self.quitting:
                break
            if self.connection:
                if( self.channel_values_lock.acquire(False) ):
                    for channel, value in self.channel_values.iteritems():
                        self.channel_changed( channel, value )
                    self.channel_values = {}
                    self.channel_values_lock.release()
                    

        
    def connect_serial(self, button):

        controls = self.builder.get_object('grid1').get_children()
        def set_sensitive(sensitive):
            for c in controls:
                c.set_sensitive(sensitive)


        def disconnect():
            button.set_label("Connect")
            set_sensitive(False)
            self.connection = None

        if button.get_label() == "Disconnect":
            disconnect()
            return

        try:
            port = self.builder.get_object('serialPort').get_text()
            self.connection = serial.Serial(port, SPEED, timeout=0, stopbits=serial.STOPBITS_ONE)
            button.set_label("Disconnect")
            set_sensitive(True)
        except serial.serialutil.SerialException, e:
            disconnect()
            print e
        

    def quit(self, *args):
        self.connection = None
        self.quitting = True
        Gtk.main_quit()

    def send_command(self, val):
        self.connection.write(val)

    def receive_data(self):

        buffer = ""
        while True:
            if self.connection:
                buffer += self.connection.read(self.connection.inWaiting())
                buffer_list = buffer.split('\n')
                for line in map(lambda x: x.replace("\r", ""), buffer_list[:-1]):
                    GObject.idle_add(self.update_data_buffer, line)
                    print line
                buffer = buffer_list[-1]
            if self.quitting:
                break


    def update_data_buffer(self, data):

        textview = self.builder.get_object('textview1')
        data_buffer = Gtk.TextBuffer()
        textview.set_buffer(data_buffer)
        scrollbar = self.builder.get_object('scrolledwindow1').get_vadjustment()

        data_buffer.insert(data_buffer.get_end_iter(), data)
        #scrollbar.set_value(scrollbar.upper - scrollbar.page_size)


if __name__ == '__main__':

    import signal
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    signal.signal(signal.SIGTERM, signal.SIG_DFL)

    MainWindow()
    Gtk.main()
    
