import sys
import time
import unittest
import Image
import StringIO

import gameduino.remote
import gameduino.prep as gdprep

gd = gameduino.remote.Gameduino(sys.argv.pop(), 115200)

class TestGameduino(unittest.TestCase):

    def setUp(self):
        pass

    def test_talk(self):
        self.assertEqual(gd.rd(gameduino.IDENT), 0x6d)

    def test_sprites(self):
        ir = gdprep.ImageRAM(StringIO.StringIO())
        (rock0, rock1) = gdprep.palettize([Image.open("rock0r.png"), Image.open("rock1r.png")], 16)
        ir.addsprites("rock0", (16, 16), rock0, gdprep.PALETTE16A, center = (8,8))
        ir.addsprites("rock1", (32, 32), rock1, gdprep.PALETTE16A, center = (16,16))
        gd.wr16(gameduino.RAM_PAL, gameduino.RGB(0, 255, 0))
        gd.wrstr(gameduino.RAM_SPRIMG, ir.used())
        gd.wrstr(gameduino.PALETTE16A, gdprep.getpal(rock0))

        for i in range(128):
            gd.sprite(i, 200 + 20 * (i & 7), 20 * (i / 8), i / 2, gdprep.PALETTE16A[i&1], 0)

        (pic,chr,pal) = gdprep.encode(Image.open("platformer.png"))
        gd.wrstr(gameduino.RAM_CHR, chr)
        gd.wrstr(gameduino.RAM_PAL, pal)
        for y in range(32):
            gd.wrstr(gameduino.RAM_PIC + 64 * y, pic[16*y:16*y+16])

    def test_ascii(self):
        gd.ascii()
        gd.putstr(10, 10, "THIS IS A!!")

if __name__ == '__main__':
    unittest.main()
