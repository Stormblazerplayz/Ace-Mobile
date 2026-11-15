// @title Two Arduinos Talking: Receiver (I2C Slave)
// @category Arduino
// @kind Arduino sketch
// @where Upload to Arduino #2; join A4 to A4, A5 to A5 and GND to GND with Arduino #1 (running the Sender sketch); LED with 220 ohm resistor on pin 9.
// @keywords i2c slave, wire onreceive, receive data from another arduino, i2c receiver led
// @about Listens on I2C address 8 and sets an LED's brightness to whatever number the sender Arduino sends.

#include <Wire.h>

const int MY_ADDRESS = 8;
const int LED = 9;
volatile byte brightness = 0;
volatile bool gotNew = false;

// Runs by itself whenever the sender sends bytes. Keep it short!
void onData(int howMany) {
  while (howMany-- > 0 && Wire.available()) {
    brightness = Wire.read();
  }
  gotNew = true;
}

void setup() {
  pinMode(LED, OUTPUT);
  Wire.begin(MY_ADDRESS);  // giving an address makes this board a helper (slave)
  Wire.onReceive(onData);
  Serial.begin(9600);
}

void loop() {
  if (gotNew) {
    gotNew = false;
    byte level = brightness;
    analogWrite(LED, level);
    Serial.print("Got ");
    Serial.println(level);
  }
}
