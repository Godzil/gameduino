#include <SPI.h>
#include <GD.h>

#include "flashimg.h"
#include "loadcommon.h"

void setup()
{
  common_setup(2);
  page = STAGEBASE + P2OFF;
  GD_uncompress(part2);

  common_show_status();
  GD.putstr(0, 20, "Done.  Now run load3");
  GD.wr(IOMODE, 0);
}

void loop()
{
}
