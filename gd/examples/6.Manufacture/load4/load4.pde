#include <SPI.h>
#include <GD.h>

#include "flashimg.h"
#include "loadcommon.h"

#include "reload.h"

void reload()
{
  GD.microcode(reload_code, sizeof(reload_code));
}

static unsigned long copy_page(int dst, int src)
{
  int i;

  SEL_local();
  SPI.transfer(0x03);
  spipage(src);
  for (i = 0; i < 264; i++)
    history[i] = spix(0);
  UNSEL_local();

  SEL_local();
  SPI.transfer(0x82);
  spipage(dst);
  for (i = 0; i < 264; i++)
    spix(history[i]);
  UNSEL_local();
  while ((status() & 0x80) == 0)
    ;
}

void setup()
{
  common_setup(4);

  if (!ready0123(STAGEBASE)) {
    GD.putstr(0, 20, "You must run load0, load1, load2, load3 first");
    for (;;)
      ;
  }
    
  common_show_status();
  do {
    page = P4OFF;
    GD_uncompress(part4);
    common_show_status();
  } while (!ready(4));

  do {
    GD.putstr(0, 20, "Parts ready. Copying...");
    GD.putstr(0, 22, "DO NOT INTERRUPT OR TURN OFF");
    int i;
    for (i = 0; i < P4OFF; i++)
      copy_page(i, STAGEBASE + i);
  } while (!ready0123(0));

  GD.putstr(25, 20, "Done!");
  GD.putstr(0, 27, "Now restarting...");
  delay(2000);
  reload();
}

void loop()
{
}
