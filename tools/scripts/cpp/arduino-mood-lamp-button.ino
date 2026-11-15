// @title Mood Lamp with a Mode Button
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; RGB LED red 9, green 10, blue 11 (220 ohm each); push button between pin 2 and GND.
// @keywords mood lamp, rgb mode button, night lamp colors, cycle colors with button
// @about Each button press changes the lamp mode: warm, cool, party flash, slow rainbow or off.

const int R = 9, G = 10, B = 11, BUTTON = 2;
int mode = 0;
const int MODES = 5;
bool lastButton = HIGH;

void color(int r, int g, int b) {
  analogWrite(R, r);
  analogWrite(G, g);
  analogWrite(B, b);
}

void setup() {
  pinMode(R, OUTPUT);
  pinMode(G, OUTPUT);
  pinMode(B, OUTPUT);
  pinMode(BUTTON, INPUT_PULLUP);
}

void loop() {
  bool button = digitalRead(BUTTON);
  if (button == LOW && lastButton == HIGH) {  // just pressed
    mode = (mode + 1) % MODES;
    delay(40);  // tiny debounce
  }
  lastButton = button;

  unsigned long t = millis();
  switch (mode) {
    case 0: color(255, 90, 10); break;   // warm
    case 1: color(40, 120, 255); break;  // cool
    case 2:                              // party: new color every 150 ms
      if ((t / 150) % 3 == 0) color(255, 0, 0);
      else if ((t / 150) % 3 == 1) color(0, 255, 0);
      else color(0, 0, 255);
      break;
    case 3: {                            // slow rainbow using sine waves
      float s = t / 1000.0;
      color((sin(s) + 1) * 127, (sin(s + 2.1) + 1) * 127, (sin(s + 4.2) + 1) * 127);
      break;
    }
    default: color(0, 0, 0); break;      // off
  }
}
