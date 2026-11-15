// @title Fade an LED Up and Down
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; LED long leg through a 220 ohm resistor to pin 9, short leg to GND.
// @keywords arduino fade, led fade in out, analogwrite pwm, dimming led arduino
// @about Slowly brightens an LED and then dims it again, over and over, using PWM.

const int LED_PIN = 9;  // PWM pins have a ~: 3, 5, 6, 9, 10, 11
int brightness = 0;
int step = 5;           // how much to change each time

void setup() {
  pinMode(LED_PIN, OUTPUT);
}

void loop() {
  analogWrite(LED_PIN, brightness);  // 0 = off, 255 = full on
  brightness += step;

  // At the top or bottom, turn around.
  if (brightness <= 0 || brightness >= 255) {
    step = -step;
  }
  delay(30);
}
