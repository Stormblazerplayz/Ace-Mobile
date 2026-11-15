// @title Find Your IR Remote's Button Codes
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "IRremote" by Armin Joachimsmeyer (version 4 or newer); IR receiver (VS1838B) OUT to pin 11, VCC 5V, GND; open Serial Monitor at 9600.
// @keywords ir remote codes, arduino ir receiver, irremote decode, vs1838b, tv remote arduino
// @about Prints the code of every button you press on an infrared remote so you can use them in other projects.

#include <IRremote.hpp>

const int IR_PIN = 11;

void setup() {
  Serial.begin(9600);
  // ENABLE_LED_FEEDBACK makes the built-in LED flicker when a signal arrives.
  IrReceiver.begin(IR_PIN, ENABLE_LED_FEEDBACK);
  Serial.println("Point a remote at the sensor and press buttons.");
}

void loop() {
  if (IrReceiver.decode()) {
    // A held button sends "repeat" messages; skip those.
    if (!(IrReceiver.decodedIRData.flags & IRDATA_FLAGS_IS_REPEAT)) {
      Serial.print("Button code: 0x");
      Serial.print(IrReceiver.decodedIRData.command, HEX);
      Serial.print("   (");
      Serial.print(IrReceiver.decodedIRData.command);
      Serial.println(" in normal numbers)");
    }
    IrReceiver.resume();  // get ready for the next button
  }
}
