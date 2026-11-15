// @title Bluetooth Phone Controlled Car
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; HC-05 or HC-06 TXD to pin 2, RXD to pin 3 through a voltage divider (1k and 2k), VCC 5V, GND; L298N ENA 5, IN1 7, IN2 8, IN3 9, IN4 10, ENB 6. Use a phone app like "Arduino Bluetooth RC Car" that sends F, B, L, R, S.
// @keywords bluetooth car, hc-05 robot car, phone controlled robot, softwareserial bluetooth, rc car arduino
// @about Drives a robot car from a phone app that sends letters like F for forward and S for stop over Bluetooth.

#include <SoftwareSerial.h>

SoftwareSerial bluetooth(2, 3);  // RX, TX (the Arduino's side)
const int ENA = 5, IN1 = 7, IN2 = 8, ENB = 6, IN3 = 9, IN4 = 10;
int speed = 200;
unsigned long lastCommand = 0;

void motors(int left, int right) {
  digitalWrite(IN1, left > 0);
  digitalWrite(IN2, left < 0);
  analogWrite(ENA, abs(left));
  digitalWrite(IN3, right > 0);
  digitalWrite(IN4, right < 0);
  analogWrite(ENB, abs(right));
}

void setup() {
  int pins[] = {ENA, IN1, IN2, ENB, IN3, IN4};
  for (int i = 0; i < 6; i++) pinMode(pins[i], OUTPUT);
  bluetooth.begin(9600);  // HC-05 and HC-06 usually talk at 9600
  Serial.begin(9600);
}

void loop() {
  if (bluetooth.available()) {
    char c = bluetooth.read();
    lastCommand = millis();
    Serial.println(c);
    switch (c) {
      case 'F': motors(speed, speed); break;
      case 'B': motors(-speed, -speed); break;
      case 'L': motors(-speed, speed); break;
      case 'R': motors(speed, -speed); break;
      case 'G': motors(speed / 3, speed); break;   // forward left
      case 'I': motors(speed, speed / 3); break;   // forward right
      case 'S': motors(0, 0); break;
      default:
        // Many apps send '0' to '9' for the speed slider ('q' means full).
        if (c >= '0' && c <= '9') speed = map(c - '0', 0, 9, 100, 255);
        if (c == 'q') speed = 255;
    }
  }

  // Safety: if the phone goes quiet for 1 second (out of range), stop.
  if (millis() - lastCommand > 1000) motors(0, 0);
}
