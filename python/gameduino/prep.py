"""
gameduino.prep - for graphics and sound preparation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The prep module provides utilities for
preparing Gameduino media: images and sound.
These utilities can be used, for example, to take image files
and encode them so that the Gameduino can display them as backgrounds
or sprites.


..
    This module defines mnemonics for the sprite palette select field:
    +-----------------------+-------+
    | PALETTE256A           | 0     |
    +-----------------------+-------+
    | PALETTE256B           | 1     |
    +-----------------------+-------+
    | PALETTE256C           | 2     |
    +-----------------------+-------+
    | PALETTE256D           | 3     |
    +-----------------------+-------+
    | PALETTE16A_BITS0123   | 4     |
    +-----------------------+-------+
    | PALETTE16A_BITS4567   | 6     |
    +-----------------------+-------+
    | PALETTE16B_BITS0123   | 5     |
    +-----------------------+-------+
    | PALETTE16B_BITS4567   | 7     |
    +-----------------------+-------+
    | PALETTE4A_BITS01      | 8     |
    +-----------------------+-------+
    | PALETTE4A_BITS23      | 10    |
    +-----------------------+-------+
    | PALETTE4A_BITS45      | 12    |
    +-----------------------+-------+
    | PALETTE4A_BITS67      | 14    |
    +-----------------------+-------+
    | PALETTE4B_BITS01      | 9     |
    +-----------------------+-------+
    | PALETTE4B_BITS23      | 11    |
    +-----------------------+-------+
    | PALETTE4B_BITS45      | 13    |
    +-----------------------+-------+
    | PALETTE4B_BITS67      | 15    |
    +-----------------------+-------+

The module defines these constants for use as the ``palset`` argument to  :meth:`ImageRAM.addsprites`:

+-------------+-------------------------+
| PALETTE256A | 256-color palette A     |
+-------------+-------------------------+
| PALETTE256B | 256-color palette B     |
+-------------+-------------------------+
| PALETTE256C | 256-color palette C     |
+-------------+-------------------------+
| PALETTE256D | 256-color palette D     |
+-------------+-------------------------+
| PALETTE4A   | Four-color palette A    |
+-------------+-------------------------+
| PALETTE4B   | Four-color palette B    |
+-------------+-------------------------+
| PALETTE16A  | Sixteen-color palette A |
+-------------+-------------------------+
| PALETTE16B  | Sixteen-color palette B |
+-------------+-------------------------+

"""

PALETTE256A = [0]
PALETTE256B = [1]
PALETTE256C = [2]
PALETTE256D = [3]
PALETTE4A_BITS01 = (0x8 + (0 << 1))
PALETTE4A_BITS23 = (0x8 + (1 << 1))
PALETTE4A_BITS45 = (0x8 + (2 << 1))
PALETTE4A_BITS67 = (0x8 + (3 << 1))
PALETTE4A = (PALETTE4A_BITS01, PALETTE4A_BITS23, PALETTE4A_BITS45, PALETTE4A_BITS67)
PALETTE4B_BITS01 = (0x8 + (0 << 1) + 1)
PALETTE4B_BITS23 = (0x8 + (1 << 1) + 1)
PALETTE4B_BITS45 = (0x8 + (2 << 1) + 1)
PALETTE4B_BITS67 = (0x8 + (3 << 1) + 1)
PALETTE4B = (PALETTE4B_BITS01, PALETTE4B_BITS23, PALETTE4B_BITS45, PALETTE4B_BITS67)

PALETTE16A_BITS0123 = (0x4 + (0 << 1))
PALETTE16A_BITS4567 = (0x4 + (1 << 1))
PALETTE16A = (PALETTE16A_BITS0123, PALETTE16A_BITS4567)
PALETTE16B_BITS0123 = (0x4 + (0 << 1) + 1)
PALETTE16B_BITS4567 = (0x4 + (1 << 1) + 1)
PALETTE16B = (PALETTE16B_BITS0123, PALETTE16B_BITS4567)

from array import array
import Image

def dump(hh, name, data):
    """
    Writes data to a header file for use in an Arduino Sketch.

    :param hh: destination header file
    :type hh: :class:`file`
    :param name: the name of the object, as it will appear in the header file
    :type name: string
    :param data: the data to be dumped
    :type data: :class:`array.array`
    """
    print >>hh, "static PROGMEM prog_uchar %s[] = {" % name
    bb = array('B', data.tostring())
    for i in range(0, len(bb), 16):
        if (i & 0xff) == 0:
            print >>hh
        for c in bb[i:i+16]:
            print >>hh, "0x%02x, " % c,
        print >>hh
    print >>hh, "};"

def rgbpal(imdata):
    # For RGBA imdata, return list of (r,g,b) triples and the palette
    li = array('B', imdata).tolist()
    rgbas = zip(li[0::4], li[1::4], li[2::4], li[3::4])
    palette = list(set(rgbas))
    return (rgbas, palette)

def getch(im, x, y):
    # return the RGBA data for the 8x8 character at (x, y) in im
    # if the 8x8 RGB contains more than 4 colors, quantize it using
    # `scolorq <http://www.cs.berkeley.edu/~dcoetzee/downloads/scolorq/>`_.

    sub88 = im.crop((x, y, x + 8, y + 8))
    sub88d = sub88.tostring()

    (_, pal) = rgbpal(sub88d)
    if len(pal) > 4:
        return sub88.convert('RGB').convert('P', palette=Image.ADAPTIVE, colors=4).convert("RGBA")
    else:
        return sub88

def rgb555(r, g, b):
    return ((r / 8) << 10) + ((g / 8) << 5) + (b / 8)

def rgba1555(r, g, b, a):
    return ((a < 128) << 15) + ((r / 8) << 10) + ((g / 8) << 5) + (b / 8)

def encodech(imdata):
    """
    imdata is 8x8x4 RGBA character, string of length 256
    return the pixel and palette data for it as
    :class:`array.array` of type 'B' and 'H' respectively.
    """

    assert len(imdata) == (4 * 8 * 8)
    (rgbs, palette) = rgbpal(imdata)
    indices = [palette.index(c) for c in rgbs]
    indices_b = ""
    for i in range(0, len(indices), 4):
        c =   ((indices[i] << 6) +
               (indices[i + 1] << 4) +
               (indices[i + 2] << 2) +
               (indices[i + 3]))
        indices_b += (chr(c))
    palette = (palette + ([(0,0,0,255)] * 4))[:4]   # unused palette entries: opaque black
    ph = array('H', [rgba1555(*p) for p in palette])
    return (indices_b, ph)

def getpal(im):
    """ im is a paletted image.  Return its palette as a Gameduino sprite palette
    in an :class:`array.array` of type 'H'.  This form can be used directly with :func:`dump`::

        import gameduino.prep as gdprep
        ...
        gdprep.dump(hfile, "paletteA", gdprep.getpal(im))

    """

    ncol = ord(max(im.tostring())) + 1
    ncol = min([c for c in [4,16,256] if c >= ncol])
    lut = im.resize((ncol, 1))
    lut.putdata(range(ncol))
    palstr = lut.convert("RGB").tostring()
    rgbs = zip(*(array('B', palstr[i::3]) for i in range(3)))
    rgb555 = [(((r / 8) << 10) | ((g / 8) << 5) | (b / 8)) for (r,g,b) in rgbs]
    if 'transparency' in im.info:
        rgb555[im.info['transparency']] = 0x8000
    return array('H', rgb555)

def encode(im):
    """
    Convert a PIL image to a Gameduino character background image.

    :param im: A Python Imaging Library image
    :rtype: tuple of data for (picture, character, font) all :class:`array.array`.

    The image must have dimensions that are multiples of 8.
    If any character cell contains more than four colors, then the cell's pixel are quantized to four colors before encoding.
    If the image requires more than 256 unique character cells, this function throws exception OverflowError.
    The tuple returned contains three pieces of data:
    
    * picture - the bytes representing the character cells.  For input image sized (w, h) this array has size (w/8)*(h/8).  Type of this array is 'B' (unsigned byte)
    * character - the glyphs for all used 8x8 characters.  One character is 16 bytes.  Type of this array is 'B' (unsigned byte)
    * palette - the 4-color palettes for all used 8x8 characters.  One character is 8 bytes.  Type of this array is 'H' (unsigned short)

    To display the image, load these three arrays into Gameduino memory.  For example,
    to encode a single image and
    write its data to a header file ``titlescreen.h``::

      import gameduino.prep as gdprep
      (dpic, dchr, dpal) = gdprep.encode(Image.open("titlescreen.png"))
      hdr = open("titlescreen.h", "w")
      gdprep.dump(hdr, "titlescreen_pic", dpic)
      gdprep.dump(hdr, "titlescreen_chr", dchr)
      gdprep.dump(hdr, "titlescreen_pal", dpal)

    and to display the image on the screen, an Arduino sketch might do::

      #include "titlescreen.h"

      void setup()
      {
      ...
        GD.copy(RAM_PIC, titlescreen_pic, sizeof(titlescreen_pic));
        GD.copy(RAM_CHR, titlescreen_chr, sizeof(titlescreen_chr));
        GD.copy(RAM_PAL, titlescreen_pal, sizeof(titlescreen_pal));

    """

    if im.mode != "RGBA":
        im = im.convert("RGBA")
    charset = {} # dict that maps 8x8 images to byte charcodes
    picture = [] # 64x64 byte picture RAM
    for y in range(0, im.size[1], 8):
        for x in range(0, im.size[0], 8):
            iglyph = getch(im, x, y)
            glyph = iglyph.tostring()
            if not glyph in charset:
                if len(charset) == 256:
                    raise OverflowError
                charset[glyph] = len(charset)
            picture.append(charset[glyph])
    picd = array('B', picture)
    cd = array('B', [0] * 16 * len(charset))
    pd = array('H', [0] * 4 * len(charset))
    for d,i in charset.items():
        for y in range(8):
            (char, pal) = encodech(d)
            cd[16 * i:16 * (i+1)] = array('B', char)
            pd[4 * i:4 * (i+1)] = pal
    return (picd, cd, pd)

def preview(picd, cd, pd):
    preview = Image.new("RGB", im.size)
    preview.paste(iglyph, (x, y))
    return preview

def glom(sizes):
    """ Returns a master size and a list of crop/paste coordinates """
    mw = max(w for (w,h) in sizes)
    mh = sum(h for (w,h) in sizes)
    y = 0
    r = []
    for (w,h) in sizes:
        r.append((0, y, w, y + h))
        y += h
    return ((mw,mh), r)


def palettize(im, ncol):
    """ Given an input image or list of images, convert to a palettized version using at most ``ncol`` colors.
    This function preserves transparency: if the input(s) have transparency then the returned
    image(s) have ``.info['transparency']`` set to the transparent color.

    If ``im`` is a single image, returns a single image.  If ``im`` is a list of images, returns a list of images.
    """
    
    assert ncol in (4, 16, 256)
    if isinstance(im, list):
        # For a list of images, paste them all into a single image,
        # palettize the single image, then return cropped subimages

        for i in im:
            i.load()
        (ms, lpos) = glom([i.size for i in im])
        master = Image.new(im[0].mode, ms)
        for i,ps in zip(im, lpos):
            master.paste(i, ps)
        master = palettize(master, ncol)
        ims = [master.crop(ps) for ps in lpos]
        for i in ims:
            i.info = master.info
        return ims
    else:
        im.load()
        
    if im.mode == 'P':
        if ord(max(im.tostring())) < ncol:
            return im # already done
        if 'transparency' in im.info:
            im = im.convert("RGBA")
        else:
            im = im.convert("RGB")
    assert im.mode in ("RGBA", "RGB")
    if im.mode == "RGB":
        return im.convert('P', palette=Image.ADAPTIVE, colors=ncol)
    else:
        alpha = im.split()[3]
        mask = Image.eval(alpha, lambda a: 255 if a <= 128 else 0)
        im.paste((0,0,0), mask)
        im = im.convert('RGB').convert('P', palette=Image.ADAPTIVE, colors = (ncol - 1))
        im.paste(ncol - 1, mask)
        im.info['transparency'] = ncol - 1
        return im

def isnonblank(im):
    assert im.mode == 'P'
    if 'transparency' in im.info:
        transparent = im.info['transparency']
        (w,h) = im.size
        colors = set([im.getpixel((i, j)) for i in range(w) for j in range(h)])
        return colors != set([transparent])
    else:
        return True

class ImageRAM(object):
    """

    The ImageRAM object simplifies loading of the Gameduino's 16K sprite image RAM.
    A caller adds sprite images to the ImageRAM, and finally obtains a memory image
    using :meth:`ImageRAM.used`.

    """
    def __init__(self, hh):
        self.hh = hh
        self.data = array('B', [0] * 16384)
        self.nxtpage = 0    # next available page
        self.nxtbit = 0     # next available bit

    def __bump(self, b):
        self.nxtbit += b
        if 8 == self.nxtbit:
            self.nxtbit = 0
            self.nxtpage += 1

    def add(self, page, size):
        """
        Add a sprite image to the ImageRAM

        :param page: image data, a list length 256
        :param size: size of data elements, either 4, 16 or 256
        :rtype: Returns a tuple (image, pal)

        This method adds the data in ``page`` to the ImageRAM, and the returns the assigned location.  ``image`` is the
        sprite image 0-63 containing the data, and ``pal`` is the palette bit select for the data.

        For a 4-color image, ``pal`` is 0-3, for 16-color image ``pal`` is 0-1 and for a 256-color image ``pal`` is 0.

        The ``image`` and ``pal`` values may be used to display the sprite using :cpp:func:`GD::sprite`.

        If the data would cause the ImageRAM to increase beyond 16K, this method throws exception OverflowError.
        """
        assert size in (4,16,256)
        assert max(page) < size, "%d colors allowed, but page contains %d" % (size, max(page))
        assert len(page) == 256

        bits = {4:2, 16:4, 256:8}[size]
        while (self.nxtbit % bits) != 0:
            self.__bump(2)
        if self.nxtpage == 64:
            raise OverflowError
        if size == 4:
            pal = self.nxtbit / 2
        elif size == 16:
            pal = self.nxtbit / 4
        else:
            pal = 0
        pg = self.nxtpage
        for i in range(256):
            self.data[256 * self.nxtpage + i] |= (page[i] << self.nxtbit)
        self.__bump(bits)
        return (pg, pal)

    def addsprites(self, name, size, im, palset = PALETTE256A, center = (0,0)):
        """
        Extract multiple sprite frames from a source image, and generate the code to draw them.

        :param name: name of the sprite set; used to name the generated ``draw_`` function
        :param size: size of each sprite frame (width, height)
        :param im: source image, mode must be 'P' - paletted
        :param palset: palette set to use for the sprite, one of PALETTE256A-D, PALETTE16A-B, PALETTE4A-B
        :param center: the center pixel of the sprite image.  Default is (0,0) meaning top left pixel.

        Given a sequence of sprite frames in ``im``, this method extracts their data and adds it to the ImageRAM.  
        In addition, it writes the code to draw the sprite to the ImageRAM's header file.  For example::

            import gameduino.prep as gdprep
            ir = gdprep.ImageRAM(open("hdr.h", "w"))
            rock0 = gdprep.palettize(Image.open("rock0r.png"), 16)
            ir.addsprites("rock0", (16, 16), rock0, gdprep.PALETTE16A, center = (8,8))

        would extract the four 16x16 frames from the ``rock0r.png`` image:
        
        .. image:: rock0r.png
        
        and write the following code to ``hdr.h``::

            #define ROCK0_FRAMES 4
            static void draw_rock0(int x, int y, byte anim, byte rot, byte jk = 0) {
            ...
            }

        For more more examples, see the :ref:`asteroids` demo game.
        """

        def get16x16(sheet, x, y):
            return sheet.crop((16*x, 16*y, 16*(x+1), 16*(y+1)))

        def walktile(im, size):
            for y in range(0, im.size[1], size[1]):
                for x in range(0, im.size[0], size[0]):
                    yield im.crop((x, y, x + size[0], y + size[1]))
        tiles = list(walktile(im, size))

        print >>self.hh, "#define %s_FRAMES %d" % (name.upper(), len(tiles))
        animtype = ["byte", "int"][len(tiles) > 255]
        print >>self.hh, """static void draw_%s(int x, int y, %s anim, byte rot, byte jk = 0) {\n  switch (anim) {""" % (name, animtype)
        if palset == PALETTE256A:
            ncolors = 256
        elif palset == PALETTE256B:
            ncolors = 256
        elif palset == PALETTE256C:
            ncolors = 256
        elif palset == PALETTE256D:
            ncolors = 256
        elif palset == PALETTE4A:
            ncolors = 4
        elif palset == PALETTE4B:
            ncolors = 4
        elif palset == PALETTE16A:
            ncolors = 16
        elif palset == PALETTE16B:
            ncolors = 16
        else:
            highest = ord(max(im.tostring()))
            ncolors = min([c for c in [4,16,256] if (highest < c)])
        for spr,spriteimage in enumerate(tiles):
            loads = []
            for y in range((size[1] + 15) / 16):
                for x in range((size[0] + 15) / 16):
                    t = get16x16(spriteimage, x, y)
                    t.info = im.info    # workaround: PIL does not copy .info when cropping
                    if isnonblank(t):
                        (page, palsel) = self.add(array('B', t.tostring()), ncolors)
                        loads += ["    GD.xsprite(x, y, %d, %d, %d, %d, rot, jk);" % (x * 16 - center[0], y * 16 - center[1], page, palset[palsel])]
            if loads:
                print >>self.hh, "  case %d:" % spr
                print >>self.hh, "\n".join(loads)
                print >>self.hh, "    break;"

        print >>self.hh, """  }\n}\n"""

    def used(self):
        """
        Return the contents of the ImageRAM, as an :class:`array.array` of type 'B'.
        The size of the array depends on the amount of data added, up to a limit
        of 16K.
        """
        if self.nxtbit == 0:
            past = self.nxtpage
        else:
            past = self.nxtpage + 1
        return array('B', self.data[:256*past])

import math

def spectrum(specfile, cutoff = 64, volume = 255):
    """
    Read an Audacity spectrum file and return a list of (frequency, amplitude)
    pairs, loudest first.

    :param cutoff: length of the list of returned pairs
    :param volume: total volume of the returned pairs
    :rtype: list of tuples (frequency, amplitude) where frequency is a floating-point frequency in Hz, and amplitude in an integer amplitude.

    This function can be used to create voice profiles for instruments
    and sounds.  For example to load a choir sound, previously saved
    as ``choir.txt``::
        
        for (i, (f, a)) in enumerate(spectrum("choir.txt")):
            gd.voice(i, 0, int(4 * f), a, a)

    """

    snd = [[float(t) for t in l.split()] for l in open(specfile) if not "Freq" in l]
    snd = [(f,db) for (f,db) in snd if 40 < f < 8192]
    snd = sorted(snd, reverse=True, key=lambda t:t[1])
    top = snd[:cutoff]
    amps = [(f,math.pow(2, .1 * db)) for (f, db) in top]
    samps = sum([a for (f,a) in amps])
    return [(f, int(volume * a / samps)) for (f, a) in amps]

__all__ = [ "encode", "dump", "palettize", "getpal", "ImageRAM", "spectrum", ]
