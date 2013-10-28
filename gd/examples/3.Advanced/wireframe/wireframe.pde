#include <SPI.h>
#include <GD.h>

////////////////////////////////////////////////////////////////////////////////
//                                  Plotter
////////////////////////////////////////////////////////////////////////////////

#include "wireframe.h"
#include "eraser.h"

// replicate a 2-bit color across the whole byte.
byte replicate(byte color)
{
  return (color << 6) | (color << 4) | (color << 2) | color;
}

#define BLACK RGB(0,0,0)
#define WHITE RGB(255,255,255)

class PlotterClass
{
public:
  void begin();
  void line(byte x0, byte y0, byte x1, byte y1);
  void show();
private:
  byte flip;
  byte plotting;
  void erase();
  void waitready();
};

PlotterClass Plotter;

void PlotterClass::waitready()
{
  while (GD.rd(COMM+7))
    ;
}

void PlotterClass::erase()
{
  byte color = flip ? 1 : 2;

  plotting = 0;
  GD.wr(J1_RESET, 1);
  GD.wr(COMM+7, 1);
  GD.wr(COMM+8, replicate(color ^ 3));
  GD.microcode(eraser_code, sizeof(eraser_code));
}

void PlotterClass::begin()
{
  // Draw 256 sprites left to right, top to bottom, all in 4-color
  // palette mode.  By doing them in column-wise order, the address
  // calculation in setpixel is made simpler.
  // First 64 use bits 0-1, next 64 use bits 2-4, etc.
  // This gives a 256 x 256 4-color bitmap.

  unsigned int i;
  for (i = 0; i < 256; i++) {
    int x =     72 + 16 * ((i >> 4) & 15);
    int y =     22 + 16 * (i & 15);
    int image = i & 63;     /* image 0-63 */
    int pal =   3 - (i >> 6);   /* palettes bits in columns 3,2,1,0 */
    GD.sprite(i, x, y, image, 0x8 | (pal << 1), 0);
  }

  flip = 0;
  plotting = 0;
  erase();
  show();
}

void PlotterClass::show()
{
  waitready();
  if (flip == 1) {
    GD.wr16(PALETTE4A, BLACK);
    GD.wr16(PALETTE4A + 2, WHITE);
    GD.wr16(PALETTE4A + 4, BLACK);
    GD.wr16(PALETTE4A + 6, WHITE);
  } else {
    GD.wr16(PALETTE4A, BLACK);
    GD.wr16(PALETTE4A + 2, BLACK);
    GD.wr16(PALETTE4A + 4, WHITE);
    GD.wr16(PALETTE4A + 6, WHITE);
  }
  flip ^= 1;
  erase();
}

void PlotterClass::line(byte x0, byte y0, byte x1, byte y1)
{
  byte swap;
#define SWAP(a, b) (swap = (a), (a) = (b), (b) = swap)

  byte steep = abs(y1 - y0) > abs(x1 - x0);
  if (steep) {
    SWAP(x0, y0);
    SWAP(x1, y1);
  }
  if (x0 > x1) {
    SWAP(x0, x1);
    SWAP(y0, y1);
  }
  int deltax = x1 - x0;
  int deltay = abs(y1 - y0);
  int error = deltax / 2;
  signed char ystep;
  if (y0 < y1)  
    ystep = 1;
  else
    ystep = -1;
  byte x;
  byte y = y0;

  waitready();
  if (!plotting) {
    GD.microcode(wireframe_code, sizeof(wireframe_code));
    plotting = 1;
    byte color = flip ? 1 : 2;
    GD.wr(COMM+8, color << 6);
  }
  GD.__wstart(COMM+0);
  SPI.transfer(x0);
  SPI.transfer(y0);
  SPI.transfer(x1);
  SPI.transfer(y1);
  SPI.transfer(steep);
  SPI.transfer(deltax);
  SPI.transfer(deltay);
  SPI.transfer(ystep);
  GD.__end();
}

////////////////////////////////////////////////////////////////////////////////
//                                  3D Projection
////////////////////////////////////////////////////////////////////////////////

struct ship
{
  const char *name;
  byte nvertices;
  prog_char *vertices;
  byte nedges;
  prog_uchar *edges;
};

#include "eliteships.h"
#define NSHIPS (sizeof(eliteships) / sizeof(eliteships[0]))

static float mat[9];

// Taken from glRotate()
static void rotation(float phi)
{
  float x = 0.57735026918962573;
  float y = 0.57735026918962573;
  float z = 0.57735026918962573;

  float s = sin(phi);
  float c = cos(phi);

  mat[0] = x*x*(1-c)+c;
  mat[1] = x*y*(1-c)-z*s;
  mat[2] = x*z*(1-c)+y*s;

  mat[3] = y*x*(1-c)+z*s;
  mat[4] = y*y*(1-c)+c;
  mat[5] = y*z*(1-c)-x*s;

  mat[6] = x*z*(1-c)-y*s;
  mat[7] = y*z*(1-c)+x*s;
  mat[8] = z*z*(1-c)+c;
}

static byte projected[40 * 2];

void project(struct ship *s, float distance)
{
  byte vx;
  prog_char *pm = s->vertices; 
  prog_char *pm_e = pm + (s->nvertices * 3);
  byte *dst = projected;
  signed char x, y, z;

  while (pm < pm_e) {
    x = pgm_read_byte_near(pm++);
    y = pgm_read_byte_near(pm++);
    z = pgm_read_byte_near(pm++);
    float xx = x * mat[0] + y * mat[3] + z * mat[6];
    float yy = x * mat[1] + y * mat[4] + z * mat[7];
    float zz = x * mat[2] + y * mat[5] + z * mat[8] + distance;
    float q = 140 / (140 + zz);
    *dst++ = byte(128 + xx * q);
    *dst++ = byte(128 + yy * q);
  }
}

void draw(struct ship *s, float distance)
{
  project(s, distance);

  prog_uchar *pe = s->edges; 
  prog_uchar *pe_e = pe + (s->nedges * 2);
  while (pe < pe_e) {
    byte *v0 = &projected[pgm_read_byte_near(pe++) << 1];
    byte *v1 = &projected[pgm_read_byte_near(pe++) << 1];
    Plotter.line(v0[0], v0[1], v1[0], v1[1]);
  }
}

void setup()
{
  GD.begin();
  GD.ascii();
  GD.putstr(0, 0, "Accelerated wireframe");
  Plotter.begin();
}

static byte sn;      // Ship number, 0-NSHIPS
static float phi;    // Current rotation angle

// Draw one frame of ship
void cycle(float distance)
{
  rotation(phi);
  phi += 0.02;
  draw(&eliteships[sn], distance);

  // GD.waitvblank(); // uncomment this to sync to 72Hz frame rate
  Plotter.show();

  static byte every;
  if (++every == 4) {
    static long tprev;
    long t = micros();
    every = 0;

    char msg[30];
    int fps10 = int(4 * 10000000UL / (t - tprev));
    sprintf(msg, "%3d.%d fps  ", fps10 / 10, fps10 % 10);
    GD.putstr(41, 0, msg);
    tprev = t;
  }
}

void loop()
{
  const char *name = eliteships[sn].name;
  GD.putstr(0, 36, "                                                  ");
  GD.putstr(25 - strlen(name) / 2, 36, name);

  int d;
  for (d = 0; d < 100; d++)
    cycle(1000 - 10 * d);
  for (d = 0; d < 72*6; d++) 
    cycle(0.0);
  for (d = 0; d < 100; d++)
    cycle(10 * d);
  sn = (sn + 1) % NSHIPS;
}
