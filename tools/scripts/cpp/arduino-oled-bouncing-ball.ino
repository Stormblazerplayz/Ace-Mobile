// @title OLED Bouncing Ball
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Adafruit SSD1306" and "Adafruit GFX Library"; OLED SDA A4, SCL A5, VCC 5V, GND.
// @keywords oled bouncing ball, oled animation, ball bounce walls, simple physics oled
// @about Bounces a ball around the OLED screen with a little gravity, so it slowly settles down.

#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

Adafruit_SSD1306 display(128, 64, &Wire, -1);
const int RADIUS = 4;
float x = 20, y = 10;     // position
float vx = 2.2, vy = 0;   // speed
const float GRAVITY = 0.25;
const float BOUNCE = 0.85;  // keeps 85% of the speed on each bounce

void setup() {
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
}

void loop() {
  vy += GRAVITY;  // gravity pulls down every frame
  x += vx;
  y += vy;

  // Floor and ceiling.
  if (y > 63 - RADIUS) { y = 63 - RADIUS; vy = -vy * BOUNCE; }
  if (y < RADIUS) { y = RADIUS; vy = -vy; }
  // Walls.
  if (x > 127 - RADIUS) { x = 127 - RADIUS; vx = -vx; }
  if (x < RADIUS) { x = RADIUS; vx = -vx; }

  // When it is almost stopped, throw it up again.
  if (fabs(vy) < 0.6 && y >= 63 - RADIUS - 1) vy = -6;

  display.clearDisplay();
  display.drawRect(0, 0, 128, 64, SSD1306_WHITE);
  display.fillCircle((int)x, (int)y, RADIUS, SSD1306_WHITE);
  display.display();
  delay(16);  // about 60 frames a second (the screen may be a bit slower)
}
