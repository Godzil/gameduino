#include <SPI.h>
#include <GD.h>

struct voice
{
  float f;
  float a;
} voices[16];

void load()
{
  byte v;
  unsigned int gg = 0;

  float sum = 0.0;
  for (v = 0; v < 16; v++) {
    sum += voices[v].a;
  }
  float scale = 255.0 / sum;
  for (v = 0; v < 16; v++) {
    byte a = int(voices[v].a * scale);
    GD.voice(v, 0, int(4 * voices[v].f), a, a);
  }
}

struct sprite
{
  int x;
  int y;
} sprites[64];
static int sprnum;

void note(byte voice, byte m, byte vel)
{
  if (voice == 0 && vel) {
    sprites[sprnum].x = 384;
    sprites[sprnum].y = 284 - 8 * m;
    sprnum = (sprnum + 1) & 63;
  }
  float f0 = 440 * pow(2.0, (m - 69) / 12.0);
  float a0 = vel / 120.;
  if (voice == 0) {
    float choirA[] = { 3.5, 1.6, .7, 3.7, 1, 2 };
    byte v;
    for (v = 0; v < 6; v++) {
      voices[v].f = (v + 1) * f0;
      voices[v].a = a0 * choirA[v] / 3.7;
    }
  } else {
    voices[voice].f = f0;
    voices[voice].a = a0;
  }
}

static void pause(int n)
{
  load();
  long started = millis();
  while (millis() < (started + n * 3 / 2)) {
    GD.waitvblank();
    byte i;
    for (i = 0; i < 64; i++) {
      if (sprites[i].x > -16) {
        GD.sprite(i, sprites[i].x, sprites[i].y, 0, 0, 0);
        sprites[i].x--;
      } else {
        GD.sprite(i, 400, 400, 0, 0, 0);
      }
    }
  }
}

#define PAUSE(x)      255,x
#define NOTE(v, p, a) v, p, a

static PROGMEM prog_uchar widor_toccata[] = {
#include "music.h"
};

static void play()
{
  prog_uchar *pc = widor_toccata;
  while (pc < (widor_toccata + sizeof(widor_toccata))) {
    byte a = pgm_read_byte_near(pc++);
    byte b = pgm_read_byte_near(pc++);
    if (a == 255) {
      pause(b);
    } else {
      byte c = pgm_read_byte_near(pc++);
      note(a, b, c);
    }
  }
}

void setup()
{
  int i;

  GD.begin();
  
  GD.ascii();

  GD.wr16(RAM_SPRPAL + (0 * 2), 0x8000);
  GD.wr16(RAM_SPRPAL + (1 * 2), RGB(255, 255, 255));

  GD.fill(RAM_SPRIMG, 0, 256);
  GD.wr(RAM_SPRIMG + 0x78, 1);
  GD.wr(RAM_SPRIMG + 0x98, 1);
  GD.wr(RAM_SPRIMG + 0x87, 1);
  GD.wr(RAM_SPRIMG + 0x89, 1);
  GD.wr(RAM_SPRIMG + 0x88, 1);

  GD.putstr(0, 0,"Widor's Toccata");
}

void loop()
{
  play();
  delay(2000);
  int i;
  for (i = 0; i < 256; i++)
    GD.sprite(i, 400, 400, 0, 0, 0);

}
