#include <SPI.h>
#include <GD.h>

void readn(byte *dst, unsigned int addr, int c)
{
  GD.__start(addr);
  while (c--)
    *dst++ = SPI.transfer(0);
  GD.__end();
}

static byte coll[256];
static void load_coll()
{
  while (GD.rd(VBLANK) == 0)  // Wait until vblank
    ;
  while (GD.rd(VBLANK) == 1)  // Wait until display
    ;
  while (GD.rd(VBLANK) == 0)  // Wait until vblank
    ;
  readn(coll, COLLISION, sizeof(coll));
}

void setup()
{
  int i;

  GD.begin();

  GD.wr(JK_MODE, 1);
  GD.wr16(RAM_PAL, RGB(255,255,255));

  // Use the 4 palettes:
  // 0 pink, for J sprites
  // 1 green, for K sprites
  // 2 dark pink, J collisions
  // 3 dark green, K collisions
  for (i = 0; i < 256; i++) {
    GD.wr16(RAM_SPRPAL + (0 * 512) + (i << 1), RGB(255, 0, 255));
    GD.wr16(RAM_SPRPAL + (1 * 512) + (i << 1), RGB(0, 255, 0));
    GD.wr16(RAM_SPRPAL + (2 * 512) + (i << 1), RGB(100, 0, 100));
    GD.wr16(RAM_SPRPAL + (3 * 512) + (i << 1), RGB(0, 100, 0));
  }
}

byte spr;
static void polar(float th, int r, byte jk)
{
  // add 2 to the palette if this sprite is colliding
  byte colliding = coll[spr] != 0xff;
  GD.sprite(spr, 200 + int(r * sin(th)), 142 + int(r * cos(th)), 0, jk + (colliding ? 2 : 0), 0, jk);
  spr++;
}

void loop()
{
  byte i;
  float th;
  spr = 0;
  // draw the J sprites (pink)
  for (i = 0; i < 5; i++) {
    th = (millis() / 3000.) + 2 * PI * i / 5;
    polar(th, 134, 0);
  }
  // draw the K sprites (green)
  randomSeed(4);
  for (i = 0; i < 17; i++) {
    th = (millis() / float(random(1000,3000))) + 2 * PI * i / 17;
    polar(th, 134, 1);
  }
  load_coll();
}
