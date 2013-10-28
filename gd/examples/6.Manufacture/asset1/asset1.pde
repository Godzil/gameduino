#include <SPI.h>
#include <GD.h>

#include "assetlib.h"
#include "loadcommon.h"

void setup()
{
  common_setup(1);
  GD.putstr(0, 0, "Asset loader 1");
  page = ASSET1_PAGE;
  GD_uncompress(GET_FAR_ADDRESS(assetlib1));
  if (flash_sum(ASSET1_PAGE, ASSET1_LEN) != ASSET1_SUM)
    GD.putstr(0, 10, "load failed");
  else
    GD.putstr(0, 10, "Done");
}

void loop()
{
}
