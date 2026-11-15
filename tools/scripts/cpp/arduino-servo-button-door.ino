// @title Servo Door with a Button
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; servo signal to pin 9, red 5V, brown GND; push button between pin 2 and GND.
// @keywords servo door, button opens servo, toggle servo position, lego door servo
// @about Opens and closes a little door with a servo each time you press the button, moving slowly so it looks smooth.

#include <Servo.h>

Servo door;
const int BUTTON_PIN = 2;
const int CLOSED = 10;
const int OPEN = 100;
int angle = CLOSED;
bool isOpen = false;

void moveSlowly(int target) {
  while (angle != target) {
    angle += (target > angle) ? 1 : -1;
    door.write(angle);
    delay(12);  // smaller = faster door
  }
}

void setup() {
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  door.attach(9);
  door.write(angle);
}

void loop() {
  if (digitalRead(BUTTON_PIN) == LOW) {
    isOpen = !isOpen;
    moveSlowly(isOpen ? OPEN : CLOSED);
    while (digitalRead(BUTTON_PIN) == LOW) delay(10);  // wait for release
    delay(50);
  }
}
