// @title I2C Address Scanner
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; connect your I2C device SDA to A4, SCL to A5, VCC and GND; open Serial Monitor at 9600.
// @keywords i2c scanner, find i2c address, lcd address 0x27 or 0x3f, wire scanner
// @about Searches every I2C address and prints which ones have a device, so you know your LCD or sensor address.

#include <Wire.h>

void setup() {
  Wire.begin();
  Serial.begin(9600);
}

void loop() {
  Serial.println("Scanning...");
  int found = 0;

  for (int address = 1; address < 127; address++) {
    // Knock on each address. 0 means somebody answered.
    Wire.beginTransmission(address);
    byte result = Wire.endTransmission();
    if (result == 0) {
      Serial.print("Found a device at 0x");
      if (address < 16) Serial.print("0");
      Serial.println(address, HEX);
      found++;
    }
  }

  if (found == 0) Serial.println("Nothing found. Check the SDA and SCL wires.");
  else Serial.println("Done.");
  delay(5000);
}
