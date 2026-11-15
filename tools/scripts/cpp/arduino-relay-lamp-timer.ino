// @title Relay Lamp On and Off Timer
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; 5V relay module IN to pin 7, VCC 5V, GND GND; switch a LOW voltage device only (like a 12V LED strip), never mains without an adult.
// @keywords relay module, relay timer, switch a lamp arduino, relay on off cycle
// @about Clicks a relay on for 5 seconds and off for 5 seconds to switch a lamp or LED strip.

const int RELAY_PIN = 7;
// Many relay modules are "active LOW": LOW turns them on. Flip these if yours is backwards.
const int RELAY_ON = LOW;
const int RELAY_OFF = HIGH;

void setup() {
  digitalWrite(RELAY_PIN, RELAY_OFF);  // set it off BEFORE making it an output, so it doesn't click on
  pinMode(RELAY_PIN, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  Serial.println("Relay ON");
  digitalWrite(RELAY_PIN, RELAY_ON);
  delay(5000);

  Serial.println("Relay OFF");
  digitalWrite(RELAY_PIN, RELAY_OFF);
  delay(5000);
}
