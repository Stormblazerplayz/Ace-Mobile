// @title Two Arduinos Talking: Sender (I2C Master)
// @category Arduino
// @kind Arduino sketch
// @where Upload to Arduino #1; join A4 to A4, A5 to A5 and GND to GND between two Unos; potentiometer middle leg on A0. Load the Receiver sketch on Arduino #2.
// @keywords two arduinos talk, i2c master, wire begintransmission, arduino to arduino communication
// @about Reads a knob and sends its value to a second Arduino over I2C ten times a second.

#include <Wire.h>

const int RECEIVER_ADDRESS = 8;  // the receiver answers to this number

void setup() {
  Wire.begin();  // no address = this board is the boss (master)
  Serial.begin(9600);
}

void loop() {
  int value = analogRead(A0);
  byte level = value / 4;  // squeeze 0..1023 into one byte 0..255

  Wire.beginTransmission(RECEIVER_ADDRESS);
  Wire.write(level);
  byte result = Wire.endTransmission();  // 0 means it was received

  Serial.print("Sent ");
  Serial.print(level);
  Serial.println(result == 0 ? " (ok)" : " (no answer, check wires)");
  delay(100);
}
