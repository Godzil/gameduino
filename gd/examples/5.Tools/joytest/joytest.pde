#include <SPI.h>
#include <GD.h>

void setup()
{
#if 0
  pinMode(9, OUTPUT);
  pinMode(12, INPUT);
  digitalWrite(12, HIGH);
  for (;;) {
    digitalWrite(9, HIGH);
    delay(1000);
    digitalWrite(9, LOW);
    delay(1000);
  }
#endif
  // Configure input pins with internal pullups
  byte i;
  for (i = 2; i < 7; i++) {
    pinMode(i, INPUT);
    digitalWrite(i, HIGH);
  }
  GD.begin();
  GD.ascii();

  GD.wr16(RAM_SPRPAL + 2 * 255, TRANSPARENT);

  // draw 32 circles into 32 sprite images
  for (i = 0; i < 32; i++) {
    GD.wr16(RAM_SPRPAL + 2 * i, RGB(8 * i, 64, 255 - 8 * i));
    int dst = RAM_SPRIMG + 256 * i;
    GD.__wstart(dst);
    byte x, y;
    int r2 = min(i * i, 256);
    for (y = 0; y < 16; y++) {
      for (x = 0; x < 16; x++) {
        byte pixel;
        if ((x * x + y * y) <= r2)
          pixel = i;    // use color above
        else
          pixel = 0xff; // transparent
        SPI.transfer(pixel);
      }
    }
    GD.__end();
  }
}

void circle(int x, int y, byte a)
{
    byte sprnum = 0;
    GD.sprite(sprnum++, x + 16, y + 16, a, 0, 0);
    GD.sprite(sprnum++, x +  0, y + 16, a, 0, 2);
    GD.sprite(sprnum++, x + 16, y +  0, a, 0, 4);
    GD.sprite(sprnum++, x +  0, y +  0, a, 0, 6);
}

static byte bbits()
{
  byte r;
  r |= (digitalRead(3) << 0);
  r |= (digitalRead(4) << 1);
  r |= (digitalRead(5) << 2);
  r |= (digitalRead(6) << 3);
  r |= (digitalRead(2) << 4);
  return r;
}

static byte ands = 0x1f, ors = 0x00;

void loop()
{
  GD.putstr(40, 10, digitalRead(4) ? "-" : "U");
  GD.putstr(40, 20, digitalRead(5) ? "-" : "D");
  GD.putstr(35, 15, digitalRead(6) ? "-" : "L");
  GD.putstr(45, 15, digitalRead(3) ? "-" : "R");

  GD.putstr(17, 24, digitalRead(2) ? "-" : "S");

  int x = analogRead(0);
  int y = analogRead(1);

  byte bb = bbits();
  ands &= bb;
  ors |= bb;

  if (ands == 0 && ors == 0x1f)
    GD.putstr(35, 24, "BUTTONS OK");

  char msg[20];
  sprintf(msg, "X=%4d, Y=%4d", x, y);
  GD.putstr(0, 36, msg);

  circle(x / 4, 255 - y / 4, digitalRead(2) ? 15 : 31);
}
