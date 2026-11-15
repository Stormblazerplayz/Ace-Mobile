// @title LED Dimmer Knob
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; potentiometer middle leg to A0 (outer legs 5V and GND); LED with 220 ohm resistor on pin 9.
// @keywords led dimmer, potentiometer led brightness, pwm dimmer knob, analogwrite potentiometer
// @about Turning a knob makes an LED dimmer or brighter.

const int POT_PIN = A0;
const int LED_PIN = 9;  // PWM pin (has a ~ next to it)

void setup() {
  pinMode(LED_PIN, OUTPUT);
}

void loop() {
  int knob = analogRead(POT_PIN);  // 0 to 1023
  // analogWrite only goes up to 255, so divide by 4.
  int brightness = knob / 4;
  analogWrite(LED_PIN, brightness);
  delay(10);
}
