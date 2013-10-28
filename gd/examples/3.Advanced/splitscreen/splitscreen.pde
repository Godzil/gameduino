#include <SPI.h>
#include <GD.h>

#include "splitscreen.h"

/*
 For the splitscreen microprogram, the COMM area holds 8 short words
 that control the 3-way screen split:

 COMM+0   SCROLL_X for top section
 COMM+2   SCROLL_Y for top section
 COMM+4   Y-coordinate of start of middle section
 COMM+6   SCROLL_X for middle section
 COMM+8   SCROLL_Y for middle section
 COMM+10  Y-coordinate of start of bottom section
 COMM+12  SCROLL_X for bottom section
 COMM+14  SCROLL_Y for bottom section
*/

#include "splitscreen_graphics.h"

void setup()
{
  GD.begin();

  GD.copy(RAM_PIC, splitscreen_pic, sizeof(splitscreen_pic));
  GD.copy(RAM_CHR, splitscreen_chr, sizeof(splitscreen_chr));
  GD.copy(RAM_PAL, splitscreen_pal, sizeof(splitscreen_pal));

  GD.wr16(COMM+0, 0);
  GD.wr16(COMM+2, 0);
  GD.wr16(COMM+4, 100);   // split at line 100
  GD.wr16(COMM+6, 0);
  GD.wr16(COMM+8, 140);
  GD.wr16(COMM+10, 200);   // split at line 200
  GD.wr16(COMM+12, 0);
  GD.wr16(COMM+14, (511 & (82 - 200))); // show line 82 at line 200

  GD.microcode(splitscreen_code, sizeof(splitscreen_code));
}

// Set the scroll registers for the middle screen secion to (x, y)
static void scrollxy(uint16_t x, uint16_t y)
{
  GD.wr16(COMM+6, x);
  GD.wr16(COMM+8, y);
}

void loop()
{
  static int i;
  float th = i / 16.;
  scrollxy(55 + 50 * cos(th), 150 + 50 * sin(th));
  GD.wr16(COMM+12, i);
  i++;
  GD.waitvblank();
}
