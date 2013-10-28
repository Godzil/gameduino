#include <SPI.h>
#include <GD.h>

static void playsample(Asset &a)
{
  while (a.available()) {
    byte b;
    a.read(&b, 1);
    GD.wr(SAMPLE_L + 1, b);
    GD.wr(SAMPLE_R + 1, b);
    delayMicroseconds(80);
  }
}

static void say(const char *word)
{
  Asset a;
  a.open("voice", word, NULL);
  playsample(a);
}

void setup()
{
  GD.begin();

  // Say "Gameduino ready"
  say("game");
  say("duino");
  delay(100);
  say("ready");

  // Load the pickups starting at sprite 0.
  // First copy pickups/pal into RAM_SPRPAL, then
  // pickups/img into RAM_SPRIMG.
  Asset a;
  a.open("pickups", "pal", NULL);
  a.load(RAM_SPRPAL);
  a.open("pickups", "img", NULL);
  a.load(RAM_SPRIMG);
}

void loop()
{
  // Scatter sprites across the screen
  for (int i = 0; i < 256; i++)
    GD.sprite(i, random(400), random(300), random(47), 0, 0);

  // Play a random instrument from the 12 in the drumkit
  static const char *drums[12] = {
    "bassdrum2",
    "bassdrum4",
    "clap",
    "conga2",
    "conga3",
    "cowbell1",
    "cymbal1",
    "cymbal3",
    "hihat1",
    "hihat2",
    "snaredrum2",
    "snaredrum3"
  };
  Asset drum;
  drum.open("drumkit", drums[random(12)], NULL);
  playsample(drum);

  // Say "game over"
  say("game");
  say("over");
}
