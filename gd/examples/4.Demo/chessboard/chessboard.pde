#include <SPI.h>
#include <GD.h>

#include "Wood32.h"
#include "staunton.h" // Chess pieces from eboard's Staunton set: http://www.bergo.eng.br

#define digits (sizeof(staunton_img) / 256)
#include "digits.h"

int atxy(int x, int y)
{
  return (y << 6) + x;
}

static void square(byte x, byte y, byte light)
{
  prog_uchar *src = Wood32_pic + (16 * light);
  int addr = atxy(x, y);
  GD.copy(addr + 0 * 64, src, 4);
  GD.copy(addr + 1 * 64, src + 4, 4);
  GD.copy(addr + 2 * 64, src + 8, 4);
  GD.copy(addr + 3 * 64, src + 12, 4);
}

#define QROOK    0
#define QKNIGHT  1
#define QBISHOP  2
#define QUEEN   3
#define KING    4
#define KBISHOP 5
#define KKNIGHT 6
#define KROOK   7
#define PAWN    8
#define WHITE   0x00
#define BLACK   0x10

static char board[32];

static void startboard()
{
  byte i;

  for (i = 0; i < 8; i++) {
    board[i] =    56 + i;
    board[8+i] =  48 + i;
    board[16+i] = i;
    board[24+i] = 8 + i;
  }
}

// Return the piece at pos, or -1 if pos is empty
static char find(byte pos)
{
  byte slot;
  for (slot = 0; slot < 32; slot++)
    if (board[slot] == pos)
      return slot;
  return -1;
}

byte images[16] = { 0, 1, 2, 3, 4, 2, 1, 0, 5, 5, 5, 5, 5, 5, 5, 5 };

static void piece(byte slot, int x, int y)
{
  byte i = (4 * slot);
  byte j = images[slot & 0xf] * 2;
  byte bw = (slot >> 4) & 1;
  GD.sprite(i, x, y, j, bw, 0);
  GD.sprite(i + 1, x + 16, y, j + 1, bw, 0);
  GD.sprite(i + 2, x, y + 16, j + 12, bw, 0);
  GD.sprite(i + 3, x + 16, y + 16, j + 13, bw, 0);
}

#define BOARDX(pos) (8 + (((pos) & 7) << 5))
#define BOARDY(pos) (24 + ((((pos) >> 3) & 7) << 5))

static void drawboard()
{
  byte slot;

  for (slot = 0; slot < 32; slot++) {
    char pos = board[slot];
    if (pos < 0)
      piece(slot, 400, 400);
    else {
      piece(slot, BOARDX(pos), BOARDY(pos));
    }
  }
}

static float smoothstep(float x)
{
  return x*x*(3-2*x);
}


// move piece 'slot' to position 'pos'.
// return true if a piece was taken.
static byte movepiece(byte slot, byte pos)
{
  int x0 = BOARDX(board[slot]);
  int y0 = BOARDY(board[slot]);
  int x1 = BOARDX(pos);
  int y1 = BOARDY(pos);
  // move at 1.5 pix/frame
  int d = int(sqrt(pow(x0 - x1, 2) + pow(y0 - y1, 2)) / 2);
  int it;
  for (it = 0; it < d; it++) {
    float t = smoothstep(float(it) / d);
    GD.waitvblank();
    GD.waitvblank();
    piece(slot, int(x0 + t * (x1 - x0)), int(y0 + t * (y1 - y0)));
  }
  byte taken = find(pos) != -1;
  if (taken)
    board[find(pos)] = -1;
  board[slot] = pos;
  drawboard();
  return taken;
}

void setup()
{
  int i, j;

  GD.begin();
  GD.ascii();
  GD.putstr(0, 0, "Chess board");

  GD.copy(RAM_CHR, Wood32_chr, sizeof(Wood32_chr));
  GD.copy(RAM_PAL, Wood32_pal, sizeof(Wood32_pal));
  GD.copy(RAM_SPRIMG, staunton_img, sizeof(staunton_img));
  GD.copy(RAM_SPRPAL, staunton_white, sizeof(staunton_white));
  GD.copy(RAM_SPRPAL + 512, staunton_black, sizeof(staunton_black));

  GD.copy(RAM_SPRIMG + (digits << 8), digits_img, sizeof(digits_img));
  GD.copy(RAM_SPRPAL + 2 * 512, digits_pal, sizeof(digits_pal));
  for (i = 0; i < 256; i++) {
    unsigned int b = GD.rd16(RAM_SPRPAL + 2 * 512 + 2 * i);
    GD.wr16(RAM_SPRPAL + 3 * 512 + 2 * i, b ^ 0x7fff);
  }

  // Draw the 64 squares of the board
  for (i = 0; i < 8; i++)
    for (j = 0; j < 8; j++)
      square(1 + (i << 2), 3 + (j << 2), (i ^ j) & 1);

  // Draw the rank and file markers 1-8 a-h
  for (i = 0; i < 8; i++) {
    GD.wr(atxy(3 + (i << 2), 2), 'a' + i);
    GD.wr(atxy(3 + (i << 2), 35), 'a' + i);
    GD.wr(atxy(0, 5 + (i << 2)), '8' - i);
    GD.wr(atxy(33, 5 + (i << 2)), '8' - i);
  }

  startboard();
  drawboard();
}

static int clock[2];

// draw digit d in sprite slots spr,spr+1 at (x,y)
static void digit(byte spr, byte d, byte bw, int x, int y)
{
  GD.sprite(spr, x, y, digits + d, 2 + bw, 0);
  GD.sprite(spr + 1, x, y + 16, digits + d + 11, 2 + bw, 0);
}

static void showclock(byte bw)
{
  int t = clock[bw];
  byte spr = 128 + (bw * 16);
  byte s = t % 60;
  int y = (bw ? 31 : 3) * 8;
  byte d0 = s % 10; s /= 10;
  digit(spr,      d0, bw, 400 - 1 * 16, y);
  digit(spr + 2,   s, bw, 400 - 2 * 16, y);

  digit(spr + 4,  10, bw, 400 - 3 * 16, y);    // colon
  spr += 6;
  int x = 400 - 4 * 16;

  byte m = t / 60;
  do {
    d0 = m % 10; m /= 10;
    digit(spr,  d0, bw, x, y);
    spr += 2;
    x -= 16;
  } while (m);
}

static int turn;

#define ALG(r,f) ((r - 'a') + ((8 - f) * 8))
#define CASTLE 255,255

static byte game[] = {
  ALG('e', 2),ALG('e', 4), ALG('e', 7),ALG('e', 5),
  ALG('g', 1),ALG('f', 3), ALG('b', 8),ALG('c', 6),
  ALG('f', 1),ALG('b', 5), ALG('a', 7),ALG('a', 6),
  ALG('b', 5),ALG('a', 4), ALG('g', 8),ALG('f', 6),
  ALG('d', 1),ALG('e', 2), ALG('b', 7),ALG('b', 5),
  ALG('a', 4),ALG('b', 3), ALG('f', 8),ALG('e', 7),
  ALG('c', 2),ALG('c', 3), CASTLE,
  CASTLE,                  ALG('d', 7),ALG('d', 5),
  ALG('e', 4),ALG('d', 5), ALG('f', 6),ALG('d', 5),
  ALG('f', 3),ALG('e', 5), ALG('d', 5),ALG('f', 4),
  ALG('e', 2),ALG('e', 4), ALG('c', 6),ALG('e', 5),
  ALG('e', 4),ALG('a', 8), ALG('d', 8),ALG('d', 3),
  ALG('b', 3),ALG('d', 1), ALG('c', 8),ALG('h', 3),
  ALG('a', 8),ALG('a', 6), ALG('h', 3),ALG('g', 2),
  ALG('f', 1),ALG('e', 1), ALG('d', 3),ALG('f', 3),
};

static void putalg(byte x, byte y, byte a)
{
  GD.wr(atxy(x, y), 'a' + (a & 7));
  GD.wr(atxy(x+1, y), '8' - ((a >> 3) & 7));
}

void loop()
{
  byte i;
  for (i = random(25); i; i--) {
    clock[(1 & turn) ^ 1]++;
    GD.waitvblank();
    showclock(0);
    showclock(1);
    delay(20);
  }
  if (turn < (sizeof(game) / 2)) {
    byte yy = 8 + (turn >> 1);
    byte xx = (turn & 1) ? 44 : 38;
    byte i = 1 + (turn >> 1);
    if (i >= 10)
      GD.wr(atxy(35, yy), '0' + i / 10);
    GD.wr(atxy(36, yy), '0' + i % 10);
    GD.wr(atxy(37, yy), '.');

    byte from = game[2 * turn];
    byte to = game[2 * turn + 1];
    if (from != 255) {
      putalg(xx, yy, from);
      GD.wr(atxy(xx + 2, yy), movepiece(find(from), to) ? 'x' : '-');
      putalg(xx + 3, yy, to);
    } else {
      byte rank = (turn & 1) ? 8 : 1;
      movepiece(find(ALG('e', rank)), ALG('g', rank));
      movepiece(find(ALG('h', rank)), ALG('f', rank));
      GD.putstr(xx, yy, "O-O");
    }
    turn++;
  } else {
    delay(4000);
    setup();
    turn = 0;
    clock[0] = 0;
    clock[1] = 0;
  }
}

