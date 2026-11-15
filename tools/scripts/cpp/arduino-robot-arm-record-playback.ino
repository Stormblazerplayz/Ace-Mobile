// @title Robot Arm Record and Play Back
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; servos base 3, shoulder 5, elbow 6, claw 9 (own 5V supply, GND joined); potentiometers A0 to A3; record button pin 2 to GND; play button pin 4 to GND.
// @keywords robot arm record playback, teach robot arm moves, save servo positions, repeat arm motion
// @about Press record to save the arm's position (up to 20 poses), then press play to make it repeat them all.

#include <Servo.h>

Servo joints[4];
const int SERVO_PINS[4] = {3, 5, 6, 9};
const int KNOB_PINS[4] = {A0, A1, A2, A3};
const int RECORD_BUTTON = 2, PLAY_BUTTON = 4;
const int MAX_POSES = 20;

byte poses[MAX_POSES][4];  // byte is enough: angles are 0 to 180
int poseCount = 0;

void moveTo(const byte target[4]) {
  // Move all joints together in 30 small steps.
  int start[4];
  for (int i = 0; i < 4; i++) start[i] = joints[i].read();
  for (int step = 1; step <= 30; step++) {
    for (int i = 0; i < 4; i++) {
      joints[i].write(start[i] + (target[i] - start[i]) * step / 30);
    }
    delay(20);
  }
}

void setup() {
  for (int i = 0; i < 4; i++) joints[i].attach(SERVO_PINS[i]);
  pinMode(RECORD_BUTTON, INPUT_PULLUP);
  pinMode(PLAY_BUTTON, INPUT_PULLUP);
  Serial.begin(9600);
}

void loop() {
  // Live mode: the knobs move the arm.
  byte live[4];
  for (int i = 0; i < 4; i++) {
    live[i] = map(analogRead(KNOB_PINS[i]), 0, 1023, 0, 180);
    joints[i].write(live[i]);
  }

  if (digitalRead(RECORD_BUTTON) == LOW && poseCount < MAX_POSES) {
    for (int i = 0; i < 4; i++) poses[poseCount][i] = live[i];
    poseCount++;
    Serial.print("Saved pose ");
    Serial.println(poseCount);
    while (digitalRead(RECORD_BUTTON) == LOW) delay(10);
  }

  if (digitalRead(PLAY_BUTTON) == LOW && poseCount > 0) {
    Serial.println("Playing back...");
    for (int p = 0; p < poseCount; p++) {
      moveTo(poses[p]);
      delay(300);
    }
    Serial.println("Done! Hold play while it finishes to clear the poses.");
    if (digitalRead(PLAY_BUTTON) == LOW) poseCount = 0;
    while (digitalRead(PLAY_BUTTON) == LOW) delay(10);
  }
  delay(20);
}
