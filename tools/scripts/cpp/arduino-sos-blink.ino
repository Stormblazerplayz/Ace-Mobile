// @title SOS Signal Light
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; uses the built-in LED on pin 13, or add a bright LED with a 220 ohm resistor on pin 13.
// @keywords sos blink, morse sos, emergency light, dots and dashes led
// @about Flashes S O S in Morse code: three short, three long, three short.

const int LED_PIN = LED_BUILTIN;
const int DOT = 200;  // one "unit" of time in Morse

void flash(int length) {
  digitalWrite(LED_PIN, HIGH);
  delay(length);
  digitalWrite(LED_PIN, LOW);
  delay(DOT);  // gap between flashes in the same letter
}

void letterS() {
  for (int i = 0; i < 3; i++) flash(DOT);      // . . .
}

void letterO() {
  for (int i = 0; i < 3; i++) flash(DOT * 3);  // - - -
}

void setup() {
  pinMode(LED_PIN, OUTPUT);
}

void loop() {
  letterS();
  delay(DOT * 2);  // a letter gap is 3 units (we already waited 1)
  letterO();
  delay(DOT * 2);
  letterS();
  delay(DOT * 6);  // a word gap is 7 units
}
