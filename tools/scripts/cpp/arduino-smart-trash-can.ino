// @title Touchless Smart Trash Can
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; HC-SR04 on the front of the can, Trig 9, Echo 10; servo on pin 6 tied to the lid with string or a stick; power the servo from 5V.
// @keywords smart trash can, automatic lid opener, touchless bin, ultrasonic servo lid
// @about Opens the trash can lid with a servo when your hand comes close and closes it a few seconds later.

#include <Servo.h>

Servo lid;
const int TRIG = 9, ECHO = 10;
const int CLOSED = 0, OPEN = 100;
const int HAND_CM = 20;
const unsigned long STAY_OPEN_MS = 4000;

long distanceCm() {
  digitalWrite(TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG, LOW);
  unsigned long d = pulseIn(ECHO, HIGH, 30000UL);
  return d == 0 ? 400 : d / 58;
}

void setup() {
  pinMode(TRIG, OUTPUT);
  pinMode(ECHO, INPUT);
  lid.attach(6);
  lid.write(CLOSED);
}

void loop() {
  if (distanceCm() < HAND_CM) {
    lid.write(OPEN);
    // Keep it open while the hand is still there, then wait a bit more.
    unsigned long lastSeen = millis();
    while (millis() - lastSeen < STAY_OPEN_MS) {
      if (distanceCm() < HAND_CM) lastSeen = millis();
      delay(100);
    }
    for (int a = OPEN; a >= CLOSED; a--) {  // close gently so it doesn't slam
      lid.write(a);
      delay(10);
    }
  }
  delay(100);
}
