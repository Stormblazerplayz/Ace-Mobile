// @title Control LEDs with a TV Remote
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "IRremote" (version 4+); IR receiver OUT to pin 11; LEDs with 220 ohm resistors on pins 4, 5 and 6. Change the codes to match your remote (use the code finder sketch).
// @keywords ir remote led control, remote control lights, irremote switch case, turn on led with remote
// @about Turns three LEDs on and off with buttons 1, 2 and 3 on an infrared remote and button 0 turns all off.

#include <IRremote.hpp>

const int IR_PIN = 11;
const int LED_PINS[] = {4, 5, 6};

// These are the codes for the common little "Car MP3" style remote.
const uint16_t BUTTON_0 = 0x16;
const uint16_t BUTTON_1 = 0x0C;
const uint16_t BUTTON_2 = 0x18;
const uint16_t BUTTON_3 = 0x5E;

bool ledOn[3] = {false, false, false};

void toggle(int which) {
  ledOn[which] = !ledOn[which];
  digitalWrite(LED_PINS[which], ledOn[which] ? HIGH : LOW);
}

void setup() {
  for (int i = 0; i < 3; i++) pinMode(LED_PINS[i], OUTPUT);
  IrReceiver.begin(IR_PIN);
}

void loop() {
  if (!IrReceiver.decode()) return;  // nothing pressed yet

  bool isRepeat = IrReceiver.decodedIRData.flags & IRDATA_FLAGS_IS_REPEAT;
  uint16_t code = IrReceiver.decodedIRData.command;
  IrReceiver.resume();
  if (isRepeat) return;

  switch (code) {
    case BUTTON_1: toggle(0); break;
    case BUTTON_2: toggle(1); break;
    case BUTTON_3: toggle(2); break;
    case BUTTON_0:
      for (int i = 0; i < 3; i++) {
        ledOn[i] = false;
        digitalWrite(LED_PINS[i], LOW);
      }
      break;
  }
}
