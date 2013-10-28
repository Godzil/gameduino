#define STAGEBASE 568

#if 0
static PROGMEM prog_uint32_t crc_table[16] = {
    0x00000000, 0x1db71064, 0x3b6e20c8, 0x26d930ac,
    0x76dc4190, 0x6b6b51f4, 0x4db26158, 0x5005713c,
    0xedb88320, 0xf00f9344, 0xd6d6a3e8, 0xcb61b38c,
    0x9b64c2b0, 0x86d3d2d4, 0xa00ae278, 0xbdbdf21c
};

unsigned long crc_update(unsigned long crc, byte data)
{
  uint_farptr_t tab = GET_FAR_ADDRESS(crc_table);

  byte tbl_idx;
  tbl_idx = crc ^ data;
  crc = pgm_read_dword_far(tab + 4 * (tbl_idx & 0x0f)) ^ (crc >> 4);
  tbl_idx = crc ^ (data >> 4);
  crc = pgm_read_dword_far(tab + 4 * (tbl_idx & 0x0f)) ^ (crc >> 4);

  return crc;
}
#else
static uint32_t crc_table[16] = {
    0x00000000, 0x1db71064, 0x3b6e20c8, 0x26d930ac,
    0x76dc4190, 0x6b6b51f4, 0x4db26158, 0x5005713c,
    0xedb88320, 0xf00f9344, 0xd6d6a3e8, 0xcb61b38c,
    0x9b64c2b0, 0x86d3d2d4, 0xa00ae278, 0xbdbdf21c
};

unsigned long crc_update(unsigned long crc, byte data)
{
  byte tbl_idx;
  tbl_idx = crc ^ data;
  crc = crc_table[tbl_idx & 0x0f] ^ (crc >> 4);
  tbl_idx = crc ^ (data >> 4);
  crc = crc_table[tbl_idx & 0x0f] ^ (crc >> 4);

  return crc;
}
#endif

class GDflashbits {
public:
  void begin(prog_uchar *s) {
    src = s;
    mask = 0x01;
  }
  byte get1(void) {
    byte r = (pgm_read_byte_near(src) & mask) != 0;
    mask <<= 1;
    if (!mask) {
      mask = 1;
      src++;
    }
    return r;
  }
  unsigned short getn(byte n) {
    unsigned short r = 0;
    while (n--) {
      r <<= 1;
      r |= get1();
    }
    return r;
  }
private:
  prog_uchar *src;
  byte mask;
};

#if defined(__AVR_ATmega1280__) || defined(__AVR_ATmega2560__)
// far ptr version
class GDflashbitsF {
public:
  void begin(uint_farptr_t s) {
    src = s;
    mask = 8;
    m = pgm_read_byte_far(src++);
  }
  byte get1(void) {
    byte r = (m & 1);
    m >>= 1;
    if (--mask == 0) {
      mask = 8;
      m = pgm_read_byte_far(src++);
    }
    return r;
  }
  unsigned short getn(byte n) {
    unsigned short r = 0;
    while (n--) {
      r <<= 1;
      r |= get1();
    }
    return r;
  }
private:
  uint_farptr_t src;
  byte m, mask;
};
#endif

static byte history[264], hp;

int page, offset;

#define FLOCAL 2

#define SEL_local() digitalWrite(FLOCAL, LOW)
#define UNSEL_local() digitalWrite(FLOCAL, HIGH)

#define spix(n) SPI.transfer(n)

static void spipage(int n)
{
  spix(n >> 7);
  spix(n << 1);
  spix(0);
}

static byte status()
{
  SEL_local();
  spix(0xd7);   // read SPI flash status
  byte status = spix(0);
  UNSEL_local();
  return status;
}

static void UNSEL_local_wait()
{
  UNSEL_local();
  while ((status() & 0x80) == 0)
    ;
}

static void pgcmd(byte cmd, int page)
{
  SEL_local();
  spix(cmd);
  spipage(page);
}

static void supply(byte b)
{
  history[hp++] = b;

  if (offset == 0) {
    if ((page & 7) == 0) {
      pgcmd(0x50, page);
      UNSEL_local_wait();
    }
    pgcmd(0x84, page);
  }
  spix(b);
  if (++offset == 264) {
    UNSEL_local();

    pgcmd(0x88, page++);
    UNSEL_local_wait();
    offset = 0;
  }
}

#if defined(__AVR_ATmega1280__) || defined(__AVR_ATmega2560__)
static GDflashbitsF GDFB;
static void GD_uncompress(uint_farptr_t src)
#else
static GDflashbits GDFB;
static void GD_uncompress(PROGMEM prog_uchar *src)
#endif
{
  GDFB.begin(src);
  byte b_off = GDFB.getn(4);
  byte b_len = GDFB.getn(4);
  byte minlen = GDFB.getn(2);
  unsigned short items = GDFB.getn(16);
  hp = 0;
  offset = 0;
  while (items--) {
    if (GDFB.get1() == 0) {
      supply(GDFB.getn(8));
    } else {
      int offset = -GDFB.getn(b_off) - 1;
      int l = GDFB.getn(b_len) + minlen;
      while (l--) {
        supply(history[0xff & (hp + offset)]);
      }
    }
  }
}

static unsigned long flash_crc(int page, int n)
{
  SEL_local();
  SPI.transfer(0x03);
  spipage(page);

  unsigned long crc = ~0;
  unsigned long len = 264L * n;
  while (len--) {
    byte b = spix(0);
    crc = crc_update(crc, b);
  }
  crc = ~crc;
  UNSEL_local();
  return crc;
}

static unsigned long flash_sum(int page, int n)
{
  SEL_local();
  SPI.transfer(0x03);
  spipage(page);

  unsigned long sum = 0;
  unsigned long len = 264L * n;
  while (len--) {
    byte b = spix(0);
    sum = sum + b;
  }
  UNSEL_local();
  return sum;
}


#ifdef P0OFF
static byte ready(byte part, int sb = STAGEBASE)
{
  switch (part) {
  case 0: return flash_crc(sb + P0OFF, P0SIZE) == P0CRC;
  case 1: return flash_crc(sb + P1OFF, P1SIZE) == P1CRC;
  case 2: return flash_crc(sb + P2OFF, P2SIZE) == P2CRC;
  case 3: return flash_crc(sb + P3OFF, P3SIZE) == P3CRC;
  case 4: return flash_crc(P4OFF, P4SIZE) == P4CRC;
  }
  return 0;
}

static int atxy(int x, int y)
{
  return (y << 6) + x;
}

static void common_show_status()
{
  for (byte i = 0; i < 5; i++) {
    byte y = 10 + 2 * i;
    GD.putstr(0, y, "part ");
    GD.wr(atxy(6, y), '0' + i);
    GD.putstr(25, y, ready(i) ? "OK" : "--");
  }
}

static int ready0123(int sb)
{
  return ready(0, sb) && ready(1, sb) && ready(2, sb) && ready(3, sb);
}

#endif

static void common_setup(byte part)
{
  GD.begin();

  GD.wr(IOMODE, 'F');
  pinMode(2, OUTPUT);
  digitalWrite(2, HIGH);
  GD.ascii();

#ifdef REVISION
  // avoid sprintf because it bloats executable

  GD.putstr(0, 0, "Flash loader");

  char revmsg[] = "Firmware X.X";
  revmsg[9] = '0' + (REVISION >> 4);
  revmsg[11] = '0' + (REVISION & 0xf);
  GD.putstr(0, 2, revmsg);

  char partmsg[] = "part X";
  partmsg[5] = '0' + part;
  GD.putstr(0, 4, partmsg);

  GD.putstr(0, 8, "loading");
  GD.putstr(8, 8, partmsg);
  common_show_status();
#endif
}
