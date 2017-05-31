"""
gameduino.sim - simple simulator
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The Gameduino simulator can simulate some aspects of Gameduino hardware, both video and audio.
It can be a useful tool for previewing media before loading on actual hardware.

The Gameduino in this module is similar to the one in :mod:`gameduino.remote`::

    import gameduino
    import gameduino.prep as gdprep
    import gameduino.sim as gdsim

    im = Image.open("platformer.png").convert("RGB")
    (picd,chrd,pald) = gdprep.encode(im)
    gd = gdsim.Gameduino()
    gd.wrstr(gameduino.RAM_PIC, picd)
    gd.wrstr(gameduino.RAM_CHR, chrd)
    gd.wrstr(gameduino.RAM_PAL, pald)
    gd.im().save("preview.png")

The simulator can produce screenshots (:meth:`Gameduino.im`), generate
single-note sounds (:meth:`Gameduino.writewave`), and simulate collision RAM
(:meth:`Gameduino.coll`).  It does not currently simulate the coprocessor.

"""

import struct
import time
import array
import math
import itertools
import wave
import binascii

import Image

from gameduino.registers import *
from gameduino.base import BaseGameduino

def sum512(a, b):
    return 511 & (a + b)
def s9(vv):
    vv &= 0x1ff
    if vv > 400:
        vv -= 512;
    return vv
        
class Gameduino(BaseGameduino):
    """
    The Gameduino object simulates some aspects of the Gameduino hardware.  For example::

        >>> import gameduino
        >>> import gameduino.sim as gdsim
        >>> gd = gdsim.Gameduino()
        >>> print hex(gd.rd(gameduino.IDENT))
        0x6d
    """

    def __init__(self):
        self.mem = array.array('B', [0] * 32768)
        self.mem[IDENT] = 0x6d
        self.coldstart()

    def wrstr(self, a, s):
        if not isinstance(s, str):
            s = s.tostring()
        self.mem[a:a+len(s)] = array.array('B', s)

    def rd(self, a):
        """ Read byte at address ``a`` """
        return self.mem[a]

    def rdstr(self, a, n):
        """
        Read ``n`` bytes starting at address ``a``

        :rtype: string of length ``n``.
        """
        return self.mem[a:a+n].tostring()

    def writewave(self, duration, dst):
        """
        Write the simulated output of the sound system to a wave file

        :param duration: length of clip in seconds
        :param dst: destination wave filename
        """
        sintab = [int(127 * math.sin(2 * math.pi * i / 128.)) for i in range(128)]
        nsamples = int(8000 * duration)
        master = [i/8000. for i in range(nsamples)]
        lacc = [0] * nsamples
        racc = [0] * nsamples
        for v in range(64):
            if v == self.rd(RING_START):
                print v, max(lacc)
                ring = [s/256 for s in lacc]
                lacc = [0] * nsamples
                racc = [0] * nsamples

            (freq,la,ra) = struct.unpack("<HBB", self.rdstr(VOICES + 4 * v, 4))
            if la or ra:
                tone = [sintab[int(m * freq * 32) & 0x7f] for m in master]
                if self.rd(RING_START) <= v < self.rd(RING_END):
                    lacc = [o + la * (r * t) / 256 for (o,r,t) in zip(lacc, ring, tone)]
                    racc = [o + ra * (r * t) / 256 for (o,r,t) in zip(racc, ring, tone)]
                else:
                    lacc = [o + la * t for (o,t) in zip(lacc, tone)]
                    racc = [o + ra * t for (o,t) in zip(racc, tone)]
        merged = [None,None] * nsamples
        merged[0::2] = lacc
        merged[1::2] = racc
        raw = array.array('h', merged)
        w = wave.open(dst, "wb")
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(8000)
        w.writeframesraw(raw)
        w.close()

    def bg(self, lines = range(512)):
        bg_color = self.rd16(BG_COLOR) & 0x7fff
        glyphs = []
        for i in range(256):
            pals = array.array('H', self.mem[RAM_PAL + 8 * i:RAM_PAL + 8 * i + 8].tostring())
            for j in range(4):
                if pals[j] & 0x8000:
                    pals[j] = bg_color
            glyph = []
            for y in range(8):
                for x in range(8):
                    pix = 3 & (self.mem[RAM_CHR + 16 * i + 2 * y + (x / 4)] >> [6,4,2,0][x&3])
                    glyph.append(pals[pix])
            glyphs.append(glyph)
        img = {}
        for y in lines:
            line = []
            for x in range(512):
                c = self.mem[RAM_PIC + 64 * (y >> 3) + (x >> 3)]
                line.append(glyphs[c][8 * (y & 7) + (x & 7)])
            img[y] = line
        return img

    def sprfetch(self, img, pal, rot, x, y):
        if rot & 1:
            exo,eyo = y,x
        else:
            exo,eyo = x,y
        if rot & 2:
            exo = 15 - exo
        if rot & 4:
            eyo = 15 - eyo
        ix = self.rd(RAM_SPRIMG + 256 * img + 16 * eyo + exo)
        if (pal & 0xc) == 0:
            pix = self.rd16(RAM_SPRPAL + 512 * (pal & 3) + 2 * ix)
        elif (pal & 0xc) == 4:
            nyb = 15 & (ix >> [0,4][1 & (pal >> 1)])
            pix = self.rd16(PALETTE16A + 32 * (pal & 1) + 2 * nyb)
        else:
            nyb = 3 & (ix >> [0,2,4,6][3 & (pal >> 1)])
            pix = self.rd16(PALETTE4A + 8 * (pal & 1) + 2 * nyb)
        return pix

    def spr_page(self):
        return RAM_SPR + 1024 * (self.rd(SPR_PAGE) & 1)

    def sp(self, y, line):
        if self.rd(SPR_DISABLE) & 1:
            return line
        page = self.spr_page()
        for i in range(256):
            sprval = self.rd32(page + 4 * i)
            sx = s9(sprval)
            sy = s9(sprval >> 16)
            simg = (sprval >> 25) & 63
            spal = (sprval >> 12) & 15
            srot = (sprval >> 9) & 7
            yo = y - sy
            if 0 <= yo < 16:
                for xo in range(16):
                    if 0 <= (sx + xo) < 400:
                        pix = self.sprfetch(simg, spal, srot, xo, yo)
                        if pix < 32768:
                            line[sx + xo] = pix
        return line
    def coll(self):
        """
        Return the 256 bytes of COLLISION RAM.

        :rtype: list of byte values.
        """
        coll = 256 * [0xff]
        page = self.spr_page()
        jkmode = (self.rd(JK_MODE) & 1) != 0
        if 0 == (self.rd(SPR_DISABLE) & 1):
            yocc = [[] for i in range(300)]
            for i in range(256):
                sprval = self.rd32(page + 4 * i)
                sy = s9(sprval >> 16)
                for j in range(16):
                    if 0 <= (sy + j) < 300:
                        yocc[sy + j].append(i)
            for y in range(300):
                tag = [None] * 400
                jk = [None] * 400
                for i in yocc[y]:
                    sprval = self.rd32(page + 4 * i)
                    sy = s9(sprval >> 16)
                    yo = y - sy
                    if 0 <= yo < 16:
                        sx = s9(sprval)
                        simg = (sprval >> 25) & 63
                        spal = (sprval >> 12) & 15
                        srot = (sprval >> 9) & 7
                        sjk = (sprval >> 31)
                        for xo in range(16):
                            x = sx + xo
                            if 0 <= x < 400:
                                if self.sprfetch(simg, spal, srot, xo, yo) < 32768:
                                    if tag[x] != None:
                                        if (not jkmode) or (jk[x] != sjk):
                                            coll[i] = tag[x]
                                    tag[x] = i
                                    jk[x] = sjk
        return coll

    def screen(self, lines, w = 400):
        sx = self.rd16(SCROLL_X) & 511
        sy = self.rd16(SCROLL_Y)
        bg = self.bg([sum512(y, sy) for y in lines])
        def wrapx(l):
            return (l + l)[sx:sx+w]
        return dict([(y, self.sp(y, wrapx(bg[sum512(y, sy)]))) for y in lines])

    def _im(self):
        return self._imwh(400, 300)

    def fullim(self):
        """ Return the entire 512x512 pixel screen image """
        return _imwh(512, 512)

    def _imwh(self, w, h):
        import Image
        fi = Image.new("RGB", (w, h))
        lines = self.screen(range(h), w)
        for y in range(h):
            ld = lines[y]
            r = [8 * (31 & (v >> 10)) for v in ld]
            g = [8 * (31 & (v >> 5)) for v in ld]
            b = [8 * (31 & (v >> 0)) for v in ld]
            rgb = sum(zip(r,g,b), ())
            li = Image.fromstring("RGB", (w,1), array.array('B', rgb).tostring())
            fi.paste(li, (0, y))
        return fi

    def linecrc(self, y):
        line = array.array('H', self.screen([y])[y]).tostring()
        return 0xffffffff & binascii.crc32(line)

    def collcrc(self):
        return 0xffffffff & binascii.crc32(array.array('B', self.coll()).tostring())

    def memcrc(self, a, s):
        return 0xffffffff & binascii.crc32(self.mem[a:a+s])

    def memory(self):
        """ Returns current image of memory as a 32768 byte string """
        return self.mem.tostring()

def readarray(filename):
    return array.array('B', open(filename).read())


__all__ = [ "Gameduino" ]
