// @title Steer a Servo with a Remote
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "IRremote" (version 4+); IR receiver OUT to pin 11; servo signal to pin 9, red 5V, brown GND. Codes are for the common Car MP3 remote.
// @keywords ir remote servo, remote control servo, servo left right remote, irremote servo
// @about Moves a servo left or right a bit each time you press the arrow buttons on a remote.

#include <IRremote.hpp>
#include <Servo.h>

Servo servo;
int angle = 90;

const uint16_t LEFT_BUTTON = 0x44;    // |<< on the Car MP3 remote
const uint16_t RIGHT_BUTTON = 0x40;   // >>|
const uint16_t CENTER_BUTTON = 0x43;  // >||

void setup() {
  servo.attach(9);
  servo.write(angle);
  IrReceiver.begin(11);
  Serial.begin(9600);
}

void loop() {
  if (IrReceiver.decode()) {
    uint16_t code = IrReceiver.decodedIRData.command;
    IrReceiver.resume();

    // Holding a button sends repeats, which keeps the servo moving. Nice!
    if (code == LEFT_BUTTON) angle += 10;
    else if (code == RIGHT_BUTTON) angle -= 10;
    else if (code == CENTER_BUTTON) angle = 90;

    angle = constrain(angle, 0, 180);
    servo.write(angle);
    Serial.print("Servo angle: ");
    Serial.println(angle);
  }
}
