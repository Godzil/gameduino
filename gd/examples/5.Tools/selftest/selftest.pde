#include <SPI.h>
#include <GD.h>

int atxy(int x, int y)
{
  return (y << 6) + x;
}

void readn(byte *dst, unsigned int addr, int c)
{
  GD.__start(addr);
  while (c--)
    *dst++ = SPI.transfer(0);
  GD.__end();
}

static byte coll[256];
static void debug_coll()
{
  while (GD.rd(VBLANK) == 0)  // Wait until vblank
    ;
  while (GD.rd(VBLANK) == 1)  // Wait until display
    ;
  while (GD.rd(VBLANK) == 0)  // Wait until vblank
    ;
  readn(coll, COLLISION, 256);
}

#define FAIL do { Serial.print("Fail at line: "); Serial.println(__LINE__, DEC); return 0; } while (0)

int test_collision()
{
  int i, j;
#define NOCOLL 0xff
  
  GD.wr16(RAM_SPRPAL, 0x8000);  // color 0 transparent, 1-255 0x5555 (pinkish)
  GD.fill(RAM_SPRPAL + 2, 0x55, 510);
  GD.fill(RAM_SPRIMG, 1, 256);

  for (i = 0; i < 256; i++)
    GD.sprite(i, 400, 400, 0, 0, 0);
  debug_coll();
  for (i = 0; i < 256; i++)
    if (coll[i] != NOCOLL)
      FAIL;

  GD.sprite(7, 200, 100, 0, 0, 0);
  GD.sprite(117, 200, 200, 0, 0, 0);

  byte jkmode, jk;
  for (jkmode = 0; jkmode < 2; jkmode++) {
    for (jk = 0; jk < 2; jk++) {
      GD.wr(JK_MODE, jkmode);
      for (i = -20; i < 20; i++) {
        GD.sprite(8, 200, 100 + i, 0, 0, 0, jk);
        GD.sprite(200, 200 + i, 200, 0, 0, 0, jk);

        debug_coll();

        byte expected = ((!jkmode || jk) && (abs(i) < 16)) ? 7 : NOCOLL;
        if (coll[8] != expected)
          FAIL;
        expected = ((!jkmode || jk) && (abs(i) < 16)) ? 117 : NOCOLL;
        if (coll[200] != expected)
          FAIL;
      }
    }
  }

  randomSeed(1);
  for (j = 100; j; j--) {
    for (i = 0; i < 256; i++) {
      GD.sprite(i, random(512), random(512), 0, 0, 0);
    }
    debug_coll();
    for (i = 0; i < 256; i++) {
      if (coll[i] != 0xff && (coll[i] >= i))
        FAIL;
    }
  }

  for (i = 0; i < 256; i++)
    GD.sprite(i, 400, 400, 0, 0, 0);

  return 1;
}

int test_ident()
{
  byte id = GD.rd(IDENT);
  if (id != 0x6d) {
    Serial.println(id, HEX);
    FAIL;
  }
  return 1;
}

int test_frame()
{
  byte v;
  const int nframes = 200;

  v = GD.rd(FRAME);
  while (GD.rd(FRAME) != ((v + 1) & 0xff))
    ;
  long t0 = micros();
  while (GD.rd(FRAME) != ((v + nframes + 1) & 0xff))
    ;
  long t10 = micros();

  Serial.println(t10 - t0, DEC);
  Serial.print("(");
  Serial.print(nframes / (1.e-6 * (t10 - t0)), DEC);
  Serial.println(" fps)");

  return 1;
}

// low-level SPI test.  Write a random pattern to the 16K image RAM,
// then read it back, verifying the same random values.  Meant to
// catch SPI transmission errors.

int test_spi()
{
  int i;

  randomSeed(947);
  GD.__wstart(RAM_SPRIMG);
  for (i = 0; i < 16384; i++)
    SPI.transfer(random(256));
  GD.__end();

  randomSeed(947);
  GD.__start(RAM_SPRIMG);
  for (i = 0; i < 16384; i++)
    if (SPI.transfer(0) != random(256))
      FAIL;
  GD.__end();

  return 1;
}

// Test a RAM area (addr, c)
int test_a_ram(unsigned int addr, int c)
{
  while (c--) {
    byte prev = GD.rd(addr);
    GD.wr(addr, 0xff); if (GD.rd(addr) != 0xff) FAIL;
    GD.wr(addr, 0x00); if (GD.rd(addr) != 0x00) FAIL;
    GD.wr(addr, 0x47); if (GD.rd(addr) != 0x47) FAIL;
    GD.wr(addr, prev); if (GD.rd(addr) != prev) FAIL;
    addr++;
  }
  return 1;
}

// Write/read a simple pattern to each RAM byte.
// (Restores RAM values so display is preserved.)
int test_rams()
{
  test_a_ram(0, (4 + 4 + 2) * 1024);     /* Pic, chr and pal */
  test_a_ram(RAM_SPR, 0x5000);  /* Sprites */
  test_a_ram(PALETTE16A, 64);
  test_a_ram(PALETTE4A, 16);
  test_a_ram(VOICES, 64 * 4);
  GD.wr(J1_RESET, 1);
  test_a_ram(J1_CODE, 256);
  return 1;
}

int test_audio_l()
{
  GD.fill(VOICES, 0, 64 * 4);
  GD.voice(0, 0, 4 * 440, 255, 0);
  delay(1000);
  return 1;
}

int test_audio_r()
{
  GD.fill(VOICES, 0, 64 * 4);
  GD.voice(0, 0, 4 * 440, 0, 255);
  delay(1000);
  GD.fill(VOICES, 0, 64 * 4);
  return 1;
}

int test_speed()
{
  long t0 = millis();
  int i, j;
  for (i = 0; i < 1000; i++) {
    GD.fill(RAM_SPRIMG, 0x55, 1000);
  }
  Serial.print("(Took ");
  Serial.print(millis() - t0);
  Serial.print(")");
  return 1;
}

#include "lena.h"

static void show_lena()
{
  GD.copy(RAM_SPRPAL, lenapal, sizeof(lenapal));
  int i;
  for (i = 0; i < 64; i++)
    GD.sprite(i, 256 + ((i & 7) << 4), 64 + 2 * (i & 070), i, 0, 0);
  for (i = 64; i < 512; i++)
    GD.sprite(i, 400, 400, 0, 0, 0);
  GD.uncompress(RAM_SPRIMG, lenaimg);
}

void show_stripes()
{
  int i;
  for (i = 0; i < 32; i++) {
    GD.wr16(RAM_PAL + (0x80 + i) * 8, RGB(8 * i, 0, 0));
    GD.wr16(RAM_PAL + (0xa0 + i) * 8, RGB(0, 8 * i, 0));
    GD.wr16(RAM_PAL + (0xc0 + i) * 8, RGB(0, 0, 8 * i));
    GD.wr(atxy(i, 24), 0x80 + i);
    GD.wr(atxy(i, 25), 0xa0 + i);
    GD.wr(atxy(i, 26), 0xc0 + i);
  }
  GD.putstr(0, 28, "R");
  GD.putstr(0, 29, "G");
  GD.putstr(0, 30, "B");
  GD.putstr(4, 31, "0");
  GD.putstr(8, 31, "1");
  GD.putstr(16, 31, "2");

  GD.wr(atxy(4, 28), 0x80 + 4);
  GD.wr(atxy(8, 28), 0x80 + 8);
  GD.wr(atxy(16, 28), 0x80 + 16);

  GD.wr(atxy(4, 29), 0xa0 + 4);
  GD.wr(atxy(8, 29), 0xa0 + 8);
  GD.wr(atxy(16, 29), 0xa0 + 16);

  GD.wr(atxy(4, 30), 0xc0 + 4);
  GD.wr(atxy(8, 30), 0xc0 + 8);
  GD.wr(atxy(16, 30), 0xc0 + 16);
}

byte y;
static void logn(const char*s)
{
  Serial.print(s);
  GD.putstr(0, y, s);
}

static void log(const char*s)
{
  Serial.println(s);
  GD.putstr(16, y++, s);
}

#define RUNTEST(NAME) \
  do { \
  logn(#NAME ":  "); \
  r = NAME(); \
  log(r ? "pass" : "FAIL"); \
  pass &= r; \
  } while (0)

#include "selftest1.h"

static unsigned long rd32()
{
  return GD.rd16(COMM+0) + ((unsigned long)GD.rd16(COMM+2) << 16);
}

int test_coproc()
{
  GD.microcode(selftest1_code, sizeof(selftest1_code));
  GD.wr(COMM+15, 0);  // stop
  GD.wr16(COMM+0, 0);
  GD.wr16(COMM+2, 0);
  unsigned long started;
  unsigned long cycles0, cycles1;
  byte regime;
  int jj;

  for (regime = 0; regime < 6; regime++) {
    cycles0 = rd32();
    started = micros();
    GD.wr(COMM+15, 1);  // go

    switch (regime) {
    case 0:
      delay(1000);
      break;
    case 1:
      GD.__start(0);
      delay(1000);
      GD.__end();
      break;
    case 2:
      GD.__start(0);
      SPI.transfer(0);
      delay(1000);
      GD.__end();
      break;
    case 3:
      GD.__start(0);
      for (jj = 0; jj < 1000; jj++) {
        SPI.transfer(0);
        delay(1);
      }
      GD.__end();
      break;
    case 4:
      for (jj = 0; jj < 1000; jj++) {
        GD.rd(0);
        delay(1);
      }
      break;
    case 5:
      while ((micros() - started) < 1000000) {
        GD.__start(0);
        for (jj = 0; jj < 1000; jj++)
          SPI.transfer(0);
        GD.__end();
      }
      break;
    }

    GD.wr(COMM+15, 0);  // stop
    delay(1);
    cycles1 = rd32();
    long cps = long(1e6 * (cycles1 - cycles0) / (micros() - started));
    if (cps < 1000000)
      FAIL;

    // Serial.println(micros() - started, DEC);
    // Serial.print(regime, DEC);
    // Serial.print(' ');
    // Serial.println(cps, DEC);
  }
  return 1;
}

// See Atmel AT45DB021D datasheet:
// http://www.atmel.com/dyn/resources/prod_documents/doc3638.pdf

static int test_flash()
{
  GD.wr(IOMODE, 'F');
  pinMode(2, OUTPUT);
  digitalWrite(2, HIGH);
  delay(1);

  digitalWrite(2, LOW);
  SPI.transfer(0xd7);   // read SPI flash status
  byte status = SPI.transfer(0);
  digitalWrite(2, HIGH);

  if (status != 0x94)   // 0x94 means "idle; all is well"
      FAIL;
  GD.wr(IOMODE, 0);

  return 1;
}

static void runtests()
{
  char msg[50];

  GD.begin();
  
  GD.ascii();
  GD.fill(0, ' ', 4096);
  GD.putstr(0, 0,"<------------------- TOP LINE ------------------->");
  GD.putstr(0,36,"<----------------- BOTTOM LINE ------------------>");
  show_stripes();

  y = 3;
  byte r, pass = 1;
  log("Starting self-test");

  RUNTEST(test_ident);
  // RUNTEST(test_frame);
  RUNTEST(test_flash);
  RUNTEST(test_audio_l);
  RUNTEST(test_audio_r);
  RUNTEST(test_coproc);
  RUNTEST(test_speed);
  RUNTEST(test_spi);
  RUNTEST(test_rams);
  RUNTEST(test_collision);

  if (pass) {
    log("All tests passed");
    show_lena();

    long seconds = millis() / 1000;
    long minutes = seconds / 60;
    sprintf(msg, "%d minutes", minutes);
    log(msg);

    // GD.screenshot(0);
  } else {
    for (;;) {
      GD.wr16(BG_COLOR, RGB(255,0,0));
      delay(100);
      GD.wr16(BG_COLOR, RGB(0,0,0));
      delay(100);
    }
  }

  byte i;
  for (i = 9; i; i--) {
    sprintf(msg, "Restarting in %d", i);
    GD.putstr(0, y, msg);
    delay(1000);
  }
}

void setup()
{
  Serial.begin(1000000);
  runtests();
}

void loop()
{
  runtests();
}
