#include <SPI.h>
#include <GD.h>

#include "assetlib.h"
#include "loadcommon.h"

void setup()
{
  common_setup(0);
  GD.putstr(0, 0, "Asset loader 0");
  page = ASSET0_PAGE;
  GD_uncompress(GET_FAR_ADDRESS(assetlib0));
  if (flash_sum(ASSET0_PAGE, ASSET0_LEN) != ASSET0_SUM)
    GD.putstr(0, 10, "load failed");
  else
    GD.putstr(0, 10, "Done");
}

void loop()
{
}
