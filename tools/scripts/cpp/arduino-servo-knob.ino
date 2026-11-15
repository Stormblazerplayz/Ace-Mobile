// @title Servo Follows a Knob
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; potentiometer middle leg to A0; servo signal (orange) to pin 9, red 5V, brown GND.
// @keywords servo potentiometer, servo knob control, turn knob move servo, arduino servo pot
// @about Makes a servo point wherever you turn the knob.

#include <Servo.h>

Servo servo;
const int POT_PIN = A0;

void setup() {
  servo.attach(9);
}

void loop() {
  int knob = analogRead(POT_PIN);
  int angle = map(knob, 0, 1023, 0, 180);  // knob range -> servo range
  servo.write(angle);
  delay(15);  // give the servo time to move
}
