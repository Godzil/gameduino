#include <SPI.h>
#include <GD.h>

// ----------------------------------------------------------------------
//     controller: buttons on Arduino pins 3,4,5,6 with 7 grounded
// ----------------------------------------------------------------------

static void controller_init()
{
  // Configure input pins with internal pullups
  byte i;
  for (i = 3; i < 7; i++) {
    pinMode(i, INPUT);
    digitalWrite(i, HIGH);
  }
  // drive pin 7 low
  pinMode(7, OUTPUT);
  digitalWrite(7, 0);
}

#define CONTROL_LEFT  1
#define CONTROL_RIGHT 2
#define CONTROL_UP    4
#define CONTROL_DOWN  8

static byte controller_sense()
{
  byte r = 0;
  if (!digitalRead(5))
    r |= CONTROL_DOWN;
  if (!digitalRead(4))
    r |= CONTROL_UP;
  if (!digitalRead(6))
    r |= CONTROL_LEFT;
  if (!digitalRead(3))
    r |= CONTROL_RIGHT;
  return r;
}

#define FLOCAL 2
#define SEL_local() digitalWrite(FLOCAL, LOW)
#define UNSEL_local() digitalWrite(FLOCAL, HIGH)

struct dirent {
  char name[12];
  uint16_t length;
  uint32_t addr;
};

static uint32_t flash_readn(byte *dst, uint32_t src, size_t n)
{
  SEL_local();
  SPI.transfer(0x03);
  SPI.transfer((byte)(src >> 16));
  SPI.transfer((byte)(src >> 8));
  SPI.transfer((byte)(src >> 0));
  while (n--) {
    *dst++ = SPI.transfer(0);
    src++;
    if ((511 & (uint16_t)src) == 264)
      src = src - 264 + 512;
  }
  UNSEL_local();
  return src;
}

uint16_t samp_len;
uint32_t samp_ptr;

static dirent de;

static byte find_name(uint32_t &ptr, uint16_t &len, uint32_t dirptr, char *name)
{
  while (true) {
    dirptr = flash_readn((byte*)&de, dirptr, sizeof(de));
    if (de.name[0] == 0)
      return 0;   // end of dir, no match found
    if (strcmp(de.name, name) == 0) {
      len = de.length;
      ptr = de.addr;
      return 1;
    }
  }
}

static byte ninstruments;
static dirent instruments[32];

struct active {
  byte instrument;
  uint32_t addr;
  uint16_t pos, length;
  uint16_t x, y;
};
#define NACTIVE 3
static active playing[NACTIVE];

struct active *findidle()
{
  byte i;
  for (i = 0; i < NACTIVE; i++)
    if (playing[i].addr == 0)
      return &playing[i];
  return NULL;
}

static void kickoff(byte i)
{
  active *p = findidle();
  if (p) {
    p->addr = instruments[i].addr;
    p->pos = 0;
    p->length = instruments[i].length;
    p->x = 0;
    p->y = 16 + 16 * i;
  }
}

static void fromflash(uint16_t dst, uint32_t src, uint16_t len)
{
  while (len--) {
    byte v;
    src = flash_readn(&v, src, 1);
    GD.wr(dst++, v);
  }
}

static byte sprstr(int x, int y, byte spr, const char *txt)
{
  char c;
  while ((c = *txt++) != 0) {
    GD.sprite(spr++, x, y, (c - ' ') >> 2, 8 + ((c & 3) << 1), 0);
    x += 11;
  }
  return spr;
}

// add all samples from dir
void add_samples(uint32_t dir)
{
  dirent *pi = &instruments[ninstruments];
  while (dir = flash_readn((byte*)pi, dir, sizeof(*pi)), pi->name[0]) {
    pi++, ninstruments++;
  }
}

void setup()
{
  controller_init();
  GD.begin();
  GD.ascii();
  pinMode(FLOCAL, OUTPUT);
  UNSEL_local();
  GD.wr(IOMODE, 'F');
  uint32_t assetroot = 512L * 640;
  uint32_t dk;
  uint16_t dkl;
  find_name(dk, dkl, assetroot, "voice");
  add_samples(dk);
  find_name(dk, dkl, assetroot, "drumkit");
  add_samples(dk);

  byte i;
  for (i = 0; i < ninstruments; i++) {
    byte x = (50 - strlen(instruments[i].name)) >> 1;
    GD.putstr(x, 2 + i, instruments[i].name);
  }

  uint32_t sd;
  uint16_t sdl;
  if (1) { 
    find_name(dk, dkl, assetroot, "pickups");
    find_name(sd, sdl, dk, "pal");
    fromflash(RAM_SPRPAL, sd, sdl);
    find_name(sd, sdl, dk, "img");
    fromflash(RAM_SPRIMG, sd, sdl);
  }
}

#include "soundbuffer.h"

#define SOUNDBUFFER 0x3f00

int cursor;
void loop()
{
  GD.microcode(soundbuffer_code, sizeof(soundbuffer_code));

  byte writepointer = 0;
  for (;;) {
    active *p;
    byte i;

    byte readpointer = GD.rd(COMM+0);
    byte fullness = writepointer - readpointer;
    while (fullness < 254) {
      char total = 0;
      for (p = playing, i = 0; i < NACTIVE; p++, i++) {
        if (p->addr) {
          char v;
          p->addr = flash_readn((byte*)&v, p->addr, 1);
          total += (v >> 1);
          if (++p->pos >= p->length)
            p->addr = 0;
        }
      }
      GD.wr(SOUNDBUFFER + writepointer++, total);
      fullness++;
    }

    GD.waitvblank();
    GD.sprite(0, 142, 11 + 8 * cursor, 47, 0, 0);
    GD.sprite(1, 238, 11 + 8 * cursor, 47, 0, 2);

    static byte prev;
    byte press;
    press = controller_sense();
    press = random(16);
    if (prev == 0) {
      if (press & CONTROL_DOWN)
        cursor = min(ninstruments - 1, cursor + 1);
      if (press & CONTROL_UP)
        cursor = max(0, cursor - 1);
      if (press & (CONTROL_RIGHT | CONTROL_LEFT))
        kickoff(cursor);
    }
    prev = press;
  }
}
