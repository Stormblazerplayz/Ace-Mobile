// @title LED that Gets Brighter in the Dark
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; photoresistor from 5V to A0 with a 10k resistor from A0 to GND; LED with 220 ohm resistor on pin 9 (a PWM pin).
// @keywords auto brightness led, ldr dim led, darker room brighter led, analogwrite light sensor
// @about Smoothly makes an LED brighter as the room gets darker, using PWM.

const int LIGHT_PIN = A0;
const int LED_PIN = 9;  // must be a ~ pin: 3, 5, 6, 9, 10 or 11 on an Uno

float smoothLight = 512;  // a running average stops flicker

void setup() {
  pinMode(LED_PIN, OUTPUT);
}

void loop() {
  int raw = analogRead(LIGHT_PIN);
  // Move 10% of the way toward the new reading each time.
  smoothLight = smoothLight * 0.9 + raw * 0.1;

  // Bright room (1023) -> LED off (0). Dark room (0) -> LED full (255).
  int brightness = map((int)smoothLight, 0, 1023, 255, 0);
  brightness = constrain(brightness, 0, 255);
  analogWrite(LED_PIN, brightness);
  delay(20);
}
