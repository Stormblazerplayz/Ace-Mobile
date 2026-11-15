// @title TV Remote Controlled Robot Car
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "IRremote" (version 4+); IR receiver OUT to pin 12; L298N ENA 5, IN1 7, IN2 8, IN3 9, IN4 10, ENB 6. Codes are for the Car MP3 remote; use the code finder sketch for yours.
// @keywords ir remote car, remote control robot, tv remote robot car, infrared robot
// @about Drives a robot car with an infrared remote: 2 forward, 8 back, 4 left, 6 right, 5 stop.

#include <IRremote.hpp>

const int ENA = 5, IN1 = 7, IN2 = 8, ENB = 6, IN3 = 9, IN4 = 10;
const uint16_t KEY_2 = 0x18, KEY_4 = 0x08, KEY_5 = 0x1C, KEY_6 = 0x5A, KEY_8 = 0x52;
unsigned long lastSignal = 0;

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
  IrReceiver.begin(12);
}

void loop() {
  if (IrReceiver.decode()) {
    uint16_t key = IrReceiver.decodedIRData.command;
    IrReceiver.resume();
    lastSignal = millis();  // holding a key keeps sending repeats, which keeps us moving

    if (key == KEY_2) motors(200, 200);
    else if (key == KEY_8) motors(-200, -200);
    else if (key == KEY_4) motors(-170, 170);
    else if (key == KEY_6) motors(170, -170);
    else if (key == KEY_5) motors(0, 0);
  }

  // Let go of the button for 250 ms and the car stops by itself.
  if (millis() - lastSignal > 250) motors(0, 0);
}
