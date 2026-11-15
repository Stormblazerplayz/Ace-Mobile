// @title Debounced Toggle Button
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; push button between pin 2 and GND; LED on pin 13 (built in); open Serial Monitor at 9600.
// @keywords debounce button, button bounce fix, toggle led debounced, millis debounce, clean button presses
// @about Shows how to debounce a button with millis() so one press always counts as exactly one press.

const int BUTTON = 2;
const unsigned long DEBOUNCE_MS = 30;

int stableState = HIGH;     // the state we trust
int lastReading = HIGH;     // the raw reading from last time
unsigned long lastFlicker = 0;
bool ledOn = false;
int presses = 0;

void setup() {
  pinMode(BUTTON, INPUT_PULLUP);
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  int reading = digitalRead(BUTTON);

  // When a button is pressed its metal contacts bounce, flickering for a few ms.
  // Each flicker restarts this timer...
  if (reading != lastReading) lastFlicker = millis();
  lastReading = reading;

  // ...so we only believe the reading once it has stayed the same for 30 ms.
  if (millis() - lastFlicker > DEBOUNCE_MS && reading != stableState) {
    stableState = reading;
    if (stableState == LOW) {  // a real, clean press
      presses++;
      ledOn = !ledOn;
      digitalWrite(LED_BUILTIN, ledOn);
      Serial.print("Press number ");
      Serial.println(presses);
    }
  }
}
