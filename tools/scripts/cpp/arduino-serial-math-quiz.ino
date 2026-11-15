// @title Math Quiz in the Serial Monitor
// @category Arduino
// @kind Arduino sketch
// @where Any Arduino; open Serial Monitor at 9600 with line ending "Newline"; type answers and press Enter. Optional buzzer on pin 8.
// @keywords arduino math quiz, times tables quiz serial, mental math game arduino, quiz with buzzer
// @about Asks 10 random add, subtract and multiply questions, beeps for right or wrong, and gives a final score.

const int BUZZER = 8;
int question = 0;
int score = 0;
int answer;

void ask() {
  int a = random(2, 13);
  int b = random(2, 13);
  int kind = random(3);
  Serial.print("Question ");
  Serial.print(question + 1);
  Serial.print(": ");
  Serial.print(a);
  if (kind == 0) { Serial.print(" + "); answer = a + b; }
  else if (kind == 1) { Serial.print(" - "); answer = a - b; }
  else { Serial.print(" x "); answer = a * b; }
  Serial.print(b);
  Serial.println(" = ?");
}

void setup() {
  pinMode(BUZZER, OUTPUT);
  Serial.begin(9600);
  randomSeed(analogRead(A0));
  Serial.println("Math quiz! 10 questions. Go!");
  ask();
}

void loop() {
  if (!Serial.available()) return;
  long typed = Serial.parseInt();  // also reads negative numbers like -3
  while (Serial.available()) Serial.read();

  if (typed == answer) {
    Serial.println("Correct!");
    score++;
    tone(BUZZER, 1500, 150);
  } else {
    Serial.print("Oops, it was ");
    Serial.println(answer);
    tone(BUZZER, 200, 400);
  }

  question++;
  if (question == 10) {
    Serial.print("\nYou scored ");
    Serial.print(score);
    Serial.println(" out of 10!");
    if (score == 10) Serial.println("PERFECT! You're a math wizard.");
    Serial.println("\nNew quiz starting...");
    question = 0;
    score = 0;
    delay(2000);
  }
  ask();
}
