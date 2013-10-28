#include <SPI.h>
#include <GD.h>

#include "r.h"

void setup()
{
  int i;

  GD.begin();
  GD.ascii();
  GD.putstr(0, 0,"Sprite rotation");

  GD.copy(RAM_SPRIMG, r_img, sizeof(r_img));
  GD.copy(RAM_SPRPAL, r_pal, sizeof(r_pal));

  for (i = 0; i < 8; i++) {
    char msg[] = "ROT=.";
    byte y = 3 + 4 * i;
    msg[4] = '0' + i;
    GD.putstr(18, y, msg);
    GD.sprite(i, 200, 8 * y, 0, 0, i);
  }
}

void loop()
{
}
