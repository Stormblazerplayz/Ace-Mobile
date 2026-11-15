// @title Hot Potato Party Game
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno (on a battery so you can pass it around); passive buzzer on pin 8; LED on pin 13; button pin 2 to GND starts a round.
// @keywords hot potato game, party game arduino, pass it before it beeps, ticking timer game
// @about Press start and pass the Arduino around while it ticks; whoever holds it when it explodes is out.

const int BUZZER = 8;
const int LED = 13;
const int START_BUTTON = 2;

void setup() {
  pinMode(BUZZER, OUTPUT);
  pinMode(LED, OUTPUT);
  pinMode(START_BUTTON, INPUT_PULLUP);
  randomSeed(analogRead(A0));
}

void explode() {
  for (int f = 1500; f > 100; f -= 20) {  // falling "boom" sound
    tone(BUZZER, f);
    digitalWrite(LED, f / 100 % 2);
    delay(8);
  }
  noTone(BUZZER);
  digitalWrite(LED, HIGH);
  delay(2000);
  digitalWrite(LED, LOW);
}

void loop() {
  if (digitalRead(START_BUTTON) == HIGH) return;  // wait for a press

  // The potato blows up after 10 to 30 seconds. Nobody knows when!
  unsigned long fuse = random(10000, 30000);
  unsigned long start = millis();

  while (millis() - start < fuse) {
    unsigned long left = fuse - (millis() - start);
    // Tick faster as time runs out (but players can't see the time).
    int gap = left > 8000 ? 600 : (left > 3000 ? 300 : 120);
    tone(BUZZER, 1000, 30);
    digitalWrite(LED, HIGH);
    delay(30);
    digitalWrite(LED, LOW);
    delay(gap);
  }
  explode();
}
