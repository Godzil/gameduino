/*
 * Copyright (C) 2011 by James Bowman <jamesb@excamera.com>
 * Gameduino library for arduino.
 *
 */

#ifndef _GD_H_INCLUDED
#define _GD_H_INCLUDED

// define SS_PIN before including "GD.h" to override this
#ifndef SS_PIN
#define SS_PIN 9
#endif

#ifdef MAPLE_IDE

#include <stdarg.h>
#include "wirish.h"

typedef const unsigned char prog_uchar;
typedef const signed char prog_char;
typedef const unsigned short prog_uint16_t;
typedef const unsigned long prog_uint32_t;
#define Serial SerialUSB
#define pgm_read_byte(x) (*(prog_uchar*)(x))
#define pgm_read_byte_near(x) pgm_read_byte(x)
#define pgm_read_word(x) (*(prog_uint16_t*)(x))
#define pgm_read_word_near(x) pgm_read_word(x)
#define pgm_read_dword(x) (*(prog_uint32_t*)(x))
#define pgm_read_dword_near(x) pgm_read_dword(x)
#define PROGMEM const
#define memcpy_P(a,b,c) memcpy((a), (b), (c))

extern HardwareSPI SPI;

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#endif

struct sprplot
{
  char x, y;
  byte image, palette;
};

class GDClass {
public:
  static void begin();
  static void end();
  static void __start(unsigned int addr);
  static void __wstart(unsigned int addr);
  static void __end(void);
  static byte rd(unsigned int addr);
  static void wr(unsigned int addr, byte v);
  static unsigned int rd16(unsigned int addr);
  static void wr16(unsigned int addr, unsigned int v);
  static void fill(int addr, byte v, unsigned int count);
  static void copy(unsigned int addr, prog_uchar *src, int count);
#if defined(__AVR_ATmega1280__) || defined(__AVR_ATmega2560__)
  static void copy(unsigned int addr, uint_farptr_t src, int count);
  static void microcode(uint_farptr_t src, int count);
  static void uncompress(unsigned int addr, uint_farptr_t src);
#endif

  static void setpal(int pal, unsigned int rgb);
  static void sprite(int spr, int x, int y, byte image, byte palette, byte rot = 0, byte jk = 0);
  static void sprite2x2(int spr, int x, int y, byte image, byte palette, byte rot = 0, byte jk = 0);
  static void waitvblank();
  static void microcode(prog_uchar *src, int count);
  static void uncompress(unsigned int addr, prog_uchar *src);

  static void voice(int v, byte wave, unsigned int freq, byte lamp, byte ramp);
  static void ascii();
  static void putstr(int x, int y, const char *s);

  static void screenshot(unsigned int frame);

  void __wstartspr(unsigned int spr = 0);
  void xsprite(int ox, int oy, signed char x, signed char y, byte image, byte palette, byte rot = 0, byte jk = 0);
  void xhide();
  void plots(int ox, int oy, PROGMEM sprplot *psp, byte count, byte rot, byte jk);

  byte spr;   // Current sprite, incremented by xsprite/xhide above
};

#define GD_HAS_PLOTS    1     // have the 'GD.plots' method

extern GDClass GD;

#define RGB(r,g,b) ((((r) >> 3) << 10) | (((g) >> 3) << 5) | ((b) >> 3))
#define TRANSPARENT (1 << 15) // transparent for chars and sprites

#define RAM_PIC     0x0000    // Screen Picture, 64 x 64 = 4096 bytes
#define RAM_CHR     0x1000    // Screen Characters, 256 x 16 = 4096 bytes
#define RAM_PAL     0x2000    // Screen Character Palette, 256 x 8 = 2048 bytes

#define IDENT         0x2800
#define REV           0x2801
#define FRAME         0x2802
#define VBLANK        0x2803
#define SCROLL_X      0x2804
#define SCROLL_Y      0x2806
#define JK_MODE       0x2808
#define J1_RESET      0x2809
#define SPR_DISABLE   0x280a
#define SPR_PAGE      0x280b
#define IOMODE        0x280c

#define BG_COLOR      0x280e
#define SAMPLE_L      0x2810
#define SAMPLE_R      0x2812

#define MODULATOR     0x2814
#define VIDEO_MODE    0x2815

#define   MODE_800x600_72   0
#define   MODE_800x600_60   1

#define SCREENSHOT_Y  0x281e

#define PALETTE16A 0x2840   // 16-color palette RAM A, 32 bytes
#define PALETTE16B 0x2860   // 16-color palette RAM B, 32 bytes
#define PALETTE4A  0x2880   // 4-color palette RAM A, 8 bytes
#define PALETTE4B  0x2888   // 4-color palette RAM A, 8 bytes
#define COMM       0x2890   // Communication buffer
#define COLLISION  0x2900   // Collision detection RAM, 256 bytes
#define VOICES     0x2a00   // Voice controls
#define J1_CODE    0x2b00   // J1 coprocessor microcode RAM
#define SCREENSHOT 0x2c00   // screenshot line RAM

#define RAM_SPR     0x3000    // Sprite Control, 512 x 4 = 2048 bytes
#define RAM_SPRPAL  0x3800    // Sprite Palettes, 4 x 256 = 2048 bytes
#define RAM_SPRIMG  0x4000    // Sprite Image, 64 x 256 = 16384 bytes

#ifndef GET_FAR_ADDRESS // at some point this will become official... https://savannah.nongnu.org/patch/?6352
#if defined(__AVR_ATmega1280__) || defined(__AVR_ATmega2560__)
#define GET_FAR_ADDRESS(var)                          \
({                                                    \
    uint_farptr_t tmp;                                \
                                                      \
    __asm__ __volatile__(                             \
                                                      \
            "ldi    %A0, lo8(%1)"           "\n\t"    \
            "ldi    %B0, hi8(%1)"           "\n\t"    \
            "ldi    %C0, hh8(%1)"           "\n\t"    \
            "clr    %D0"                    "\n\t"    \
        :                                             \
            "=d" (tmp)                                \
        :                                             \
            "p"  (&(var))                             \
    );                                                \
    tmp;                                              \
}) 
#else
#define GET_FAR_ADDRESS(var) (var)
#endif
#endif

// simple utilities for accessing the asset library in a filesystem-like
// way
// Details of the flash chip:
// http://www.atmel.com/dyn/resources/prod_documents/doc3638.pdf

const int FLASHSEL = 2; // flash SPI select pin
class Asset {

  private:

    uint32_t addr;    // pointer into flash memory
    uint16_t remain;  // number of remaing unread bytes

    byte find_name(const char *name) {
      // addr points at a directory, scan for name, if found set addr
      // to the entry and return 1, otherwise return 0.
      while (true) {
        static struct {
          char name[12];
          uint16_t length;
          uint32_t addr;
        } de;
        read(&de.name, 12);
        read(&de.length, 2);
        read(&de.addr, 4);
        if (de.name[0] == 0)
          return 0;   // end of dir, no match found
        if (strcmp(de.name, name) == 0) {
          remain = de.length;
          addr = de.addr;
          return 1;
        }
      }
    }

  public:

    int open(const char *d, ...) {
      va_list ap;
      va_start(ap, d);
      addr = 512L * 640;
      remain = 1024;
      pinMode(FLASHSEL, OUTPUT);
      digitalWrite(FLASHSEL, HIGH);
      do {
        if (!find_name(d))
          return 0;
        d = va_arg(ap, const char *);
      } while (d != NULL);
      return 1;
    }
    int read(void *dst, uint16_t n) {
      GD.wr(IOMODE, 'F');
      digitalWrite(FLASHSEL, LOW);
      SPI.transfer(0x03);
      SPI.transfer((byte)(addr >> 16));
      SPI.transfer((byte)(addr >> 8));
      SPI.transfer((byte)(addr >> 0));
      uint16_t actual = min(n, remain);   // actual bytes read
      byte *bdst = (byte*)dst;
      for (uint16_t a = actual; a; a--) {
        byte b = SPI.transfer(0);
        *bdst++ = b;
        addr++;
        if ((511 & (uint16_t)addr) == 264)
          addr = addr - 264 + 512;
      }
      remain -= actual;
      digitalWrite(FLASHSEL, HIGH);
      GD.wr(IOMODE, 0);
      return actual;
    }
    void load(uint16_t dst) {
      while (remain) {
        byte buf[16];
        uint16_t n = min(remain, sizeof(buf));
        read(buf, n);
        GD.__wstart(dst);
        for (byte i = 0; i < n; i++)
          SPI.transfer(buf[i]);
        GD.__end();
        dst += n;
      }
    }
    uint16_t available() {
      return remain;
    }
};

#endif

