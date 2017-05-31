RAM_PIC       = 0x0000    # Screen Picture, 64 x 64 = 4096 bytes
RAM_CHR       = 0x1000    # Screen Characters, 256 x 16 = 4096 bytes
RAM_PAL       = 0x2000    # Screen Character Palette, 256 x 8 = 2048 bytes

IDENT         = 0x2800
REV           = 0x2801
FRAME         = 0x2802
VBLANK        = 0x2803
SCROLL_X      = 0x2804
SCROLL_Y      = 0x2806
JK_MODE       = 0x2808
J1_RESET      = 0x2809
SPR_DISABLE   = 0x280a
SPR_PAGE      = 0x280b
IOMODE        = 0x280c

BG_COLOR      = 0x280e
SAMPLE_L      = 0x2810
SAMPLE_R      = 0x2812

SCREENSHOT_Y  = 0x281e

PALETTE16A    = 0x2840    # 16-color palette RAM A, 32 bytes
PALETTE16B    = 0x2860    # 16-color palette RAM B, 32 bytes
PALETTE4A     = 0x2880    # 4-color palette RAM A, 8 bytes
PALETTE4B     = 0x2888    # 4-color palette RAM A, 8 bytes
COMM          = 0x2890    # Communication buffer
COLLISION     = 0x2900    # Collision detection RAM, 256 bytes
VOICES        = 0x2a00    # Voice controls
J1_CODE       = 0x2b00    # J1 coprocessor microcode RAM
SCREENSHOT    = 0x2c00    # screenshot line RAM

RAM_SPR       = 0x3000    # Sprite Control, 512 x 4 = 2048 bytes
RAM_SPRPAL    = 0x3800    # Sprite Palettes, 4 x 256 = 2048 bytes
RAM_SPRIMG    = 0x4000    # Sprite Image, 64 x 256 = 16384 bytes

def RGB(r, g, b):
    """ Return the 16-bit hardware encoding of color (R,G,B).

    :param R: red value 0-255
    :param G: green value 0-255
    :param B: blue value 0-255
    :rtype: int
    """
    return ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3)

TRANSPARENT = (1 << 15)

