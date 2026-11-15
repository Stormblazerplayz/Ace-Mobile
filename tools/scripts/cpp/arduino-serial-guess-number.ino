// @title Guess the Number in Serial Monitor
// @category Arduino
// @kind Arduino sketch
// @where Any Arduino; open Serial Monitor at 9600 and set the line ending to "Newline"; type guesses and press Enter.
// @keywords serial game, arduino guessing game, guess the number serial monitor, higher lower arduino
// @about The Arduino picks a number from 1 to 100 and tells you higher or lower until you guess it.

int secret;
int tries;

void newGame() {
  secret = random(1, 101);
  tries = 0;
  Serial.println("\nI'm thinking of a number from 1 to 100. Guess!");
}

void setup() {
  Serial.begin(9600);
  randomSeed(analogRead(A0));
  newGame();
}

void loop() {
  if (Serial.available() == 0) return;

  int guess = Serial.parseInt();
  while (Serial.available()) Serial.read();  // clear the Enter key
  if (guess < 1 || guess > 100) {
    Serial.println("Type a number from 1 to 100.");
    return;
  }

  tries++;
  Serial.print(guess);
  if (guess < secret) {
    Serial.println(" is too LOW.");
  } else if (guess > secret) {
    Serial.println(" is too HIGH.");
  } else {
    Serial.print(" is RIGHT! You got it in ");
    Serial.print(tries);
    Serial.println(" tries.");
    newGame();
  }
}
