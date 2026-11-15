// @title Type an Angle to Move a Servo
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; servo signal on pin 9; open Serial Monitor at 9600, set line ending to Newline, type a number 0 to 180 and press Enter.
// @keywords serial servo control, type angle servo, serial parseint, control servo from computer
// @about Moves a servo to whatever angle you type into the Serial Monitor.

#include <Servo.h>

Servo servo;

void setup() {
  servo.attach(9);
  servo.write(90);
  Serial.begin(9600);
  Serial.println("Type an angle from 0 to 180:");
}

void loop() {
  if (Serial.available() > 0) {
    int angle = Serial.parseInt();  // reads the number you typed
    // Throw away the rest of the line (the Enter key).
    while (Serial.available() > 0) Serial.read();

    if (angle < 0 || angle > 180) {
      Serial.println("Please use 0 to 180.");
      return;
    }
    servo.write(angle);
    Serial.print("Moved to ");
    Serial.print(angle);
    Serial.println(" degrees");
  }
}
