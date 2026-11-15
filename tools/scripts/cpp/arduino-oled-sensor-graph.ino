// @title OLED Live Sensor Graph
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Adafruit SSD1306" and "Adafruit GFX Library"; OLED SDA A4, SCL A5; any analog sensor or knob on A0.
// @keywords oled graph, live sensor chart, scrolling graph oled, plot sensor oled
// @about Draws a scrolling line graph of a sensor on the OLED, with the current number at the top.

#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

Adafruit_SSD1306 display(128, 64, &Wire, -1);
const int GRAPH_TOP = 12;
const int GRAPH_HEIGHT = 52;
byte history[128];  // one height for each column of the screen

void setup() {
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  for (int i = 0; i < 128; i++) history[i] = 0;
}

void loop() {
  int value = analogRead(A0);

  // Slide everything one step left and add the new point on the right.
  for (int i = 0; i < 127; i++) history[i] = history[i + 1];
  history[127] = map(value, 0, 1023, 0, GRAPH_HEIGHT - 1);

  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.print("A0: ");
  display.print(value);

  for (int i = 1; i < 128; i++) {
    int y1 = 63 - history[i - 1];
    int y2 = 63 - history[i];
    display.drawLine(i - 1, y1, i, y2, SSD1306_WHITE);
  }
  display.drawFastHLine(0, GRAPH_TOP - 1, 128, SSD1306_WHITE);
  display.display();
  delay(50);
}
