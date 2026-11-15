// @title Relay Toggle Button
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; relay module IN to pin 7, VCC 5V, GND; push button between pin 2 and GND; LED on pin 13 shows the state.
// @keywords relay button toggle, push button relay, latching switch arduino, toggle a relay
// @about Each button press flips a relay on or off, like a normal light switch.

const int RELAY_PIN = 7;
const int BUTTON_PIN = 2;
bool relayOn = false;
bool lastButton = HIGH;
unsigned long lastChange = 0;

void setup() {
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
}

void loop() {
  bool button = digitalRead(BUTTON_PIN);

  // Only count a press if 50 ms have passed since the last change (debounce).
  if (button != lastButton && millis() - lastChange > 50) {
    lastChange = millis();
    if (button == LOW) {  // pressed down
      relayOn = !relayOn;
      digitalWrite(RELAY_PIN, relayOn ? HIGH : LOW);
      digitalWrite(LED_BUILTIN, relayOn ? HIGH : LOW);
    }
    lastButton = button;
  }
}
