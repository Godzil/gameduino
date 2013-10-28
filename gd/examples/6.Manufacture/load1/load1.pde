#include <SPI.h>
#include <GD.h>

#include "flashimg.h"
#include "loadcommon.h"

void setup()
{
  common_setup(1);
  page = STAGEBASE + P1OFF;
  GD_uncompress(part1);

  common_show_status();
  GD.putstr(0, 20, "Done.  Now run load2");
  GD.wr(IOMODE, 0);
}

void loop()
{
}
