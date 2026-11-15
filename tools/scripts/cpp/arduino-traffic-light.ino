// @title Traffic Light
// @category Arduino
// @kind Arduino sketch
// @where Paste this into a new Arduino IDE sketch and upload it; wire a red LED to pin 12, yellow to pin 11 and green to pin 10, each through a 220 ohm resistor, with every short leg going to GND.
// @keywords arduino traffic light, arduino red yellow green leds, arduino stop light, three leds arduino
// @about Runs three LEDs like a real traffic light: green, yellow, then red.

const int RED_PIN = 12;
const int YELLOW_PIN = 11;
const int GREEN_PIN = 10;

// Turn on just one light and turn the others off.
void showLight(int pinToTurnOn) {
  digitalWrite(RED_PIN, pinToTurnOn == RED_PIN ? HIGH : LOW);
  digitalWrite(YELLOW_PIN, pinToTurnOn == YELLOW_PIN ? HIGH : LOW);
  digitalWrite(GREEN_PIN, pinToTurnOn == GREEN_PIN ? HIGH : LOW);
}

void setup() {
  pinMode(RED_PIN, OUTPUT);
  pinMode(YELLOW_PIN, OUTPUT);
  pinMode(GREEN_PIN, OUTPUT);
}

void loop() {
  showLight(GREEN_PIN);
  delay(5000);  // go for 5 seconds

  showLight(YELLOW_PIN);
  delay(2000);  // slow down for 2 seconds

  showLight(RED_PIN);
  delay(5000);  // stop for 5 seconds
}
