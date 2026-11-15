// @title Knight Rider LED Chaser
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; 8 LEDs, each with a 220 ohm resistor, on pins 2 to 9; potentiometer middle leg on A0 sets the speed.
// @keywords led chaser, knight rider leds, scanner lights, back and forth leds, kitt lights
// @about Makes a light zoom back and forth along 8 LEDs, and a knob changes the speed.

const int FIRST_PIN = 2;
const int LED_COUNT = 8;  // pins 2, 3, 4, 5, 6, 7, 8, 9

void setup() {
  for (int i = 0; i < LED_COUNT; i++) pinMode(FIRST_PIN + i, OUTPUT);
}

void lightOnly(int which) {
  for (int i = 0; i < LED_COUNT; i++) {
    digitalWrite(FIRST_PIN + i, i == which ? HIGH : LOW);
  }
}

int speedDelay() {
  return map(analogRead(A0), 0, 1023, 20, 200);  // knob: 20 ms to 200 ms
}

void loop() {
  for (int i = 0; i < LED_COUNT; i++) {  // go right
    lightOnly(i);
    delay(speedDelay());
  }
  for (int i = LED_COUNT - 2; i > 0; i--) {  // come back (skip the ends so they don't double)
    lightOnly(i);
    delay(speedDelay());
  }
}
