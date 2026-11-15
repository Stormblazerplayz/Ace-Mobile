// @title Happy Birthday Song
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; passive buzzer + to pin 8, - to GND; push button between pin 2 and GND to play it.
// @keywords happy birthday arduino, birthday song buzzer, play a tune on button press, arduino notes array
// @about Plays Happy Birthday on a buzzer each time you press the button.

const int BUZZER_PIN = 8;
const int BUTTON_PIN = 2;

// Note frequencies in Hz.
const int C4 = 262, D4 = 294, E4 = 330, F4 = 349, G4 = 392, A4n = 440, AS4 = 466, C5 = 523;

const int melody[] = {C4, C4, D4, C4, F4, E4,  C4, C4, D4, C4, G4, F4,
                      C4, C4, C5, A4n, F4, E4, D4,  AS4, AS4, A4n, F4, G4, F4};
// 4 = quarter note, 2 = half note, 8 = eighth note.
const int beats[] = {8, 8, 4, 4, 4, 2,  8, 8, 4, 4, 4, 2,
                     8, 8, 4, 4, 4, 4, 2,  8, 8, 4, 4, 4, 2};
const int NOTE_COUNT = sizeof(melody) / sizeof(melody[0]);

void playSong() {
  for (int i = 0; i < NOTE_COUNT; i++) {
    int duration = 1000 / beats[i];
    tone(BUZZER_PIN, melody[i], duration);
    delay(duration * 13 / 10);  // a little gap so the notes don't blur
  }
  noTone(BUZZER_PIN);
}

void setup() {
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
}

void loop() {
  if (digitalRead(BUTTON_PIN) == LOW) {
    playSong();
  }
}
