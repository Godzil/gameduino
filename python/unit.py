import gameduino
import unittest
import Image
import StringIO

import gameduino.prep as gdprep
import gameduino.sim as gdsim
import gameduino.compress as compress
import gameduino

class TestGameduino(unittest.TestCase):

    def setUp(self):
        self.bg = Image.open("platformer.png")
        pass

    def test_encode(self):
        im = self.bg.convert("RGB")
        w,h = im.size
        (pic,chr,pal) = gdprep.encode(im)
        self.assertEqual(len(chr.tostring()) / 16, len(pal.tostring()) / 8)
        self.assertEqual(len(pic), (w / 8) * (h / 8))

    def test_imageRAM(self):
        hh = StringIO.StringIO()
        singles = [Image.open("rock0r-pal16.png"),
                   gdprep.palettize(Image.open("rock0r.png"), 16),
                   gdprep.palettize(Image.open("rock0r-pal16.png"), 16)]
        for r in singles:
            print r.mode
            ir = gdprep.ImageRAM(hh)
            ir.addsprites("rock0", (16, 16), r, gdprep.PALETTE16A, center = (8,8))
            self.assert_(len(hh.getvalue()) > 0)
            self.assertEqual(len(gdprep.getpal(r)), 16)
        ir = gdprep.ImageRAM(hh)
        (walk,) = gdprep.palettize([Image.open("walk.png")], 16)
        ir.addsprites("walk", (32, 32), walk, gdprep.PALETTE16A, center = (8,32))
        print len(ir.used())
        print hh.getvalue()

    def test_compress(self):
        cc = compress.Codec(b_off = 9, b_len = 3)
        for plain in [ "00000111100000",  "This is this" * 4]:
            compressed = cc.compress(plain)
            print "compressed to", len(compressed), "tokens"
            print compressed
            self.assertEqual(plain, cc.decompress(compressed))
            print len(cc.sched2bs(compressed))

    def test_sim(self):
        gd = gdsim.Gameduino()
        self.assertEqual(gd.rd(gameduino.IDENT), 0x6d)
        i = gd.im()
        self.assertEqual(i.size, (400,300))

    def test_prep_sim(self):
        im = self.bg.convert("RGB")
        (pic,chr,pal) = gdprep.encode(im)
        gd = gdsim.Gameduino()
        gd.wrstr(gameduino.RAM_PIC, pic)
        gd.wrstr(gameduino.RAM_CHR, chr)
        gd.wrstr(gameduino.RAM_PAL, pal)
        gd.im().save("preview.png")

    def test_471fcf9e(self):
        im = Image.open("471fcf9e.png")
        imp = gdprep.palettize(im, 16)
        print gdprep.getpal(imp)

if __name__ == '__main__':
    unittest.main()
