#include <SPI.h>
#include <GD.h>

#include "flashimg.h"
#include "loadcommon.h"

void setup()
{
  common_setup(3);
  page = STAGEBASE + P3OFF;
  GD_uncompress(part3);

  common_show_status();
  GD.putstr(0, 20, "Done.  Now run load4");
  GD.wr(IOMODE, 0);
}

void loop()
{
}
