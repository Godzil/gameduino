#include <SPI.h>
#include <GD.h>

// replicate a 2-bit color across the whole byte.  Optimization for setpixel
byte replicate(byte color)
{
  return (color << 6) | (color << 4) | (color << 2) | color;
}

// Set pixel at (x,y) to color.  (note that color is replicated).
void setpixel(byte x, byte y, byte color)
{
  /*
   Because of the way the sprites are laid out in setup(), it's not too
   hard to translate the pixel (x,y) to an address and mask.  Taking the
   two byte values as x7-x0 and y7-y0, the address of the pixel is:

      x5 x4 y7 y6 y5 y4 y3 y2 y1 y0 x3 x2 x1 x0

  (x6, x7) gives the value of the mask.
  */
  unsigned int addr = RAM_SPRIMG | (x & 0xf) | (y << 4) | ((x & 0x30) << 8);
  byte mask = 0xc0 >> ((x >> 5) & 6);
  GD.wr(addr, (GD.rd(addr) & ~mask) | (color & mask));
}

// Draw color line from (x0,y0) to (x1,y1).
void line(byte x0, byte y0, byte x1, byte y1, byte color)
{
  byte swap;
#define SWAP(a, b) (swap = (a), (a) = (b), (b) = swap)

  color = replicate(color);
  byte steep = abs(y1 - y0) > abs(x1 - x0);
  if (steep) {
    SWAP(x0, y0);
    SWAP(x1, y1);
  }
  if (x0 > x1) {
    SWAP(x0, x1);
    SWAP(y0, y1);
  }
  int deltax = x1 - x0;
  int deltay = abs(y1 - y0);
  int error = deltax / 2;
  char ystep;
  if (y0 < y1)  
    ystep = 1;
  else
    ystep = -1;
  byte x;
  byte y = y0;
  for (x = x0; x < x1; x++) {
    if (steep)
      setpixel(y, x, color);
    else
      setpixel(x, y, color);
    error -= deltay;
    if (error < 0) {
      y += ystep;
      error += deltax;
    }
  }
}

struct point {
  int x, y;
  char xv, yv;
};
static struct point triangle[3];

#define RANDOM_RGB() RGB(random(256),random(256),random(256))

// Restart the drawing
static void restart()
{
  // Clear the screen
  GD.fill(RAM_SPRIMG, 0, 16384);

  // Position triangle at random
  byte i;
  for (i = 0; i < 3; i++) {
    triangle[i].x = 3 + random(250);
    triangle[i].y = 3 + random(250);
  }
  triangle[0].xv = 1;
  triangle[0].yv = 1;
  triangle[1].xv = -1;
  triangle[1].yv = 1;
  triangle[2].xv = 1;
  triangle[2].yv = -1;

  // Choose a random palette
  GD.wr16(PALETTE4A, RGB(0,0,0));
  GD.wr16(PALETTE4A + 2, RANDOM_RGB());
  GD.wr16(PALETTE4A + 4, RANDOM_RGB());
  GD.wr16(PALETTE4A + 6, RANDOM_RGB());
}

void setup()
{
  int i;

  GD.begin();
  GD.ascii();
  GD.putstr(0, 0,"Bitmap demonstration");

  // Draw 256 sprites left to right, top to bottom, all in 4-color
  // palette mode.  By doing them in column-wise order, the address
  // calculation in setpixel is made simpler.
  // First 64 use bits 0-1, next 64 use bits 2-4, etc.
  // This gives a 256 x 256 4-color bitmap.

  for (i = 0; i < 256; i++) {
    int x =     72 + 16 * ((i >> 4) & 15);
    int y =     22 + 16 * (i & 15);
    int image = i & 63;     /* image 0-63 */
    int pal =   3 - (i >> 6);   /* palettes bits in columns 3,2,1,0 */
    GD.sprite(i, x, y, image, 0x8 | (pal << 1), 0);
  }

  restart();
}

void loop()
{
  static byte color;

  if (random(1000) == 0)
    restart();

  line(triangle[0].x, triangle[0].y, triangle[1].x, triangle[1].y, color);
  line(triangle[1].x, triangle[1].y, triangle[2].x, triangle[2].y, color);
  line(triangle[2].x, triangle[2].y, triangle[0].x, triangle[0].y, color);
  color = (color + 1) & 3;
  byte i;
  for (i = 0; i < 3; i++) {
    triangle[i].x += triangle[i].xv;
    triangle[i].y += triangle[i].yv;
    if (triangle[i].x == 0 || triangle[i].x == 255)
      triangle[i].xv = -triangle[i].xv;
    if (triangle[i].y == 0 || triangle[i].y == 255)
      triangle[i].yv = -triangle[i].yv;
  }
}
