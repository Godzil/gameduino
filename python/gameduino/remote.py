"""
gameduino.remote - remote interface
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The remote interface lets Python scripts read and write
Gameduino memory, via the USB connection and a
simple client running on the Arduino.

The remote interface can be more convenient than compiling and uploading a
Sketch when developing media and coprocessor microprograms::

    import gameduino.remote
    gd = gameduino.remote.Gameduino("/dev/ttyUSB0", 115200)
    gd.ascii()
    gd.putstr(0, 5, "Hello from Python")

The Gameduino in this module is similar to the one in :mod:`gameduino.sim`.

Because this module uses USB serial interface to communicate with the Arduino,
it requires the `PySerial module <http://pyserial.sourceforge.net/>`_.

.. image:: remote.png

The Arduino runs a simple program ``memloader`` that
listens for serial commands and accesses Gameduino memory.
"""

import struct
import serial
import time
import array

from gameduino.registers import *
from gameduino.base import BaseGameduino

class Gameduino(BaseGameduino):

    def __init__(self, usbport, speed):
        self.ser = serial.Serial(usbport, speed)
        time.sleep(2)
        assert self.rd(IDENT) == 0x6d, "Missing IDENT"
        self.mem = array.array('B', [0] * 32768)
        self.coldstart()

    def wrstr(self, a, s):
        if not isinstance(s, str):
            s = s.tostring()
        self.mem[a:a+len(s)] = array.array('B', s)
        for i in range(0, len(s), 255):
            sub = s[i:i+255]
            ff = struct.pack(">BH", len(sub), 0x8000 | (a + i)) + sub
            self.ser.write(ff)

    def rd(self, a):
        """ Read byte at address ``a`` """
        ff = struct.pack(">BH", 1, a)
        self.ser.write(ff)
        return ord(self.ser.read(1))

    def rdstr(self, a, n):
        """
        Read ``n`` bytes starting at address ``a``

        :rtype: string of length ``n``.
        """
        r = ""
        while n:
            cnt = min(255, n)
            ff = struct.pack(">BH", cnt, a)
            self.ser.write(ff)
            r += self.ser.read(cnt)
            a += cnt
            n -= cnt
        return r

    def waitvblank(self):
        while self.rd(VBLANK) == 1:
            pass
        while self.rd(VBLANK) == 0:
            pass

    def linecrc(self, y):
        self.ser.write(struct.pack(">BBH", 0, ord('L'), y))
        return struct.unpack(">L", self.ser.read(4))[0]

    def coll(self):
        """
        Return the 256 bytes of COLLISION RAM.

        :rtype: list of byte values.
        """
        self.ser.write(struct.pack(">BB", 0, ord('c')))
        return array.array('B', self.ser.read(256)).tolist()

    def collcrc(self):
        self.ser.write(struct.pack(">BB", 0, ord('C')))
        return struct.unpack(">L", self.ser.read(4))[0]

    def memcrc(self, a, s):
        self.ser.write(struct.pack(">BBHH", 0, ord('M'), a, s))
        return struct.unpack(">L", self.ser.read(4))[0]

    def _im(self):
        """
        Return the current screen as a 400x300 RGB PIL Image::

            >>> import gameduino.sim
            >>> gd = gameduino.sim.Gameduino()
            >>> gd.im().save("screenshot.png")
        """
        import Image
        fi = Image.new("RGB", (400,300))
        for y in range(300):
            self.wr16(SCREENSHOT_Y, 0x8000 | y)
            while (self.rd16(SCREENSHOT_Y) & 0x8000) == 0:
                pass
            ld = array.array('H', self.rdstr(SCREENSHOT, 800))
            r = [8 * (31 & (v >> 10)) for v in ld]
            g = [8 * (31 & (v >> 5)) for v in ld]
            b = [8 * (31 & (v >> 0)) for v in ld]
            rgb = sum(zip(r,g,b), ())
            li = Image.fromstring("RGB", (400,1), array.array('B', rgb).tostring())
            fi.paste(li, (0, y))
        self.wr16(SCREENSHOT_Y, 0)
        return fi


import array
def readarray(filename):
    return array.array('B', open(filename).read())
