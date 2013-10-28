#include <SPI.h>
#include <GD.h>

#define RED RGB(255,0,0)
#define GREEN RGB(0,255,0)

void setup()
{
  int i;

  GD.begin();
  GD.ascii();
  GD.putstr(20, 0, "Screenshot");

  GD.wr16(RAM_PAL + (8 * 127), RED);   // char 127: 0=red, 3=green
  GD.wr16(RAM_PAL + (8 * 127) + 6, GREEN);
  static PROGMEM prog_uchar box[] = {
     0xff, 0xff,
     0xc0, 0x03,
     0xc0, 0x03,
     0xc0, 0x03,
     0xc0, 0x03,
     0xc0, 0x03,
     0xc0, 0x03,
     0xff, 0xff };
  GD.copy(RAM_CHR + (16 * 127), box, sizeof(box));

  for (i = 0; i < 64; i++) {
    GD.wr(64 * i + i, 127);     // diagonal boxes

    char msg[20];
    sprintf(msg, "Line %d", i);
    GD.putstr(i + 2, i, msg);

    GD.wr(64 * i + 49, 127);    // boxes on right
  }

  Serial.begin(1000000);
  long started = millis();
  GD.screenshot(0);
}

void loop()
{
}
