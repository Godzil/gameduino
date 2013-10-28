#include <SPI.h>
#include <GD.h>

static PROGMEM prog_uint32_t crc_table[16] = {
    0x00000000, 0x1db71064, 0x3b6e20c8, 0x26d930ac,
    0x76dc4190, 0x6b6b51f4, 0x4db26158, 0x5005713c,
    0xedb88320, 0xf00f9344, 0xd6d6a3e8, 0xcb61b38c,
    0x9b64c2b0, 0x86d3d2d4, 0xa00ae278, 0xbdbdf21c
};

unsigned long crc_update(unsigned long crc, byte data)
{
    byte tbl_idx;
    tbl_idx = crc ^ (data >> (0 * 4));
    crc = pgm_read_dword_near(crc_table + (tbl_idx & 0x0f)) ^ (crc >> 4);
    tbl_idx = crc ^ (data >> (1 * 4));
    crc = pgm_read_dword_near(crc_table + (tbl_idx & 0x0f)) ^ (crc >> 4);

    return crc;
}
void setup()
{
  Serial.begin(115200);
  GD.begin();
  GD.ascii();
  GD.putstr(0, 0, "memloader");
}

static byte get1()
{
  while (!Serial.available())
    ;
  return Serial.read();
}

static uint16_t get2()
{
  int r = get1();
  return (r << 8) + get1();
}

static void crc_mem(uint16_t a, uint16_t n)
{
  unsigned long crc = ~0;
  GD.__start(a);
  while (n--)
    crc = crc_update(crc, SPI.transfer(0));
  GD.__end();
  crc = ~crc;
  Serial.write(crc >> 24);
  Serial.write(crc >> 16);
  Serial.write(crc >> 8);
  Serial.write(crc);
}

static byte mirror[256];
static void copycoll()
{
  GD.waitvblank();
  GD.waitvblank();

  GD.__start(COLLISION);
  int i;
  for (i = 0; i < 256; i++)
    mirror[i] = SPI.transfer(0);
  GD.__end();
}

void loop()
{
  int i;

  // Commands arrive on the serial connection, and trigger various SPI
  // actions.  The commands are:
  //
  //  len addr         block read/write, depending on hi bit of addr
  //  0 'L' yy         line CRC.  Captures line yy, returns the CRC32
  //  0 'c'            COLLISION dump.  Returns the 256 bytes of COLLISION
  //  0 'C'            COLLISION CRC.  Returns the CRC32 of COLLISION
  //  0 'M' addr len   RAM CRC.  Returns the CRC32 of len bytes at addr

  byte len = get1();
  if (len) {
    unsigned short addr;
    addr = get2();
    GD.__start(addr);
    if (addr & 0x8000) {
      while (len--)
        SPI.transfer(get1());
    } else {
      while (len--)
        Serial.write(SPI.transfer(0));
    }
    GD.__end();
  } else switch (get1()) {
    case 'L': {   // one-line CRC
      unsigned int yy;
      yy = get2();

      GD.wr16(SCREENSHOT_Y, 0x8000 | yy);
      while ((GD.rd(SCREENSHOT_Y + 1) & 0x80) == 0)
        ;

      crc_mem(SCREENSHOT, 800);
      GD.wr16(SCREENSHOT_Y, 0);
      break;
    }
    case 'F': {   // full-screen CRC
      unsigned int yy;
      for (yy = 0; yy < 300; yy++) {
        GD.wr16(SCREENSHOT_Y, 0x8000 | yy);
        while ((GD.rd(SCREENSHOT_Y + 1) & 0x80) == 0)
          ;

        crc_mem(SCREENSHOT, 800);
      }
      GD.wr16(SCREENSHOT_Y, 0);
      break;
    }
    case 'c': {
      copycoll();
      for (i = 0; i < 256; i++) {
        Serial.write(mirror[i]);
      }
      break;
    }
    case 'C': {
      copycoll();

      unsigned long crc = ~0;
      for (i = 0; i < 256; i++)
        crc = crc_update(crc, mirror[i]);
      crc = ~crc;
      Serial.write(crc >> 24);
      Serial.write(crc >> 16);
      Serial.write(crc >> 8);
      Serial.write(crc);
      break;
    }
    case 'M': {
      uint16_t a = get2();
      uint16_t s = get2();
      crc_mem(a, s);
    }
  }
}
