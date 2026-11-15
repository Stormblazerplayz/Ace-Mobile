// @title OLED Robot Eyes
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Adafruit SSD1306" and "Adafruit GFX Library"; OLED SDA A4, SCL A5, VCC 5V, GND; stick it on your robot's face.
// @keywords robot eyes oled, animated eyes, blinking eyes robot, cute robot face
// @about Draws two robot eyes that look around, blink and sometimes look happy.

#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

Adafruit_SSD1306 display(128, 64, &Wire, -1);

// Draw both eyes. lookX/lookY move the pupils, open is the eye height (0 = shut).
void drawEyes(int lookX, int lookY, int open, bool happy) {
  display.clearDisplay();
  for (int side = 0; side < 2; side++) {
    int cx = side == 0 ? 36 : 92;  // eye centers
    int top = 32 - open / 2;
    display.fillRoundRect(cx - 20, top, 40, open, 10, SSD1306_WHITE);
    if (open > 12) {
      display.fillCircle(cx + lookX, 32 + lookY, 6, SSD1306_BLACK);  // pupil
    }
    if (happy) {  // cover the bottom with a black curve for a smile shape
      display.fillCircle(cx, 32 + open / 2 + 8, 22, SSD1306_BLACK);
    }
  }
  display.display();
}

void blink(int lookX, int lookY) {
  for (int h = 36; h >= 2; h -= 8) { drawEyes(lookX, lookY, h, false); delay(15); }
  for (int h = 2; h <= 36; h += 8) { drawEyes(lookX, lookY, h, false); delay(15); }
}

void setup() {
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  randomSeed(analogRead(A0));
}

void loop() {
  int lookX = random(-8, 9);
  int lookY = random(-6, 7);
  drawEyes(lookX, lookY, 36, false);
  delay(random(800, 2500));

  if (random(4) == 0) {
    drawEyes(0, 0, 36, true);  // happy face!
    delay(1200);
  }
  blink(lookX, lookY);
}
