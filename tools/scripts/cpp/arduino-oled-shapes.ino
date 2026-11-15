// @title OLED Shapes Drawing
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Adafruit SSD1306" and "Adafruit GFX Library"; OLED SDA to A4, SCL to A5, VCC 5V, GND.
// @keywords oled shapes, draw circle rectangle oled, adafruit gfx drawing, oled lines
// @about Draws lines, rectangles, circles and triangles on an OLED, one shape show after another.

#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

Adafruit_SSD1306 display(128, 64, &Wire, -1);

void title(const char *text) {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.print(text);
}

void setup() {
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
}

void loop() {
  title("Lines");
  for (int x = 0; x < 128; x += 8) display.drawLine(0, 63, x, 10, SSD1306_WHITE);
  display.display();
  delay(1500);

  title("Rectangles");
  for (int i = 0; i < 25; i += 4) display.drawRect(i * 2, 10 + i, 128 - i * 4, 54 - i * 2, SSD1306_WHITE);
  display.display();
  delay(1500);

  title("Circles");
  display.drawCircle(32, 38, 22, SSD1306_WHITE);
  display.fillCircle(96, 38, 22, SSD1306_WHITE);
  display.display();
  delay(1500);

  title("Triangles");
  display.drawTriangle(10, 60, 40, 12, 70, 60, SSD1306_WHITE);
  display.fillTriangle(70, 60, 98, 12, 126, 60, SSD1306_WHITE);
  display.display();
  delay(1500);

  title("Rounded box");
  display.fillRoundRect(14, 16, 100, 44, 10, SSD1306_WHITE);
  display.setTextColor(SSD1306_BLACK);  // black text on the white box
  display.setCursor(38, 34);
  display.print("Button!");
  display.display();
  delay(1500);
}
