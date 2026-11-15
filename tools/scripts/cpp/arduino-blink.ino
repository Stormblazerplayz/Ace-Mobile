// @title Blink an LED
// @category Arduino
// @kind Arduino sketch
// @where Paste this into a new sketch in the Arduino IDE and upload it to your board. Uses the built-in LED, so no wiring needed.
// @keywords arduino blink, blink led arduino, flash the arduino light, arduino led on and off
// @about Turns the board's LED on and off every second.

// How long the LED stays on (and off), in milliseconds.
const unsigned long BLINK_TIME = 1000;

void setup() {
  // Tell the board this pin is an output (it sends power out).
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  digitalWrite(LED_BUILTIN, HIGH);  // LED on
  delay(BLINK_TIME);                // wait 1 second
  digitalWrite(LED_BUILTIN, LOW);   // LED off
  delay(BLINK_TIME);                // wait 1 second
}
