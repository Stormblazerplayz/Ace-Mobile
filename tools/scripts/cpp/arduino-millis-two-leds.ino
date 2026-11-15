// @title Blink Two LEDs at Different Speeds
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; LED A with 220 ohm resistor on pin 8, LED B on pin 9.
// @keywords blink without delay, millis two leds, arduino multitasking, do two things at once
// @about Blinks one LED every 250 ms and another every 1000 ms at the same time, using millis() instead of delay().

const int LED_A = 8;
const int LED_B = 9;
const unsigned long A_EVERY = 250;
const unsigned long B_EVERY = 1000;

unsigned long lastA = 0;
unsigned long lastB = 0;
bool aOn = false;
bool bOn = false;

void setup() {
  pinMode(LED_A, OUTPUT);
  pinMode(LED_B, OUTPUT);
}

void loop() {
  // delay() would freeze everything. Instead we check the clock and only act when it's time.
  unsigned long now = millis();

  if (now - lastA >= A_EVERY) {
    lastA = now;
    aOn = !aOn;
    digitalWrite(LED_A, aOn);
  }

  if (now - lastB >= B_EVERY) {
    lastB = now;
    bOn = !bOn;
    digitalWrite(LED_B, bOn);
  }
  // loop() runs thousands of times a second, so there's time for more jobs here!
}
