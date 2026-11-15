// @title OLED SSD1306 Hello World
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Adafruit SSD1306" and "Adafruit GFX Library"; 128x64 I2C OLED VCC to 5V, GND, SDA to A4, SCL to A5.
// @keywords oled ssd1306, oled hello world, 128x64 oled arduino, adafruit ssd1306 text
// @about Shows big and small text on a little 0.96 inch OLED screen.

#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

const int SCREEN_WIDTH = 128;
const int SCREEN_HEIGHT = 64;
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);  // -1 = no reset pin

void setup() {
  Serial.begin(9600);
  // 0x3C is the usual address. Some screens use 0x3D.
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("OLED not found!");
    while (true) {}  // stop here forever
  }
}

void loop() {
  display.clearDisplay();  // wipe the drawing area
  display.setTextColor(SSD1306_WHITE);

  display.setTextSize(2);  // twice as big
  display.setCursor(0, 0);
  display.println("Hello!");

  display.setTextSize(1);  // normal small text: 21 letters across
  display.println("I am an OLED screen.");
  display.print("Uptime: ");
  display.print(millis() / 1000);
  display.println(" s");

  display.display();  // nothing shows until you call this!
  delay(500);
}
