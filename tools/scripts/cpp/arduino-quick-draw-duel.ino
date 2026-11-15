// @title Two Player Quick Draw Duel
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; player 1 button pin 2 to GND with LED on pin 8; player 2 button pin 3 to GND with LED on pin 9; middle "go" LED on pin 10; buzzer on pin 11.
// @keywords quick draw game, two player reaction duel, fastest button wins, cowboy duel arduino
// @about Two players wait for the go light; the first to press wins, but pressing too early loses.

const int P1_BUTTON = 2, P2_BUTTON = 3;
const int P1_LED = 8, P2_LED = 9, GO_LED = 10, BUZZER = 11;
int p1Score = 0, p2Score = 0;

void winner(int led, int &score, const char *name) {
  score++;
  digitalWrite(led, HIGH);
  tone(BUZZER, 1800, 400);
  Serial.print(name);
  Serial.print(" wins!  Score  P1: ");
  Serial.print(p1Score);
  Serial.print("  P2: ");
  Serial.println(p2Score);
  delay(2000);
  digitalWrite(led, LOW);
}

void setup() {
  pinMode(P1_BUTTON, INPUT_PULLUP);
  pinMode(P2_BUTTON, INPUT_PULLUP);
  pinMode(P1_LED, OUTPUT);
  pinMode(P2_LED, OUTPUT);
  pinMode(GO_LED, OUTPUT);
  Serial.begin(9600);
  randomSeed(analogRead(A0));
}

void loop() {
  Serial.println("Ready... wait for the light!");
  unsigned long waitTime = random(2000, 6000);
  unsigned long waitStart = millis();

  while (millis() - waitStart < waitTime) {  // false start check
    if (digitalRead(P1_BUTTON) == LOW) { Serial.println("P1 jumped the gun!"); winner(P2_LED, p2Score, "P2"); return; }
    if (digitalRead(P2_BUTTON) == LOW) { Serial.println("P2 jumped the gun!"); winner(P1_LED, p1Score, "P1"); return; }
  }

  digitalWrite(GO_LED, HIGH);
  tone(BUZZER, 1000, 100);
  while (true) {
    if (digitalRead(P1_BUTTON) == LOW) { digitalWrite(GO_LED, LOW); winner(P1_LED, p1Score, "P1"); return; }
    if (digitalRead(P2_BUTTON) == LOW) { digitalWrite(GO_LED, LOW); winner(P2_LED, p2Score, "P2"); return; }
  }
}
