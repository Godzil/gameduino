#include <SPI.h>
#include <GD.h>


// ----------------------------------------------------------------------
//     qrand: quick random numbers
// ----------------------------------------------------------------------

static uint16_t lfsr = 1;

static void qrandSeed(int seed)
{
  if (seed) {
    lfsr = seed;
  } else {
    lfsr = 0x947;
  }
}

static byte qrand1()    // a random bit
{
  lfsr = (lfsr >> 1) ^ (-(lfsr & 1) & 0xb400);
  return lfsr & 1;
}

static byte qrand(byte n) // n random bits
{
  byte r = 0;
  while (n--)
    r = (r << 1) | qrand1();
  return r;
}

// ----------------------------------------------------------------------
//     controller: buttons on Arduino pins 3,4,5,6
// ----------------------------------------------------------------------

static void controller_init()
{
  // Configure input pins with internal pullups
  byte i;
  for (i = 3; i < 7; i++) {
    pinMode(i, INPUT);
    digitalWrite(i, HIGH);
  }
}

#define CONTROL_LEFT  1
#define CONTROL_RIGHT 2
#define CONTROL_UP    4
#define CONTROL_DOWN  8


static byte controller_sense(uint16_t clock)
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

// Swap color's red and blue channels
uint16_t swapRB(uint16_t color)
{
    byte r = 31 & (color >> 10);
    byte g = 31 & (color >> 5);
    byte b = 31 & color;
    return (color & 0x8000) | (b << 10) | (g << 5) | r;
}

// Swap color's red and green channels
uint16_t swapRG(uint16_t color)
{
    byte r = 31 & (color >> 10);
    byte g = 31 & (color >> 5);
    byte b = 31 & color;
    return (color & 0x8000) | (g << 10) | (r << 5) | b;
}

#include "asteroidgraphics.h"
#include "splitscreen.h"

static void update_score();

// [int(127 * math.sin(math.pi * 2 * i / 16)) for i in range(16)]
static PROGMEM prog_uchar charsin[16] = {0, 48, 89, 117, 127, 117, 89, 48, 0, -48, -89, -117, -127, -117, -89, -48};
#define qsin(a) (signed char)pgm_read_byte_near(charsin + ((a) & 15))
#define qcos(a) qsin((a) + 4)

static char spr2obj[256];   // Maps sprites to owning objects

/*

The general idea is that an object table ``objects`` has an entry for
each drawn thing on screen (e.g. player, missile, rock, explosion).
Each class of object has a ``handler`` function that does the necessary
housekeeping and draws the actual sprites.

As part of the behavior, some classes need to know if they have collided
with anything. In particular the rocks need to know if they have collided
with the player or a missile.  The `collide` member points to the
colliding sprite.

*/

struct object {
  int x, y;
  byte handler, state;
  byte collide;
} objects[128];
#define COORD(c) ((c) << 4)

static char explosions = -1;
static char enemies = -1;
static char missiles = -1;

static void push(char *stk, byte i)
{
  objects[i].state = *stk;
  *stk = i;
}

static char pop(char *stk)
{
  char r = *stk;
  if (0 <= r) {
    *stk = objects[r].state;
  }
  return r;
}

byte rr[4] = { 0,3,6,5 };

static struct {
  byte boing, boom, pop;
  byte thrust;
  byte bass;
} sounds;

static int player_vx, player_vy;  // Player velocity
static int player_invincible, player_dying;
static byte lives;
static long score;
static byte level;

// Move object po by velocity (vx, vy), optionally keeping in
// player's frame.
// Returns true if the object wrapped screen edge
static bool move(struct object *po, char vx, char vy, byte playerframe = 1)
{
    bool r = 0;
    if (playerframe) {
      po->x += (vx - player_vx);
      po->y += (vy - player_vy);
    } else {
      po->x += vx;
      po->y += vy;
    }

    if (po->x > COORD(416))
      r = 1, po->x -= COORD(432);
    else if (po->x < COORD(-16))
      r = 1, po->x += COORD(432);

    if (po->y > COORD(316))
      r = 1, po->y -= COORD(332);
    else if (po->y < COORD(-16))
      r = 1, po->y += COORD(332);
    return r;
}


#define HANDLE_NULL 0
#define HANDLE_ROCK0 1
#define HANDLE_ROCK1 2
#define HANDLE_BANG0 3
#define HANDLE_BANG1 4
#define HANDLE_PLAYER 5
#define HANDLE_MISSILE 6

// Expire object i, and return it to the free stk
static void expire(char *stk, byte i)
{
  objects[i].handler = HANDLE_NULL;
  push(stk, i);
}

static void handle_null(byte i, byte state, uint16_t clock)
{
}

static void handle_player(byte i, byte state, uint16_t clock)
{
  struct object *po = &objects[i];
  byte angle = (po->state & 15);
  byte rot1 = (angle & 3);
  byte rot2 = rr[3 & (angle >> 2)];
  if (!player_dying && (player_invincible & 1) == 0)
    draw_player(200, 150, rot1, rot2);

  static byte prev_control;
  byte control = controller_sense(clock);

  char thrust_x, thrust_y;
  if (!player_dying && control & CONTROL_DOWN) { // thrust
    byte flame_angle = angle ^ 8;
    byte d;
    for (d = 9; d > 5; d--) {
      int flamex = 201 - (((d + (clock&3)) * qsin(flame_angle)) >> 5);
      int flamey = 150 - (((d + (clock&3)) * qcos(flame_angle)) >> 5);
      if ((player_invincible & 1) == 0)
        draw_sparkr(flamex, flamey, rot1, rot2, 1);   // collision class K
    }
    thrust_x = -qsin(angle);
    thrust_y = -qcos(angle);
    sounds.thrust = 1;
  } else {
    thrust_x = thrust_y = 0;
    sounds.thrust = 0;
  }

  player_vx = ((31 * player_vx) + thrust_x) / 32;
  player_vy = ((31 * player_vy) + thrust_y) / 32;

  po->x += player_vx;
  po->y += player_vy;

  if (clock & 1) {
    char rotate = (512 - analogRead(0)) / 400;
    if (control & CONTROL_LEFT)
      rotate++;
    if (control & CONTROL_RIGHT)
      rotate--;
    po->state = ((angle + rotate) & 15);
  }

  if (!player_dying &&
      !(prev_control & CONTROL_UP) &&
      (control & CONTROL_UP)) { // shoot!
    char e = pop(&missiles);
    if (0 <= e) {
      objects[e].x = COORD(200);
      objects[e].y = COORD(150);
      objects[e].state = po->state;
      objects[e].handler = HANDLE_MISSILE;
    }
    sounds.boing = 1;
  }
  prev_control = control;
  if (player_invincible)
    --player_invincible;
  if (player_dying) {
    if (--player_dying == 0) {
      --lives;
      update_score();
      if (lives != 0) {
        player_invincible = 48;
      }
    }
  }
}

static void handle_missile(byte i, byte state, uint16_t clock)
{
  struct object *po = &objects[i];
  byte angle = (po->state & 15);
  byte rot1 = (angle & 3);
  byte rot2 = rr[3 & (angle >> 2)];
  draw_sparkr(po->x >> 4, po->y >> 4, rot1, rot2);
  char vx = -qsin(po->state), vy = -qcos(po->state);
  if (move(po, vx, vy, 0)) {
    expire(&missiles, i);
  }
}

static void explodehere(struct object *po, byte handler, uint16_t clock)
{
  char e = pop(&explosions);
  if (0 <= e) {
    objects[e].x = po->x;
    objects[e].y = po->y;
    objects[e].handler = handler;
    objects[e].state = clock;
  }
}

static void killplayer(uint16_t clock)
{
  if (!player_invincible && !player_dying) {
    char e = pop(&explosions);
    if (0 <= e) {
      objects[e].x = COORD(200);
      objects[e].y = COORD(150);
      objects[e].handler = HANDLE_BANG1;
      objects[e].state = clock;
    }
    player_dying = 2 * 36;
    sounds.boom = 1;
    sounds.pop = 1;
  }
}

static byte commonrock(uint16_t clock, byte i, byte speed, void df(int x, int y, byte anim, byte rot, byte jk))
{
  struct object *po = &objects[i];

  byte move_angle = po->state >> 4;
  char vx = (speed * -qsin(move_angle)) >> 6, vy = (speed * -qcos(move_angle)) >> 6;
  move(po, vx, vy);

  byte angle = (clock * speed) >> 4;
  if (po->state & 1)
    angle = ~angle;
  byte rot1 = (angle & 3);
  byte rot2 = rr[3 & (angle >> 2)];
  df(po->x >> 4, po->y >> 4, rot1, rot2, 1);
  if (po->collide != 0xff) {
    struct object *other = &objects[po->collide];
    switch (other->handler) {
    case HANDLE_PLAYER:
      killplayer(clock);
      break;
    case HANDLE_MISSILE:
      expire(&missiles, po->collide);   // missile is dead
      expire(&enemies, i);
      return 1;
    }
  }
  return 0;
}

static void handle_rock0(byte i, byte state, uint16_t clock)
{
  struct object *po = &objects[i];
  byte speed = 12 + (po->state & 7);
  if (commonrock(clock, i, speed, draw_rock0r)) {
    explodehere(po, HANDLE_BANG0, clock);
    score += 10;
    sounds.pop = 1;
  }
}

static void handle_rock1(byte i, byte state, uint16_t clock)
{
  struct object *po = &objects[i];
  byte speed = 6 + (po->state & 3);
  if (commonrock(clock, i, speed, draw_rock1r)) {
    int j;
    for (j = 0; j < 4; j++) {
      char e = pop(&enemies);
      if (0 < e) {
        objects[e].x = po->x;
        objects[e].y = po->y;
        objects[e].handler = HANDLE_ROCK0;
        objects[e].state = (j << 6) + qrand(6);   // spread fragments across 4 quadrants
      }
    }
    explodehere(po, HANDLE_BANG1, clock);
    score += 30;
    sounds.boom = 1;
  }
}

static void handle_bang0(byte i, byte state, uint16_t clock)
{
  struct object *po = &objects[i];
  move(po, 0, 0);
  byte anim = ((0xff & clock) - state) >> 1;
  if (anim < EXPLODE16_FRAMES)
    draw_explode16(po->x >> 4, po->y >> 4, anim, 0);
  else
    expire(&explosions, i);
}

static void handle_bang1(byte i, byte state, uint16_t clock)
{
  struct object *po = &objects[i];
  move(po, 0, 0);
  byte anim = ((0xff & clock) - state) >> 1;
  byte rot = 7 & i;
  if (anim < EXPLODE32_FRAMES)
    draw_explode32(po->x >> 4, po->y >> 4, anim, rot);
  else
    expire(&explosions, i);
}

typedef void (*handler)(byte, byte, uint16_t);
static handler handlers[] = {
  handle_null,
  handle_rock0,
  handle_rock1,
  handle_bang0,
  handle_bang1,
  handle_player,
  handle_missile
};

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

static GDflashbits GDFB;

static void GD_uncompress(unsigned int addr, PROGMEM prog_uchar *src)
{
  GDFB.begin(src);
  byte b_off = GDFB.getn(4);
  byte b_len = GDFB.getn(4);
  byte minlen = GDFB.getn(2);
  unsigned short items = GDFB.getn(16);
  while (items--) {
    if (GDFB.get1() == 0) {
      GD.wr(addr++, GDFB.getn(8));
    } else {
      int offset = -GDFB.getn(b_off) - 1;
      int l = GDFB.getn(b_len) + minlen;
      while (l--) {
        GD.wr(addr, GD.rd(addr + offset));
        addr++;
      }
    }
  }
}

// uncompress one line of the title banner into buffer dst
// title banner lines are run-length encoded
static void titlepaint(char *dst, byte src, byte mask)
{
  if (src != 0xff) {
    prog_uchar *psrc = title_runs + 2 * src;
    byte a, b;
    do {
      a = pgm_read_byte_near(psrc++);
      b = pgm_read_byte_near(psrc++);
      while (a < (b & 0x7f))
        dst[a++] |= mask;
    } while (!(b & 0x80));
  }
}

// draw a title banner column src (0-511) to screen column dst (0-63).
static void column(byte dst, byte src)
{
  static char scratch[76];
  memset(scratch, 0, sizeof(scratch));
  byte line = pgm_read_byte_near(title + 2 * src);
  titlepaint(scratch, line, 1);
  line = pgm_read_byte_near(title + 2 * src + 1);
  titlepaint(scratch, line, 2);

  byte j;
  for (j = 0; j < 38; j++) {
    GD.wr(dst + (j << 6),
          (((dst + j) & 15) << 4) +
          scratch[2 * j] +
          (scratch[2 * j + 1] << 2));
  }
}

static void setup_sprites()
{
  GD.copy(PALETTE16A, palette16a, sizeof(palette16a));
  GD.copy(PALETTE4A, palette4a, sizeof(palette4a));
  GD.copy(PALETTE16B, palette16b, sizeof(palette16b));

  // Use the first two 256-color palettes as pseudo-16 color palettes
  int i;
  for (i = 0; i < 256; i++) {

    // palette 0 decodes low nibble, hence (i & 15)
    uint16_t rgb = pgm_read_word_near(palette256a + ((i & 15) << 1));
    GD.wr16(RAM_SPRPAL + (i << 1), rgb);

    // palette 1 decodes nigh nibble, hence (i >> 4)
    rgb = pgm_read_word_near(palette256a + ((i >> 4) << 1));
    GD.wr16(RAM_SPRPAL + 512 + (i << 1), rgb);
  }

  GD_uncompress(RAM_SPRIMG, asteroid_images_compressed);
  GD.wr(JK_MODE, 1);
}

// Run the object handlers, keeping track of sprite ownership in spr2obj
static void runobjects(uint16_t r)
{
  int i;
  GD.__wstartspr((r & 1) ? 256 : 0);  // write sprites to other frame
  for (i = 0; i < 128; i++) {
    struct object *po = &objects[i];
    handler h = (handler)handlers[po->handler];
    byte loSpr = GD.spr;
    (*h)(i, po->state, r);
    while (loSpr < GD.spr) {
      spr2obj[loSpr++] = i;
    }
  }
  // Hide all the remaining sprites
  do
    GD.xhide();
  while (GD.spr);
  GD.__end();
}

// ----------------------------------------------------------------------
//     map
// ----------------------------------------------------------------------

static byte loaded[8];
static byte scrap;

// copy a (w,h) rectangle from the source image (x,y) into picture RAM
static void rect(unsigned int dst, byte x, byte y, byte w, byte h)
{
  prog_uchar *src = bg_pic + (16 * y) + x;
  while (h--) {
    GD.copy(dst, src, w);
    dst += 64;
    src += 16;
  }
}

static void map_draw(byte strip)
{
  strip &= 63;              // Universe is finite but unbounded: 64 strips
  byte s8 = (strip & 7);    // Destination slot for this strip (0-7)
  if (loaded[s8] != strip) {
    qrandSeed(level ^ (strip * 77));    // strip number is the hash...

    // Random star pattern is made from characters 1-15
    GD.__wstart(s8 * (8 * 64));
    int i;
    for (i = 0; i < (8 * 64); i++) {
      byte r;
      if (qrand(3) == 0)
        r = qrand(4);
      else
        r = 0;
      SPI.transfer(r);
    }
    GD.__end();

    // Occasional planet, copied from the background char map
    if (qrand(2) == 0) {
      uint16_t dst = (qrand(3) * 8) + (s8 * (8 * 64));
      switch (qrand(2)) {
      case 0:
        rect(dst, 0, 1, 6, 6);
        break;
      case 1:
        rect(dst, 7, 1, 6, 6);
        break;
      case 2:
        rect(dst, 0, 7, 8, 4);
        break;
      case 3:
        rect(dst, 8, 7, 5, 5);
        break;
      }
    }
    loaded[s8] = strip;
  }
}

static void map_coldstart()
{
  memset(loaded, 0xff, sizeof(loaded));
  scrap = 0xff;
  byte i;
  for (i = 0; i < 8; i++)
    map_draw(i);
}

static int atxy(int x, int y)
{
  return (y << 6) + x;
}

static void update_score()
{
  prog_uchar* digitcodes = bg_pic + (16 * 30);
  unsigned long s = score;
  uint16_t a = atxy(49, scrap << 3);
  byte i;
  for (i = 0; i < 6; i++) {
    GD.wr(a--, pgm_read_byte_near(digitcodes + (s % 10)));
    s /= 10;
  }
  GD.wr(atxy(0, scrap << 3), pgm_read_byte_near(digitcodes + lives));
}

static void map_refresh(byte strip)
{
  byte i;
  byte newscrap = 7 & (strip + 7);
  if (scrap != newscrap) {
    scrap = newscrap;

    uint16_t scrapline = scrap << 6;
    GD.wr16(COMM+2, 0x8000 | scrapline);    // show scrapline at line 0
    GD.wr16(COMM+14, 0x8000 | (0x1ff & ((scrapline + 8) - 291))); // show scrapline+8 at line 291

    GD.fill(atxy(0, scrap << 3), 0, 50);
    update_score();

    GD.fill(atxy(0, 1 + (scrap << 3)), 0, 64);
    rect(atxy(0, 1 + (scrap << 3)), 0, 31, 16, 1);
    rect(atxy(32, 1 + (scrap << 3)), 0, 31, 16, 1);

    loaded[scrap] = 0xff;
  }
  delay(1);   // wait for raster to pass the top line before overwriting it
  for (i = 0; i < 6; i++)
    map_draw(strip + i);
}

static void start_level()
{
  int i;

  for (i = 0; i < 128; i++)
    objects[i].handler = 0;

  player_vx = 0;
  player_vy = 0;
  player_invincible = 0;
  player_dying = 0;

  objects[0].x = 0;
  objects[0].y = 0;
  objects[0].state = 0;
  objects[0].handler = HANDLE_PLAYER;

  // Set up the pools of objects for missiles, enemies, explosions
  missiles = 0;
  enemies = 0;
  explosions = 0;
  for (i = 1; i < 16; i++)
    push(&missiles, i);
  for (i = 16; i < 80; i++)
    push(&enemies, i);
  for (i = 80; i < 128; i++)
    push(&explosions, i);

  // Place asteroids in a ring around the edges of the screen
  for (i = 0; i < min(32, 3 + level); i++) {
    char e = pop(&enemies);
    if (random(2) == 0) {
      objects[e].x = random(2) ? COORD(32) : COORD(400-32);
      objects[e].y = random(COORD(300));
    } else {
      objects[e].x = random(COORD(400));
      objects[e].y = random(2) ? COORD(32) : COORD(300-32);
    }
    objects[e].handler = HANDLE_ROCK1;
    objects[e].state = qrand(8);
  }

  GD.copy(PALETTE16B, palette16b, sizeof(palette16b));
  for (i = 0; i < 16; i++) {
    uint16_t a = PALETTE16B + 2 * i;
    uint16_t c = GD.rd16(a);
    if (level & 1)
      c = swapRB(c);
    if (level & 2)
      c = swapRG(c);
    if (level & 4)
      c = swapRB(c);
    GD.wr16(a, c);
  }

  map_coldstart();
}

void setup()
{

  GD.begin();
  controller_init();

}

static void title_banner()
{
  GD.fill(VOICES, 0, 64 * 4);
  GD.wr(J1_RESET, 1);
  GD.wr(SPR_DISABLE, 1);
  GD.wr16(SCROLL_X, 0);
  GD.wr16(SCROLL_Y, 0);
  GD.fill(RAM_PIC, 0, 4096);
  setup_sprites();

  uint16_t i;
  uint16_t j;

  GD.__wstart(RAM_CHR);
  for (i = 0; i < 256; i++) {
    // bits control lit segments like this:
    //   0   1
    //   2   3
    byte a = (i & 1) ? 0x3f : 0;
    byte b = (i & 2) ? 0x3f : 0;
    byte c = (i & 4) ? 0x3f : 0;
    byte d = (i & 8) ? 0x3f : 0;
    for (j = 0; j < 3; j++) {
      SPI.transfer(a);
      SPI.transfer(b);
    }
    SPI.transfer(0);
    SPI.transfer(0);
    for (j = 0; j < 3; j++) {
      SPI.transfer(c);
      SPI.transfer(d);
    }
    SPI.transfer(0);
    SPI.transfer(0);
  }
  GD.__end();
  for (i = 0; i < 256; i++) {
    GD.setpal(4 * i + 0, RGB(0,0,0));
    uint16_t color = pgm_read_word_near(title_ramp + 2 * (i >> 4));
    GD.setpal(4 * i + 3, color);
  }
  for (i = 0; i < 64; i++) {
    column(i, i);
  }

  for (i = 0; i < 128; i++) {
    objects[i].handler = 0;
    objects[i].collide = 0xff;
  }

  for (i = 0; i < 128; i++)
    push(&enemies, i);

  for (i = 0; i < 40; i++) {
    char e = pop(&enemies);
    objects[e].x = COORD(random(400));
    objects[e].y = COORD(random(300));
    objects[e].handler = qrand1() ? HANDLE_ROCK1 : HANDLE_ROCK0;
    objects[e].state = qrand(8);
  }

  byte startgame = 0;
  for (i = 0; startgame < 50; i++) {
    for (j = 0; j < 256; j++) {
      byte index = 15 & ((-i >> 2) + (j >> 4));
      uint16_t color = pgm_read_word_near(title_ramp + 2 * index);
      GD.setpal(4 * j + 3, color);
    }
    if (!startgame &&
        (controller_sense(i) || (i == (2048 - 400)))) {
      // explode all rocks!
      for (j = 0; j < 128; j++) {
        byte h = objects[j].handler;
        if ((h == HANDLE_ROCK0) || (h == HANDLE_ROCK1))
          objects[j].handler = HANDLE_BANG1;
          objects[j].state = i;
        }
      startgame = 1;
    }
    if (startgame)
      startgame++;
    runobjects(i);
    GD.waitvblank();
    GD.wr(SPR_PAGE, (i & 1));
    GD.wr(SPR_DISABLE, 0);
    GD.wr16(SCROLL_X, i);
    if ((i & 7) == 0) {
      byte x = ((i >> 3) + 56);
      column(63 & x, 255 & x);
    }
  }

  for (i = 0; i < 32; i++) {
    for (j = 0; j < 256; j++) {
      uint16_t a = RAM_PAL + (8 * j) + 6;
      uint16_t pal = GD.rd16(a);
      byte r = 31 & (pal >> 10);
      byte g = 31 & (pal >> 5);
      byte b = 31 & pal;
      if (r) r--;
      if (g) g--;
      if (b) b--;
      pal = (r << 10) | (g << 5) | b;
      GD.wr16(a, pal);
    }
    GD.waitvblank();
    GD.waitvblank();
  }

  GD.fill(RAM_PIC, 0, 4096);
}

#define SOUNDCYCLE(state) ((state) = v ? ((state) + 1) : 0)

void loop()
{
  title_banner();

  GD_uncompress(RAM_CHR, bg_chr_compressed);
  GD_uncompress(RAM_PAL, bg_pal_compressed);

  GD.wr16(COMM+0, 0);
  GD.wr16(COMM+2, 0x8000);
  GD.wr16(COMM+4, 8);   // split at line 8
  GD.wr16(COMM+6, 177);
  GD.wr16(COMM+8, 166);
  GD.wr16(COMM+10, 291);   // split at line 291
  GD.wr16(COMM+12, 0);
  GD.wr16(COMM+14, 0x8000 | (0x1ff & (8 - 291))); // show line 8 at line 292
  GD.microcode(splitscreen_code, sizeof(splitscreen_code));

  setup_sprites();


  memset(&sounds, 0, sizeof(sounds));
  level = 0;
  score = 0;
  lives = 3;
  unsigned int r = 0;
  start_level();

  while (lives) {
    int i, j;

    runobjects(r);

    for (i = 0; i < 128; i++)
      objects[i].collide = 0xff;

    GD.waitvblank();
    // swap frames
    GD.wr(SPR_PAGE, (r & 1));
    int scrollx = objects[0].x >> 4;
    int scrolly = objects[0].y >> 4;
    GD.wr16(COMM+6, scrollx & 0x1ff);
    GD.wr16(COMM+8, scrolly & 0x1ff);
    map_refresh(scrolly >> 6);
    update_score();
    GD.wr16(COMM+12, r);    // horizontal scroll the bottom banner

    GD.waitvblank();

    GD.__start(COLLISION);
    for (i = 0; i < 256; i++) {
      byte c = SPI.transfer(0);   // c is the colliding sprite number
      if (c != 0xff) {
        objects[spr2obj[i]].collide = spr2obj[c];
      }
    }
    GD.__end();

    if (sounds.boing) {
      byte v = max(0, 16 - (sounds.boing - 1) * 2);
      GD.voice(0, 0, 4 * 4000 - 700 * sounds.boing, v/2, v/2);
      GD.voice(1, 1, 1000 - 100 * sounds.boing, v, v);
      SOUNDCYCLE(sounds.boing);
    }
    if (sounds.boom) {
      byte v = max(0, 96 - (sounds.boom - 1) * 6);
      GD.voice(2, 0, 220, v, v);
      GD.voice(3, 1, 220/8, v/2, v/2);
      SOUNDCYCLE(sounds.boom);
    }
    if (sounds.pop) {
      byte v = max(0, 32 - (sounds.pop - 1) * 3);
      GD.voice(4, 0, 440, v, v);
      GD.voice(5, 1, 440/8, v/2, v/2);
      SOUNDCYCLE(sounds.pop);
    }
    GD.voice(6, 1, 40, sounds.thrust ? 10 : 0, sounds.thrust ? 10 : 0);

    static byte tune;
    if (sounds.bass) {
      byte v = sounds.bass < 9 ? 63 : 0;
      int f0 = tune ? 130: 163 ;
      byte partials[] = { 71, 32, 14, 75, 20, 40 };
      byte i;
      for (i = 0; i < 6; i++) {
        byte a = (v * partials[i]) >> 8;
        GD.voice(7 + i, 0, f0 * (i + 1), a, a);
      }
      SOUNDCYCLE(sounds.bass);
    }
    static byte rhythm;
    if (++rhythm >= max(24 - level, 10)) {
      sounds.bass = 1;
      rhythm = 0;
      tune = !tune;
    }

    byte nenemies = 64;
    byte pe = enemies;
    while (pe) {
      pe = objects[pe].state;
      nenemies--;
    }
    if (nenemies == 0) {
      level++;
      start_level();
    }

    r++;
  }
}
