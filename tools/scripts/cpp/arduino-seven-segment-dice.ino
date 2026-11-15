// @title Electronic Dice on a 7-Segment Display
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; common cathode 7-segment, segments a to g on pins 2 to 8 (220 ohm each), common to GND; button between pin 10 and GND; buzzer on pin 11.
// @keywords electronic dice, 7 segment dice, roll a die arduino, random number display
// @about Press the button to roll: the numbers spin fast, slow down and stop on a random 1 to 6.

const int SEG_PINS[7] = {2, 3, 4, 5, 6, 7, 8};
const int BUTTON_PIN = 10;
const int BUZZER_PIN = 11;

// Bit patterns: bit 0 = a, bit 1 = b ... bit 6 = g.
const byte PATTERNS[7] = {0, 0b0000110, 0b1011011, 0b1001111, 0b1100110, 0b1101101, 0b1111101};

void show(int number) {
  for (int s = 0; s < 7; s++) {
    digitalWrite(SEG_PINS[s], bitRead(PATTERNS[number], s) ? HIGH : LOW);
  }
}

void setup() {
  for (int s = 0; s < 7; s++) pinMode(SEG_PINS[s], OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(BUZZER_PIN, OUTPUT);
  randomSeed(analogRead(A0));
  show(1);
}

void loop() {
  if (digitalRead(BUTTON_PIN) == LOW) {
    // Spin: start fast, get slower, like a real rolling die.
    for (int wait = 20; wait < 300; wait = wait * 12 / 10 + 1) {
      show(random(1, 7));  // 1 to 6 (the top number is not included)
      tone(BUZZER_PIN, 1200, 10);
      delay(wait);
    }
    int result = random(1, 7);
    show(result);
    tone(BUZZER_PIN, 1800, 200);
    while (digitalRead(BUTTON_PIN) == LOW) delay(10);
  }
}
