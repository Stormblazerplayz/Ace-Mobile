// @title Single 7-Segment Display Counter
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; common cathode 7-segment display: segments a to g on pins 2 to 8 (each through a 220 ohm resistor), dot on pin 9, common pins to GND.
// @keywords seven segment display, 7 segment digit, count 0 to 9 display, common cathode display
// @about Counts from 0 to 9 on a single 7-segment display by lighting the right segments.

// Segments:   a  b  c  d  e  f  g
const int SEG_PINS[7] = {2, 3, 4, 5, 6, 7, 8};
const int DOT_PIN = 9;

// For each digit, which segments are on (1) or off (0), in the order a b c d e f g.
const byte DIGITS[10][7] = {
  {1, 1, 1, 1, 1, 1, 0},  // 0
  {0, 1, 1, 0, 0, 0, 0},  // 1
  {1, 1, 0, 1, 1, 0, 1},  // 2
  {1, 1, 1, 1, 0, 0, 1},  // 3
  {0, 1, 1, 0, 0, 1, 1},  // 4
  {1, 0, 1, 1, 0, 1, 1},  // 5
  {1, 0, 1, 1, 1, 1, 1},  // 6
  {1, 1, 1, 0, 0, 0, 0},  // 7
  {1, 1, 1, 1, 1, 1, 1},  // 8
  {1, 1, 1, 1, 0, 1, 1}   // 9
};

void showDigit(int digit) {
  for (int s = 0; s < 7; s++) {
    digitalWrite(SEG_PINS[s], DIGITS[digit][s] ? HIGH : LOW);
  }
}

void setup() {
  for (int s = 0; s < 7; s++) pinMode(SEG_PINS[s], OUTPUT);
  pinMode(DOT_PIN, OUTPUT);
}

void loop() {
  for (int d = 0; d <= 9; d++) {
    showDigit(d);
    digitalWrite(DOT_PIN, d % 2);  // blink the dot on odd numbers
    delay(800);
  }
}
