#include <SPI.h>
#include <GD.h>

#include "assetlib.h"
#include "loadcommon.h"

void setup()
{
  common_setup(2);
  GD.putstr(0, 0, "Asset loader 2");
  page = ASSET2_PAGE;
  GD_uncompress(GET_FAR_ADDRESS(assetlib2));
  if (flash_sum(ASSET2_PAGE, ASSET2_LEN) != ASSET2_SUM)
    GD.putstr(0, 10, "load failed");
  else
    GD.putstr(0, 10, "Done");
}

void loop()
{
}
