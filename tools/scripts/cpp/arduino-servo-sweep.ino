// @title Servo Sweep
// @category Arduino
// @kind Arduino sketch
// @where Paste this into a new Arduino IDE sketch and upload it; wire the servo's signal (orange or yellow) to pin 9, red to 5V, and brown or black to GND.
// @keywords arduino servo, arduino servo sweep, move a servo with arduino, servo motor arduino code
// @about Swings a servo motor slowly from 0 to 180 degrees and back, over and over.

#include <Servo.h>

const int SERVO_PIN = 9;
const int STEP_DELAY = 15;  // smaller = faster sweep

Servo myServo;

void setup() {
  myServo.attach(SERVO_PIN);
}

void loop() {
  // Go from 0 up to 180 degrees.
  for (int angle = 0; angle <= 180; angle++) {
    myServo.write(angle);
    delay(STEP_DELAY);
  }
  // Come back down from 180 to 0.
  for (int angle = 180; angle >= 0; angle--) {
    myServo.write(angle);
    delay(STEP_DELAY);
  }
}
