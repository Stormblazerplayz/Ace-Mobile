// @title Buzzer Melody
// @category Arduino
// @kind Arduino sketch
// @where Paste this into a new Arduino IDE sketch and upload it; wire the buzzer's + leg to pin 8 and the - leg to GND.
// @keywords arduino buzzer, arduino melody, play a song on arduino, arduino tone music, arduino piezo
// @about Plays "Twinkle Twinkle Little Star" on a buzzer, then waits and plays it again.

const int BUZZER_PIN = 8;

// Note pitches in Hz (0 means a rest).
const int NOTE_C = 262, NOTE_D = 294, NOTE_E = 330, NOTE_F = 349, NOTE_G = 392, NOTE_A = 440;

const int melody[] = {
  NOTE_C, NOTE_C, NOTE_G, NOTE_G, NOTE_A, NOTE_A, NOTE_G, 0,
  NOTE_F, NOTE_F, NOTE_E, NOTE_E, NOTE_D, NOTE_D, NOTE_C, 0
};

// How long each note lasts: 4 = quarter note, 2 = half note.
const int beats[] = {
  4, 4, 4, 4, 4, 4, 2, 4,
  4, 4, 4, 4, 4, 4, 2, 4
};

const int NOTE_COUNT = sizeof(melody) / sizeof(melody[0]);
const int WHOLE_NOTE_MS = 1600;  // smaller = faster song

void setup() {
  pinMode(BUZZER_PIN, OUTPUT);
}

void loop() {
  for (int i = 0; i < NOTE_COUNT; i++) {
    int noteLength = WHOLE_NOTE_MS / beats[i];

    if (melody[i] > 0) {
      tone(BUZZER_PIN, melody[i], noteLength);
    }

    // Wait a little longer than the note so notes don't blur together.
    delay(noteLength * 13 / 10);
    noTone(BUZZER_PIN);
  }

  delay(2000);  // pause before playing again
}
