// @title Single Click vs Double Click
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; push button between pin 2 and GND; green LED pin 4, blue LED pin 5 (220 ohm each); open Serial Monitor at 9600.
// @keywords double click button, detect double press, click counter button, one button two actions
// @about Detects whether you clicked once or twice quickly and toggles a different LED for each.

const int BUTTON = 2, GREEN = 4, BLUE = 5;
const unsigned long DOUBLE_GAP = 350;  // second click must come within 350 ms

int clicks = 0;
unsigned long lastRelease = 0;
bool wasPressed = false;
bool greenOn = false, blueOn = false;

void setup() {
  pinMode(BUTTON, INPUT_PULLUP);
  pinMode(GREEN, OUTPUT);
  pinMode(BLUE, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  bool pressed = digitalRead(BUTTON) == LOW;

  if (!pressed && wasPressed) {  // a click finished
    clicks++;
    lastRelease = millis();
  }
  wasPressed = pressed;

  // After the gap with no new click, decide what it was.
  if (clicks > 0 && !pressed && millis() - lastRelease > DOUBLE_GAP) {
    if (clicks == 1) {
      greenOn = !greenOn;
      digitalWrite(GREEN, greenOn);
      Serial.println("Single click -> green");
    } else {
      blueOn = !blueOn;
      digitalWrite(BLUE, blueOn);
      Serial.println("Double click -> blue");
    }
    clicks = 0;
  }
  delay(10);  // also works as a simple debounce
}
