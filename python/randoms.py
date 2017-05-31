#!/usr/bin/env python

import sys
import time
import math
import array
import random

import gameduino
import gameduino.remote
import gameduino.sim

from duplicator import Duplicator

random.seed(10)

def read_y(y):
    gd.wr16(gameduino.SCREENSHOT_Y, 0x8000 | y)
    gd.waitvblank()
    gd.waitvblank()
    line = "".join([gd.rdstr(gameduino.SCREENSHOT + i, 200) for i in range(0, 800, 200)])
    gd.wr16(gameduino.SCREENSHOT_Y, 0)
    return array.array('H', line).tolist()

def sling(n):
    n1s = random.randrange(n + 1)
    return sum([(1 << i) for i in random.sample(range(n), n1s)])

def r(n):
    return random.randrange(n)

def randbytes(n):
    return array.array('B', [r(256) for i in range(n)])

def matches(r):
    return r[0] == r[1]

class TestRegime(object):
    def __init__(self, dd):
        self.dd = dd
        assert matches(dd.rd(gameduino.IDENT))
        self.dd.microcode(open("../synth/sketches/j1firmware/thrasher.binle").read())
        self.setup()

    def scramble(self):
        """ Scramble all registers and memories """
        for rg in self.reg8s:
            self.dd.wr(rg, r(2**8))
        for rg in self.reg16s:
            self.dd.wr16(rg, r(2**16))
        for a,s in self.memories:
            self.dd.wrstr(a, randbytes(s))

    def setup(self):
        self.scramble()

    def cycle(self):
        for c in xrange(1000000):
            print "Cycle", c
            for (area,size) in random.sample(self.memories, r(len(self.memories))):
                dat = randbytes(1 + sling(6))
                if len(dat) == size:
                    a = area
                else:
                    a = area + random.randrange(0, size - len(dat))
                self.dd.wrstr(a, dat)
            if r(2) == 0 and self.reg16s:
                self.dd.wr16(random.choice(self.reg16s), random.getrandbits(16))
            if r(2) == 0 and self.reg8s:
                self.dd.wr(random.choice(self.reg8s), random.getrandbits(8))

            for (y, (e,a)) in [(y, self.dd.linecrc(y)) for y in self.checklines()]:
                if e != a:
                    print "mismatch at line", y, (e,a)
                    e = gameduino.sim.screen([y])[y]
                    a = read_y(y)
                    print "expected", e
                    print "actual", a
                    print set([(ee != aa) for (ee,aa) in zip(e,a)])
                    print 'y', self.dd.linecrc(y)
                    sys.exit(1)
            a,s = random.choice(self.memories)
            if r(5) == 0:
                assert matches(self.dd.rd(a + r(s)))
            if r(5) == 0:
                assert matches(self.dd.memcrc(a, s))

            if not matches(self.dd.collcrc()):
                def s9(vv):
                    vv &= 0x1ff
                    if vv > 400:
                        vv -= 512;
                    return vv

                if 0:
                    page = self.dd.spr_page()[0]
                    for i in range(256):
                        sprval = gdsim.rd32(page + 4 * i)
                        sx = s9(sprval)
                        sy = s9(sprval >> 16)
                        simg = (sprval >> 25) & 63
                        spal = (sprval >> 12) & 15
                        srot = (sprval >> 9) & 7
                        sjk = (sprval >> 31)
                        print "%3d: x=%3d y=%3d img=%2d pal=%d rot=%d jk=%d" % (i, sx, sy, simg, spal, srot, sjk)
                (e,a) = self.dd.coll()
                print 'collcrc', self.dd.collcrc()
                import binascii
                print 'e crc', 0xffffffff & binascii.crc32(array.array('B', e).tostring())
                print 'a crc', 0xffffffff & binascii.crc32(array.array('B', a).tostring())
                for i in range(256):
                    print "%3d: e=%3d a=%3d" % (i, e[i], a[i])
                sys.exit(1)
            # gdsim.im().save("p%04d.png" % c)

class FullchipRegime(TestRegime):
    reg16s = [gameduino.SCROLL_X, gameduino.SCROLL_Y, gameduino.BG_COLOR, gameduino.SAMPLE_L, gameduino.SAMPLE_R]
    reg8s = [gameduino.IDENT,
             gameduino.REV,
             gameduino.SPR_PAGE,
             gameduino.JK_MODE,
             gameduino.SPR_DISABLE,
             gameduino.IOMODE]
    memories = [
                (gameduino.RAM_PIC, 10 * 1024),
                (gameduino.RAM_SPR, 2048),
                (gameduino.RAM_SPRPAL, 2048),
                (gameduino.RAM_SPRIMG, 16384),
                (gameduino.PALETTE16A, 64),
                (gameduino.PALETTE4A, 64),
                (gameduino.VOICES, 256),
                # (gameduino.IDENT, 64), # register file
                ]
    def checklines(self):
        return [0, 299] + random.sample(range(1, 299), 2)

class SpriteRegime(TestRegime):
    reg16s = []
    reg8s = [gameduino.JK_MODE,
             gameduino.SPR_PAGE]
    memories = [
                (gameduino.RAM_SPR, 2048),
                (gameduino.RAM_SPRPAL, 2048),
                # (gameduino.RAM_SPRIMG, 16384),
                (gameduino.PALETTE16A, 64),
                (gameduino.PALETTE4A, 64),
                (gameduino.VOICES, 256),
                ]

    def setup(self):
        self.scramble()
        patt = (
            "0101010101010101"
            "1222222222222220"
            "0222222222222221"
            "1222222222222220"
            "0222222222222221"
            "1222222222222220"
            "0222222222222221"
            "1222222222222220"
            "0222222222222221"
            "1222222222222220"
            "0222222222222221"
            "1222222222222220"
            "0222222222222221"
            "1222222222222220"
            "0222222222222221"
            "1010101010101010" )
        def expand(c):
            c = int(c)
            return c + 4 * c + 16 * c + 64 * c

        image = array.array('B', [expand(c) for c in patt])
        for i in range(64):
            self.dd.wrstr(gameduino.RAM_SPRIMG + 256 * i, image);
        self.dd.microcode(open("../synth/sketches/j1firmware/thrasher.binle").read())

    def checklines(self):
        return []

def main():
    gdsim = gameduino.sim.Gameduino()
    gd = gameduino.remote.Gameduino(sys.argv[1], 115200)
    dd = Duplicator((gdsim, gd))
    # rr = SpriteRegime(dd)
    rr = FullchipRegime(dd)
    rr.cycle()

if __name__ == '__main__':
    main()
