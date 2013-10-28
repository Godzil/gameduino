#include <SPI.h>
#include <GD.h>

#include "rasterinterrupt.h"

#define LINETIME_US 41.6    // time for one raster line in microseconds
#define delayLines(n) delayMicroseconds(int(n * LINETIME_US))

static int line;

#define BLACK 
#define RED   RGB(255, 0, 0)

void service()
{
  delayLines(0.5);   // wait half a line: puts us in middle of screen
  if (line == 150) {
    GD.wr16(BG_COLOR, RGB(255, 0, 0));  // turn red at line 150
    line = 170;
  } else {
    GD.wr16(BG_COLOR, RGB(0, 0, 0));    // turn black at line 170
    line = 150;
  }
  GD.wr16(COMM+0, line);    // Set next split line
}

void setup()
{
  int i;

  GD.begin();
  GD.ascii();
  GD.putstr(0, 0, "Raster interrupts");

  pinMode(2, INPUT);        // Arduino reads on pin 2
  GD.wr(IOMODE, 'J');       // pin 2 is under microprogram control
  line = 150;
  GD.wr16(COMM+0, line);    // Set first split line
                            // The raster interrupt microprogram
  GD.microcode(rasterinterrupt_code, sizeof(rasterinterrupt_code));
                            // call 'rising' every time pin 2 rises
  attachInterrupt(0, service, RISING);
}

void loop()
{
}
