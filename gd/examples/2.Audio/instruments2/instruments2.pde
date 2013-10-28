#include <SPI.h>
#include <GD.h>

#include "instruments.h"

// midi frequency table
static PROGMEM prog_uint16_t midifreq[128] = {
32,34,36,38,41,43,46,48,51,55,58,61,65,69,73,77,82,87,92,97,103,110,116,123,130,138,146,155,164,174,184,195,207,220,233,246,261,277,293,311,329,349,369,391,415,440,466,493,523,554,587,622,659,698,739,783,830,880,932,987,1046,1108,1174,1244,1318,1396,1479,1567,1661,1760,1864,1975,2093,2217,2349,2489,2637,2793,2959,3135,3322,3520,3729,3951,4186,4434,4698,4978,5274,5587,5919,6271,6644,7040,7458,7902,8372,8869,9397,9956,10548,11175,11839,12543,13289,14080,14917,15804,16744,17739,18794,19912,21096,22350,23679,25087,26579,28160,29834,31608,33488,35479,37589,39824,42192,44701,47359,50175
};

class player {
public:
  byte voices, duration;
  prog_uchar *amps;
  byte fv;
  player() {
    duration = 0;
  }
  void begin(PROGMEM prog_uchar *instr, byte note, byte firstvoice) {
    voices = pgm_read_byte(instr++);
    duration = pgm_read_byte(instr++);
    uint16_t midi = pgm_read_word(midifreq + note);
    fv = firstvoice;
    for (byte i = 0; i < voices; i++) {
      uint16_t w = pgm_read_word(instr);
      GD.voice(fv + i, 0, (long(w) * midi) >> 10, 0, 0);
      instr += 2;
    }
    amps = instr;
  }
  void update() {
    for (byte j = 0; j < voices; j++) {
      byte v = pgm_read_byte(amps++) >> 2;
      GD.wr(VOICES + 4 * (fv + j) + 2, v);
      GD.wr(VOICES + 4 * (fv + j) + 3, v);
    }
    duration--;
  }
  byte available() {
    return duration != 0;
  }
};

static struct {
  byte t, note;
} pacman[]  = {
  { 0, 71 },
  { 2, 83 },
  { 4, 78 },
  { 6, 75 },
  { 8, 83 },
  { 9, 78 },
  { 12, 75 },
  { 16, 72 },
  { 18, 84 },
  { 20, 79 },
  { 22, 76 },
  { 24, 84 },
  { 25, 79 },
  { 28, 76 },
  { 32, 71 },
  { 34, 83 },
  { 36, 78 },
  { 38, 75 },
  { 40, 83 },
  { 41, 78 },
  { 44, 75 },
  { 48, 75 },
  { 49, 76 },
  { 50, 77 },
  { 52, 77 },
  { 53, 78 },
  { 54, 79 },
  { 56, 79 },
  { 57, 80 },
  { 58, 81 },
  { 60, 83 }
};

static void pickinstrument(prog_uchar* &instdata, byte &pitchdrop, byte n)
{
  char* name = "";
  switch (n) {
  case 0:  name = "chimebar";  instdata = chimebar; pitchdrop = 0; break;
  case 1:  name = "piano";     instdata = piano;    pitchdrop = 4; break;
  case 2:  name = "flute";     instdata = flute;    pitchdrop = 0; break;
  case 3:  name = "harp";      instdata = harp;     pitchdrop = 1; break;
  case 4:  name = "glock";     instdata = glock;    pitchdrop = 5; break;
  case 5:  name = "nylon";     instdata = nylon;    pitchdrop = 2; break;
  case 6:  name = "bass";      instdata = bass;     pitchdrop = 4; break;
  case 7:  name = "clarinet";  instdata = clarinet; pitchdrop = 1; break;
  case 8:  name = "recorder";  instdata = recorder; pitchdrop = 1; break;
  case 9:  name = "musicbox";  instdata = musicbox; pitchdrop = 0; break;
  case 10: name = "guitar";    instdata = guitar;   pitchdrop = 3; break;
  case 11: name = "oboe";      instdata = oboe;     pitchdrop = 2; break;
  case 12: name = "organ";     instdata = organ;    pitchdrop = 2; break;
  }
  GD.fill(64, ' ', 128);
  GD.putstr(0, 2, name);
}

#include "showvoices.h"
#include "sphere.h"

void setup()
{
  GD.begin();
  GD.ascii();

  GD.copy(RAM_SPRIMG, sphere_img, sizeof(sphere_img));
  GD.copy(RAM_SPRPAL, sphere_pal, sizeof(sphere_pal));
  for (byte i = 0; i < 64; i++)
    GD.sprite(i, 100, 284 * i / 64, 0, 0);
  GD.microcode(showvoices_code, sizeof(showvoices_code));

  GD.putstr(0, 0, "Synthesized instruments");
}

void loop()
{
  player p[4];
  byte nextv = 0;
  byte v;
  for (byte inst = 0; inst < 13; inst++) {
    prog_uchar* instdata;
    byte pitchdrop;
    pickinstrument(instdata, pitchdrop, inst);
    byte t = 0;
    byte i = 0;
    while (i < sizeof(pacman) / sizeof(pacman[0])) {
      if (t == pacman[i].t) {
        p[nextv].begin(instdata, pacman[i].note - 12 * pitchdrop, 16 * nextv);
        nextv = (nextv + 1) & 3;
        i++;
      }
      for (int d = 4; d; d--) {
        for (v = 0; v < 4; v++)
          if (p[v].available())
            p[v].update();
        GD.waitvblank();
      }
      t++;
    }
    byte anyplaying;
    do {
      anyplaying = 0;
      for (v = 0; v < 4; v++) {
        byte playing = p[v].available();
        anyplaying |= playing;
        if (playing)
            p[v].update();
      }
      GD.waitvblank();
    } while (anyplaying);
  }
}
