// @title Rock Paper Scissors vs Arduino
// @category Arduino
// @kind Arduino sketch
// @where Any Arduino; open Serial Monitor at 9600; type r, p or s and press Enter. Optional: green LED on pin 4 (you win), red LED on pin 5 (Arduino wins).
// @keywords arduino rock paper scissors, serial monitor game, play against arduino, rps serial
// @about Play rock paper scissors against the Arduino by typing r, p or s, and it keeps score.

const int WIN_LED = 4, LOSE_LED = 5;
int youWins = 0, arduinoWins = 0;
const char *NAMES[3] = {"Rock", "Paper", "Scissors"};

void setup() {
  pinMode(WIN_LED, OUTPUT);
  pinMode(LOSE_LED, OUTPUT);
  Serial.begin(9600);
  randomSeed(analogRead(A0));
  Serial.println("Type r (rock), p (paper) or s (scissors):");
}

void loop() {
  if (!Serial.available()) return;
  char c = Serial.read();
  int you;
  if (c == 'r') you = 0;
  else if (c == 'p') you = 1;
  else if (c == 's') you = 2;
  else return;  // ignore Enter and other keys

  int arduino = random(3);
  Serial.print("You: ");
  Serial.print(NAMES[you]);
  Serial.print("  Arduino: ");
  Serial.print(NAMES[arduino]);
  Serial.print("  -> ");

  digitalWrite(WIN_LED, LOW);
  digitalWrite(LOSE_LED, LOW);
  // Trick: paper(1) beats rock(0), scissors(2) beats paper(1), rock(0) beats scissors(2).
  if (you == arduino) {
    Serial.print("Tie!");
  } else if ((you - arduino + 3) % 3 == 1) {
    Serial.print("You win!");
    youWins++;
    digitalWrite(WIN_LED, HIGH);
  } else {
    Serial.print("Arduino wins!");
    arduinoWins++;
    digitalWrite(LOSE_LED, HIGH);
  }
  Serial.print("   Score ");
  Serial.print(youWins);
  Serial.print(" - ");
  Serial.println(arduinoWins);
}
