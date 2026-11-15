// @title Twinkle Twinkle Little Star with LEDs
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; passive buzzer on pin 8; optional LEDs with 220 ohm resistors on pins 2 to 7, one for each note.
// @keywords twinkle twinkle little star, song with lights, notes light up leds, arduino music box
// @about Plays Twinkle Twinkle Little Star and lights a different LED for each note, like a music box.

const int BUZZER_PIN = 8;
// Notes C D E F G A, each has its own LED on pins 2..7.
const int FREQ[] = {262, 294, 330, 349, 392, 440};
const char SONG[] = "CCGGAAG FFEEDDC GGFFEED GGFFEED CCGGAAG FFEEDDC";

void setup() {
  pinMode(BUZZER_PIN, OUTPUT);
  for (int pin = 2; pin <= 7; pin++) pinMode(pin, OUTPUT);
}

void loop() {
  for (int i = 0; SONG[i] != '\0'; i++) {
    char letter = SONG[i];
    if (letter == ' ') {  // a space is a rest
      delay(400);
      continue;
    }
    int n = letter - 'C';  // C->0, D->1, E->2, F->3, G->4
    if (letter == 'A') n = 5;  // A comes before C in the alphabet, so set it by hand
    // Is it the last note before a space or the end? Hold it longer.
    bool longNote = SONG[i + 1] == ' ' || SONG[i + 1] == '\0';
    int length = longNote ? 700 : 350;

    digitalWrite(2 + n, HIGH);
    tone(BUZZER_PIN, FREQ[n], length);
    delay(length + 50);
    digitalWrite(2 + n, LOW);
  }
  delay(2000);
}
