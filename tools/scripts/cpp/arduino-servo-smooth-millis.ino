// @title Smooth Servo Without delay()
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; servo signal on pin 9; LED with 220 ohm resistor on pin 13 (or just the built-in LED).
// @keywords servo without delay, servo millis, smooth servo sweep, servo and blink at the same time
// @about Sweeps a servo smoothly using millis() so an LED can blink at its own speed at the same time.

#include <Servo.h>

Servo servo;
int angle = 0;
int direction = 1;
unsigned long lastServoMove = 0;
unsigned long lastBlink = 0;
bool ledOn = false;

void setup() {
  servo.attach(9);
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  unsigned long now = millis();

  // Job 1: move the servo one degree every 15 ms.
  if (now - lastServoMove >= 15) {
    lastServoMove = now;
    angle += direction;
    if (angle >= 180 || angle <= 0) direction = -direction;
    servo.write(angle);
  }

  // Job 2: blink the LED every 300 ms. It never waits for the servo!
  if (now - lastBlink >= 300) {
    lastBlink = now;
    ledOn = !ledOn;
    digitalWrite(LED_BUILTIN, ledOn ? HIGH : LOW);
  }
}
