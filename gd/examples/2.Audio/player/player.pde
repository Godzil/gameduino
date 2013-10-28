#include <SPI.h>
#include <GD.h>

#include "mont.h"

// visualize voice (v) at amplitude (a) on an 8x8 grid
void visualize(byte v, byte a)
{
    int x = 64 + ((v & 7) * 34);
    int y = 14 + ((v >> 3) * 34);
    byte sprnum = (v << 2); // draw each voice using four sprites
    GD.sprite(sprnum++, x + 16, y + 16, a, 0, 0);
    GD.sprite(sprnum++, x +  0, y + 16, a, 0, 2);
    GD.sprite(sprnum++, x + 16, y +  0, a, 0, 4);
    GD.sprite(sprnum++, x +  0, y +  0, a, 0, 6);
}

void setup()
{
  int i;

  GD.begin();

  GD.wr16(RAM_SPRPAL + 2 * 255, TRANSPARENT);

  // draw 32 circles into 32 sprite images
  for (i = 0; i < 32; i++) {
    GD.wr16(RAM_SPRPAL + 2 * i, RGB(8 * i, 64, 255 - 8 * i));
    int dst = RAM_SPRIMG + 256 * i;
    GD.__wstart(dst);
    byte x, y;
    int r2 = min(i * i, 256);
    for (y = 0; y < 16; y++) {
      for (x = 0; x < 16; x++) {
        byte pixel;
        if ((x * x + y * y) <= r2)
          pixel = i;    // use color above
        else
          pixel = 0xff; // transparent
        SPI.transfer(pixel);
      }
    }
    GD.__end();
  }
  for (i = 0; i < 64; i++)
    visualize(i, 0);
}

byte amp[64];       // current voice amplitude
byte target[64];    // target voice amplitude

// Set volume for voice v to a
void setvol(byte v, byte a)
{
  GD.__wstart(VOICES + (v << 2) + 2);
  SPI.transfer(a);
  SPI.transfer(a);
  GD.__end();
}

void adsr()  // handle ADSR for 64 voices
{
  byte v;
  for (v = 0; v < 64; v++) {
    int d = target[v] - amp[v]; // +ve means need to increase
    if (d) {
      if (d > 0)
        amp[v] += 4;  // attack
      else
        amp[v]--;     // decay
      setvol(v, amp[v]);
      visualize(v, amp[v]);
    }
  }
}

void loop()
{
  prog_uchar *pc;
  long started = millis();
  int ticks = 0;
  for (pc = mont; pc < mont + sizeof(mont);) {
    byte cmd = pgm_read_byte_near(pc++);  // upper 2 bits are command code
    if ((cmd & 0xc0) == 0) {
      // Command 0x00: pause N*5 milliseconds
      ticks += (cmd & 63);
      while (millis() < (started + ticks * 5)) {
        adsr();
        delay(1);
      }
    } else {
      byte v = (cmd & 63);
      byte a;
      if ((cmd & 0xc0) == 0x40) {
        // Command 0x40: silence voice
        target[v] = 0;
      } else if ((cmd & 0xc0) == 0x80) {
        // Command 0x80: set voice frequency and amplitude
        byte flo = pgm_read_byte_near(pc++);
        byte fhi = pgm_read_byte_near(pc++);
        GD.__wstart(VOICES + 4 * v);
        SPI.transfer(flo);
        SPI.transfer(fhi);
        GD.__end();
        target[v] = pgm_read_byte_near(pc++);
      }
    }
  }
}
