// @title Button Turns On an LED
// @category Arduino
// @kind Arduino sketch
// @where Paste this into a new Arduino IDE sketch and upload it; wire one leg of a push button to pin 2 and the other leg to GND, and use the built-in LED.
// @keywords arduino button, arduino push button led, button turns on light arduino, arduino debounce, arduino input pullup
// @about Each press of the button flips the LED on or off, with debounce so one press counts once.

const int BUTTON_PIN = 2;
const int LED_PIN = LED_BUILTIN;
const unsigned long DEBOUNCE_MS = 50;  // ignore wobbles shorter than this

bool ledOn = false;
int lastReading = HIGH;          // what the pin said last time
int stableState = HIGH;          // the "real" button state after debounce
unsigned long lastChangeTime = 0;

void setup() {
  // INPUT_PULLUP keeps the pin HIGH until the button connects it to GND.
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(LED_PIN, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  int reading = digitalRead(BUTTON_PIN);

  // The reading changed, so restart the debounce timer.
  if (reading != lastReading) {
    lastChangeTime = millis();
  }

  // It stayed the same long enough, so trust it.
  if (millis() - lastChangeTime > DEBOUNCE_MS && reading != stableState) {
    stableState = reading;

    // LOW means pressed (the pin is pulled to GND).
    if (stableState == LOW) {
      ledOn = !ledOn;
      digitalWrite(LED_PIN, ledOn ? HIGH : LOW);
      Serial.println(ledOn ? "LED ON" : "LED OFF");
    }
  }

  lastReading = reading;
}
