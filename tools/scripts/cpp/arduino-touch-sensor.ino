// @title Touch Sensor Lamp
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; TTP223 touch module SIG to pin 2, VCC 5V, GND; LED with 220 ohm resistor on pin 9.
// @keywords ttp223, capacitive touch sensor, touch lamp arduino, tap to change brightness
// @about Each tap on the touch pad changes a lamp between off, dim, medium and bright.

const int TOUCH_PIN = 2;
const int LED_PIN = 9;
const int LEVELS[] = {0, 30, 110, 255};  // off, dim, medium, bright
int level = 0;
int lastTouch = LOW;

void setup() {
  pinMode(TOUCH_PIN, INPUT);
  pinMode(LED_PIN, OUTPUT);
}

void loop() {
  int touch = digitalRead(TOUCH_PIN);  // HIGH while a finger is on it

  if (touch == HIGH && lastTouch == LOW) {  // a new tap
    level = (level + 1) % 4;                // 0,1,2,3 then back to 0
    analogWrite(LED_PIN, LEVELS[level]);
  }
  lastTouch = touch;
  delay(30);
}
