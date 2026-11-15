// @title Stepper Left and Right Buttons
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; 28BYJ-48 with ULN2003 IN1 8, IN2 9, IN3 10, IN4 11; left button pin 2 to GND, right button pin 3 to GND.
// @keywords stepper buttons, stepper direction control, hold button turn motor, turntable stepper
// @about Turns the stepper one way while you hold the left button and the other way with the right button.

#include <Stepper.h>

Stepper stepper(2048, 8, 10, 9, 11);
const int LEFT_BUTTON = 2;
const int RIGHT_BUTTON = 3;

void setup() {
  pinMode(LEFT_BUTTON, INPUT_PULLUP);
  pinMode(RIGHT_BUTTON, INPUT_PULLUP);
  stepper.setSpeed(12);
}

void releaseCoils() {
  // Turning the coils off stops the motor getting warm while it waits.
  for (int pin = 8; pin <= 11; pin++) digitalWrite(pin, LOW);
}

void loop() {
  bool left = digitalRead(LEFT_BUTTON) == LOW;
  bool right = digitalRead(RIGHT_BUTTON) == LOW;

  if (left && !right) {
    stepper.step(-16);  // small moves keep it responsive
  } else if (right && !left) {
    stepper.step(16);
  } else {
    releaseCoils();
    delay(10);
  }
}
