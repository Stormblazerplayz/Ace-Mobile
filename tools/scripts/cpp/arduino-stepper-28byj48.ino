// @title Stepper Motor 28BYJ-48
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; 28BYJ-48 stepper on a ULN2003 board: IN1 to 8, IN2 to 9, IN3 to 10, IN4 to 11, + to 5V, - to GND.
// @keywords stepper motor, 28byj-48, uln2003, arduino stepper library, turn exact steps
// @about Turns a small stepper motor exactly one full turn one way, then one full turn back.

#include <Stepper.h>

const int STEPS_PER_TURN = 2048;  // the 28BYJ-48 has 2048 steps in one turn
// The pin order 8, 10, 9, 11 is on purpose: it matches how this motor is wired inside.
Stepper stepper(STEPS_PER_TURN, 8, 10, 9, 11);

void setup() {
  stepper.setSpeed(10);  // turns per minute (this motor tops out around 15)
  Serial.begin(9600);
}

void loop() {
  Serial.println("One turn clockwise");
  stepper.step(STEPS_PER_TURN);
  delay(500);

  Serial.println("One turn back");
  stepper.step(-STEPS_PER_TURN);
  delay(500);

  Serial.println("Quarter turn ticks like a clock");
  for (int i = 0; i < 4; i++) {
    stepper.step(STEPS_PER_TURN / 4);
    delay(300);
  }
  delay(1000);
}
