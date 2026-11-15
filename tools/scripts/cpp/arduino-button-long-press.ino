// @title Short Press vs Long Press
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; push button between pin 2 and GND; LED on pin 9 (220 ohm); open Serial Monitor at 9600.
// @keywords long press button, hold button arduino, short and long press, button press duration
// @about Tells a quick tap from a long hold: a tap changes the LED brightness and a 1 second hold turns it off.

const int BUTTON = 2, LED = 9;
const unsigned long LONG_PRESS_MS = 1000;
const int LEVELS[] = {40, 120, 255};

int level = 0;
bool ledOn = true;
bool wasPressed = false;
bool longDone = false;
unsigned long pressStart = 0;

void setup() {
  pinMode(BUTTON, INPUT_PULLUP);
  pinMode(LED, OUTPUT);
  Serial.begin(9600);
  analogWrite(LED, LEVELS[level]);
}

void loop() {
  bool pressed = digitalRead(BUTTON) == LOW;

  if (pressed && !wasPressed) {         // just pushed down
    pressStart = millis();
    longDone = false;
  }

  if (pressed && !longDone && millis() - pressStart >= LONG_PRESS_MS) {
    longDone = true;                    // held long enough: act now, don't wait for release
    ledOn = false;
    analogWrite(LED, 0);
    Serial.println("Long press: LED off");
  }

  if (!pressed && wasPressed && !longDone && millis() - pressStart > 30) {
    // Let go before 1 second: a short press. (Under 30 ms is just bounce.)
    if (ledOn) level = (level + 1) % 3;
    ledOn = true;
    analogWrite(LED, LEVELS[level]);
    Serial.print("Short press: brightness level ");
    Serial.println(level + 1);
  }

  wasPressed = pressed;
  delay(5);
}
