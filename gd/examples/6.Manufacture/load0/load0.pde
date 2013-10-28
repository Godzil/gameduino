#include <SPI.h>
#include <GD.h>

#include "flashimg.h"
#include "loadcommon.h"

void setup()
{
  common_setup(0);
  page = STAGEBASE;
  GD_uncompress(part0);

  common_show_status();
  GD.putstr(0, 20, "Done.  Now run load1");
  GD.wr(IOMODE, 0);
}

void loop()
{
}
