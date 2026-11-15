// @title Police Siren Sound
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; passive piezo buzzer + to pin 8, - to GND (an active buzzer only beeps one note).
// @keywords buzzer siren, police siren sound, wailing siren arduino, tone sweep
// @about Makes a wailing siren and a fast yelp siren with a passive buzzer.

const int BUZZER_PIN = 8;

void wail() {
  for (int f = 500; f <= 1500; f += 10) {  // slide up
    tone(BUZZER_PIN, f);
    delay(4);
  }
  for (int f = 1500; f >= 500; f -= 10) {  // slide down
    tone(BUZZER_PIN, f);
    delay(4);
  }
}

void yelp() {
  for (int f = 700; f <= 1600; f += 30) {  // short quick sweep
    tone(BUZZER_PIN, f);
    delay(2);
  }
}

void setup() {
  pinMode(BUZZER_PIN, OUTPUT);
}

void loop() {
  for (int i = 0; i < 3; i++) wail();
  for (int i = 0; i < 12; i++) yelp();
  noTone(BUZZER_PIN);
  delay(1000);  // a little break for your ears
}
