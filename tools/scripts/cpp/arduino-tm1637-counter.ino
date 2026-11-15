// @title TM1637 4-Digit Display Counter
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "TM1637" by Avishay Orpaz; display CLK to pin 2, DIO to pin 3, VCC 5V, GND; button between pin 4 and GND.
// @keywords tm1637, 4 digit display, tm1637display shownumberdec, digit display counter
// @about Shows a number on a 4-digit display that goes up each time you press the button.

#include <TM1637Display.h>

TM1637Display display(2, 3);  // CLK, DIO
const int BUTTON_PIN = 4;
int count = 0;
bool lastButton = HIGH;

// Letters for "done" made from segments.
const uint8_t DONE[] = {
  SEG_B | SEG_C | SEG_D | SEG_E | SEG_G,          // d
  SEG_C | SEG_D | SEG_E | SEG_G,                  // o
  SEG_C | SEG_E | SEG_G,                          // n
  SEG_A | SEG_D | SEG_E | SEG_F | SEG_G           // E
};

void setup() {
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  display.setBrightness(5);  // 0 (dim) to 7 (bright)
  display.showNumberDec(count);
}

void loop() {
  bool button = digitalRead(BUTTON_PIN);
  if (button == LOW && lastButton == HIGH) {
    count++;
    if (count > 9999) {
      display.setSegments(DONE);  // only 4 digits, so we are done!
      delay(2000);
      count = 0;
    }
    display.showNumberDec(count);
    delay(30);
  }
  lastButton = button;
}
