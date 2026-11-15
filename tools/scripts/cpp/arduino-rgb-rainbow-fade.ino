// @title RGB LED Rainbow Fade
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; common cathode RGB LED: red to pin 9, green to 10, blue to 11 (220 ohm each), long leg to GND.
// @keywords rgb rainbow fade, color wheel rgb led, smooth color change, rgb cycle colors
// @about Smoothly fades one RGB LED through every color of the rainbow.

const int RED_PIN = 9, GREEN_PIN = 10, BLUE_PIN = 11;

// Turns a position on the color wheel (0 to 767) into red, green and blue.
void wheel(int pos) {
  int r, g, b;
  if (pos < 256) {         // red -> green
    r = 255 - pos; g = pos; b = 0;
  } else if (pos < 512) {  // green -> blue
    pos -= 256;
    r = 0; g = 255 - pos; b = pos;
  } else {                 // blue -> red
    pos -= 512;
    r = pos; g = 0; b = 255 - pos;
  }
  analogWrite(RED_PIN, r);
  analogWrite(GREEN_PIN, g);
  analogWrite(BLUE_PIN, b);
}

void setup() {
  pinMode(RED_PIN, OUTPUT);
  pinMode(GREEN_PIN, OUTPUT);
  pinMode(BLUE_PIN, OUTPUT);
}

void loop() {
  for (int pos = 0; pos < 768; pos++) {
    wheel(pos);
    delay(8);
  }
}
