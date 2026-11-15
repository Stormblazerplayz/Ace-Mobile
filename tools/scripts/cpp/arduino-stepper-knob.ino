// @title Stepper Follows a Knob
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; 28BYJ-48 with ULN2003: IN1 8, IN2 9, IN3 10, IN4 11; potentiometer middle leg on A0.
// @keywords stepper potentiometer, stepper knob position, stepper follow pot, dial pointer stepper
// @about Makes a stepper motor's pointer copy the position of a knob, like a remote dial.

#include <Stepper.h>

const int STEPS_PER_TURN = 2048;
Stepper stepper(STEPS_PER_TURN, 8, 10, 9, 11);
int position = 0;  // where the motor is now, in steps

void setup() {
  stepper.setSpeed(12);
}

void loop() {
  // The knob picks a target anywhere in one full turn.
  int target = map(analogRead(A0), 0, 1023, 0, STEPS_PER_TURN);
  int difference = target - position;

  // Ignore tiny wiggles from the knob.
  if (abs(difference) > 8) {
    // Move only a few steps at a time so we can keep checking the knob.
    int move = constrain(difference, -32, 32);
    stepper.step(move);
    position += move;
  }
}
