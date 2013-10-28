#include <SPI.h>
#include <GD.h>

#include "ball.h"

void setup()
{
  GD.begin();

  // Background image
  GD.copy(RAM_PIC, bg_pic, sizeof(bg_pic));
  GD.copy(RAM_CHR, bg_chr, sizeof(bg_chr));
  GD.copy(RAM_PAL, bg_pal, sizeof(bg_pal));

  // Sprite graphics
  GD.uncompress(RAM_SPRIMG, ball);

  // Palettes 0 and 1 are for the ball itself,
  // and palette 2 is the shadow.  Set it to
  // all gray.
  int i;
  for (i = 0; i < 256; i++)
    GD.wr16(RAM_SPRPAL + (2 * (512 + i)), RGB(64, 64, 64));

  // Set color 255 to transparent in all three palettes
  GD.wr16(RAM_SPRPAL + 2 * 0xff,  TRANSPARENT);
  GD.wr16(RAM_SPRPAL + 2 * 0x1ff, TRANSPARENT);
  GD.wr16(RAM_SPRPAL + 2 * 0x2ff, TRANSPARENT);
}

#define RADIUS (112 / 2) // radius of the ball, in pixels

#define YBASE (300 - RADIUS)

void loop()
{
  int x = 200, y = RADIUS;              // ball position
  int xv = 2, yv = 0;                   // ball velocity

  int r;                                // frame counter
  for (r = 0; ; r++) {
    GD.__wstartspr((r & 1) ? 256 : 0);  // write sprites to other frame
    draw_ball(x + 15, y + 15, 2);       // draw shadow using palette 2
    draw_ball(x, y, r & 1);             // draw ball using palette 0 or 1
    GD.__end();

    // paint the new palette
    uint16_t palette = RAM_SPRPAL + 512 * (r & 1);
    byte li;
    for (li = 0; li < 7; li++) {
      byte liv = 0x90 + 0x10 * li;      // brightness goes 0x90, 0xa0, etc
      uint16_t red = RGB(liv, 0, 0);
      uint16_t white = RGB(liv, liv, liv);
      byte i;
      for (i = 0; i < 32; i++) {        // palette cycling using 'r'
        GD.wr16(palette, ((i + r) & 16) ? red : white);
        palette += 2;
      }
    }

    // bounce the ball around
    x += xv;
    if ((x < RADIUS) || (x > (400 - RADIUS)))
      xv = -xv;
    y += yv;
    if ((yv > 0) && (y > YBASE)) {
      y = YBASE - (y - YBASE);          // reflect in YBASE
      yv = -yv;                         // reverse Y velocity
    }
    if (0 == (r & 3))
      yv++;                             // gravity

    // swap frames
    GD.waitvblank();
    GD.wr(SPR_PAGE, (r & 1));
  }
}
