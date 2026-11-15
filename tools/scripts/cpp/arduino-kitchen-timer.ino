// @title Kitchen Countdown Timer
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "TM1637" by Avishay Orpaz; display CLK 2, DIO 3, VCC 5V, GND; potentiometer middle leg on A0 sets minutes; start button pin 4 to GND; buzzer pin 8.
// @keywords kitchen timer, countdown timer arduino, minutes and seconds display, egg timer tm1637
// @about Turn the knob to pick 1 to 60 minutes, press start, and it counts down in mm:ss and beeps at zero.

#include <TM1637Display.h>

TM1637Display display(2, 3);
const int KNOB = A0, START_BUTTON = 4, BUZZER = 8;

void showTime(long totalSeconds, bool colon) {
  int minutes = totalSeconds / 60;
  int seconds = totalSeconds % 60;
  display.showNumberDecEx(minutes * 100 + seconds, colon ? 0b01000000 : 0, true);
}

void setup() {
  pinMode(START_BUTTON, INPUT_PULLUP);
  pinMode(BUZZER, OUTPUT);
  display.setBrightness(5);
}

void loop() {
  // Setting mode: the knob picks the minutes.
  int minutes = map(analogRead(KNOB), 0, 1023, 1, 60);
  showTime(minutes * 60L, true);

  if (digitalRead(START_BUTTON) == LOW) {
    while (digitalRead(START_BUTTON) == LOW) delay(10);
    long remaining = minutes * 60L;
    unsigned long lastTick = millis();

    while (remaining > 0) {
      if (millis() - lastTick >= 1000) {
        lastTick += 1000;
        remaining--;
      }
      showTime(remaining, (millis() / 500) % 2 == 0);  // blinking colon while running
      if (digitalRead(START_BUTTON) == LOW) {          // press again to cancel
        while (digitalRead(START_BUTTON) == LOW) delay(10);
        return;
      }
    }

    // Time's up: beep until the button is pressed.
    while (digitalRead(START_BUTTON) == HIGH) {
      tone(BUZZER, 2000, 150);
      showTime(0, true);
      delay(300);
      display.clear();
      delay(300);
    }
    while (digitalRead(START_BUTTON) == LOW) delay(10);
  }
}
