// @title Four Button Piano
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; 4 push buttons from pins 2, 3, 4, 5 to GND; passive buzzer + to pin 8, - to GND.
// @keywords arduino piano, button keyboard, play notes with buttons, mini piano buzzer
// @about Turns four buttons into piano keys that play C, D, E and G while you hold them.

const int BUZZER_PIN = 8;
const int BUTTONS[] = {2, 3, 4, 5};
const int NOTES[] = {262, 294, 330, 392};  // C, D, E, G
const int KEY_COUNT = 4;

void setup() {
  for (int i = 0; i < KEY_COUNT; i++) pinMode(BUTTONS[i], INPUT_PULLUP);
  pinMode(BUZZER_PIN, OUTPUT);
}

void loop() {
  int playing = -1;  // -1 means no key is held
  for (int i = 0; i < KEY_COUNT; i++) {
    if (digitalRead(BUTTONS[i]) == LOW) {
      playing = i;
      break;  // a buzzer can only play one note at a time
    }
  }

  if (playing >= 0) tone(BUZZER_PIN, NOTES[playing]);
  else noTone(BUZZER_PIN);
  delay(10);
}
