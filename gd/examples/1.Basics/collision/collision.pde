#include <SPI.h>
#include <GD.h>

void readn(byte *dst, unsigned int addr, int c)
{
  GD.__start(addr);
  while (c--)
    *dst++ = SPI.transfer(0);
  GD.__end();
}

#define NBALLS 80

static byte coll[NBALLS];
static void load_coll()
{
  while (GD.rd(VBLANK) == 0)  // Wait until vblank
    ;
  while (GD.rd(VBLANK) == 1)  // Wait until display
    ;
  while (GD.rd(VBLANK) == 0)  // Wait until vblank
    ;
  readn(coll, COLLISION, NBALLS);
}

struct ball {
  int x, y;
  signed char vx, vy;
  byte lasthit;
};

static struct ball balls[NBALLS];

#include "stone_wall_texture.h" // texture from 3dmd.net project
#include "sphere.h"

static void plot_balls()
{
  byte i;
  for (i = 0; i < NBALLS; i++)
    GD.sprite(i, balls[i].x >> 4, balls[i].y >> 4, 0, 0, 0);
}

// Place all balls so that none collide.  Do this by placing all at
// random, then moving until there are no collisions

static byte anycolliding()
{
  plot_balls();
  load_coll();
  byte i;
  for (i = 0; i < NBALLS; i++)
    if (coll[i] != 0xff)
      return 1;
  return 0;
}

static void place_balls()
{
  byte i;
  for (i = 0; i < NBALLS; i++) {
    balls[i].x = (2 + random(380)) << 4;
    balls[i].y = (2 + random(280)) << 4;
    balls[i].vx = random(-128,127);
    balls[i].vy = random(-128,127);
    balls[i].lasthit = 255;
  }
  while (anycolliding()) {
    for (i = 0; i < NBALLS; i++) {
      if (coll[i] != 0xff) {
        balls[i].x = (2 + random(380)) << 4;
        balls[i].y = (2 + random(280)) << 4;
      }
    }
  }
}

void setup()
{
  int i;

  GD.begin();
  
  GD.wr(JK_MODE, 0);

  GD.copy(RAM_CHR, stone_wall_texture_chr, sizeof(stone_wall_texture_chr));
  GD.copy(RAM_PAL, stone_wall_texture_pal, sizeof(stone_wall_texture_pal));
  for (i = 0; i < 4096; i++)
    GD.wr(RAM_PIC + i, (i & 15) + ((i >> 6) << 4));

  GD.copy(RAM_SPRIMG, sphere_img, sizeof(sphere_img));
  GD.copy(RAM_SPRPAL, sphere_pal, sizeof(sphere_pal));

  for (i = 0; i < 256; i++)
    GD.sprite(i, 400, 400, 0, 0, 0);

  place_balls();
}


float dot(float x1, float y1, float x2, float y2)
{
  return (x1 * x2) + (y1 * y2);
}

// Collide ball a with ball b, compute new velocities.
// Algorithm from
// http://stackoverflow.com/questions/345838/ball-to-ball-collision-detection-and-handling

void collide(struct ball *a, struct ball *b)
{
  float collision_x, collision_y;

  collision_x = a->x - b->x;
  collision_y = a->y - b->y;
  float distance = sqrt(collision_x * collision_x + collision_y * collision_y);
  float rdistance = 1.0 / distance;
  collision_x *= rdistance;
  collision_y *= rdistance;
  float aci = dot(a->vx, a->vy, collision_x, collision_y);
  float bci = dot(b->vx, b->vy, collision_x, collision_y);
  float acf = bci;
  float bcf = aci;
  a->vx += int((acf - aci) * collision_x);
  a->vy += int((acf - aci) * collision_y);
  b->vx += int((bcf - bci) * collision_x);
  b->vy += int((bcf - bci) * collision_y);
}

#define LWALL (0 << 4)
#define RWALL (384 << 4)
#define TWALL (0 << 4)
#define BWALL (284 << 4)

static int timer;
void loop()
{
  int i;

  plot_balls();

  load_coll();

  struct ball *pb;

  for (i = NBALLS, pb = balls; i--; pb++, i) {
    if ((pb->x <= LWALL)) {
      pb->x = LWALL;
      pb->vx = -pb->vx;
    }
    if ((pb->x >= RWALL)) {
      pb->x = RWALL;
      pb->vx = -pb->vx;
    }
    if ((pb->y <= TWALL)) {
      pb->y = TWALL;
      pb->vy = -pb->vy;
    }
    if ((pb->y >= BWALL)) {
      pb->y = BWALL;
      pb->vy = -pb->vy;
    }
  }
  for (i = 1; i < NBALLS; i++) {
    byte other = coll[i];
    if ((balls[i].lasthit != other) && other != 0xff) {
      collide(&balls[i], &balls[other]);
    }
    balls[i].lasthit = other;
  }
  for (i = NBALLS, pb = balls; i--; pb++, i) {
    pb->x += pb->vx;
    pb->y += pb->vy;
  }
  if (++timer == 2000) {
    place_balls();
    delay(1000);
    timer = 0;
  }
}
