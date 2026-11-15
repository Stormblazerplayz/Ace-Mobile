// @title Firefly Jar LEDs
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; 6 yellow-green LEDs with 220 ohm resistors on the PWM pins 3, 5, 6, 9, 10 and 11; put them in a jar for a firefly lamp.
// @keywords firefly leds, random glowing leds, firefly jar, random led flicker
// @about Makes LEDs glow up and fade out at random times like fireflies in a jar.

const int PINS[] = {3, 5, 6, 9, 10, 11};
const int COUNT = 6;

void glow(int pin) {
  for (int b = 0; b <= 255; b += 5) {  // fade in
    analogWrite(pin, b);
    delay(4);
  }
  for (int b = 255; b >= 0; b -= 3) {  // fade out slower
    analogWrite(pin, b);
    delay(6);
  }
}

void setup() {
  for (int i = 0; i < COUNT; i++) pinMode(PINS[i], OUTPUT);
  randomSeed(analogRead(A0));  // an unconnected pin gives a random start
}

void loop() {
  int which = random(COUNT);  // 0 to 5
  glow(PINS[which]);
  delay(random(100, 1500));   // wait a random time before the next one
}
