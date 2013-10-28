#include <SPI.h>
#include <GD.h>

#include "random.h"

void setup()
{
  GD.begin();
  int i;
  for (i = 0; i < 256; i++) {
    GD.wr16(RAM_PAL + (4 * i + 0) * 2, RGB(0,0,0));
    GD.wr16(RAM_PAL + (4 * i + 1) * 2, RGB(0x20,0x20,0x20));
    GD.wr16(RAM_PAL + (4 * i + 2) * 2, RGB(0x40,0x40,0x40));
    GD.wr16(RAM_PAL + (4 * i + 3) * 2, RGB(0xff,0xff,0xff));
  }
  GD.microcode(random_code, sizeof(random_code));
}

void loop()
{
}
