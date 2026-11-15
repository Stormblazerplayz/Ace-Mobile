// @title Robot Arm with Four Knobs
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; 4 servos (base pin 3, shoulder 5, elbow 6, claw 9) powered by a separate 5V 2A supply with GND joined; 4 potentiometers on A0 to A3.
// @keywords robot arm, 4 servo arm, mearm arduino, control robot arm with potentiometers
// @about Controls a 4-servo robot arm (base, shoulder, elbow and claw) with four knobs, moving smoothly.

#include <Servo.h>

Servo joints[4];
const int SERVO_PINS[4] = {3, 5, 6, 9};
const int KNOB_PINS[4] = {A0, A1, A2, A3};
// Safe limits for each joint so the arm can't crash into itself.
const int MIN_ANGLE[4] = {0, 30, 20, 60};
const int MAX_ANGLE[4] = {180, 150, 160, 120};
float current[4] = {90, 90, 90, 90};

void setup() {
  for (int i = 0; i < 4; i++) {
    joints[i].attach(SERVO_PINS[i]);
    joints[i].write(90);
  }
}

void loop() {
  for (int i = 0; i < 4; i++) {
    int target = map(analogRead(KNOB_PINS[i]), 0, 1023, MIN_ANGLE[i], MAX_ANGLE[i]);
    // Move 20% of the way there each time: smooth, no sudden jerks.
    current[i] += (target - current[i]) * 0.2;
    joints[i].write((int)current[i]);
  }
  delay(20);
}
