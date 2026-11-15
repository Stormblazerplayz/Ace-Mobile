// @title RGB LED Color Mixer
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; common cathode RGB LED: longest leg to GND, red leg to pin 9, green to 10, blue to 11, each through a 220 ohm resistor.
// @keywords rgb led, mix colors rgb, common cathode rgb, arduino rgb colors, setcolor function
// @about Shows red, green, blue, yellow, purple, cyan, orange and white on one RGB LED.

const int RED_PIN = 9;
const int GREEN_PIN = 10;
const int BLUE_PIN = 11;

// For a common ANODE LED (long leg to 5V), change this to true.
const bool COMMON_ANODE = false;

void setColor(int red, int green, int blue) {
  if (COMMON_ANODE) {  // anode LEDs are upside down: 255 means off
    red = 255 - red;
    green = 255 - green;
    blue = 255 - blue;
  }
  analogWrite(RED_PIN, red);
  analogWrite(GREEN_PIN, green);
  analogWrite(BLUE_PIN, blue);
}

void setup() {
  pinMode(RED_PIN, OUTPUT);
  pinMode(GREEN_PIN, OUTPUT);
  pinMode(BLUE_PIN, OUTPUT);
}

void loop() {
  setColor(255, 0, 0);     delay(700);  // red
  setColor(0, 255, 0);     delay(700);  // green
  setColor(0, 0, 255);     delay(700);  // blue
  setColor(255, 255, 0);   delay(700);  // yellow = red + green
  setColor(128, 0, 255);   delay(700);  // purple
  setColor(0, 255, 255);   delay(700);  // cyan = green + blue
  setColor(255, 80, 0);    delay(700);  // orange
  setColor(255, 255, 255); delay(700);  // white = everything
}
