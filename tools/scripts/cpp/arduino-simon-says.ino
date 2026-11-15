// @title Simon Says Memory Game
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; 4 LEDs (220 ohm) on pins 8, 9, 10, 11; 4 buttons from pins 2, 3, 4, 5 to GND (button 2 matches LED 8 and so on); passive buzzer on pin 12.
// @keywords simon says game, memory game arduino, repeat the pattern, simon game leds buttons
// @about Plays a growing pattern of lights and sounds that you must copy with the buttons, one step longer each round.

const int LEDS[4] = {8, 9, 10, 11};
const int BUTTONS[4] = {2, 3, 4, 5};
const int TONES[4] = {262, 330, 392, 523};
const int BUZZER = 12;
const int MAX_STEPS = 50;

int sequence[MAX_STEPS];
int length = 0;

void flash(int i, int ms) {
  digitalWrite(LEDS[i], HIGH);
  tone(BUZZER, TONES[i], ms);
  delay(ms);
  digitalWrite(LEDS[i], LOW);
  delay(100);
}

int waitForButton() {
  while (true) {
    for (int i = 0; i < 4; i++) {
      if (digitalRead(BUTTONS[i]) == LOW) {
        flash(i, 200);
        while (digitalRead(BUTTONS[i]) == LOW) delay(5);  // wait for release
        return i;
      }
    }
  }
}

void gameOver() {
  tone(BUZZER, 150, 800);
  for (int k = 0; k < 3; k++) {
    for (int i = 0; i < 4; i++) digitalWrite(LEDS[i], HIGH);
    delay(200);
    for (int i = 0; i < 4; i++) digitalWrite(LEDS[i], LOW);
    delay(200);
  }
  Serial.print("Game over! You reached level ");
  Serial.println(length);
  length = 0;
  delay(1000);
}

void setup() {
  for (int i = 0; i < 4; i++) {
    pinMode(LEDS[i], OUTPUT);
    pinMode(BUTTONS[i], INPUT_PULLUP);
  }
  Serial.begin(9600);
  randomSeed(analogRead(A0));
}

void loop() {
  if (length < MAX_STEPS) sequence[length++] = random(4);  // add one more step

  delay(600);
  for (int i = 0; i < length; i++) flash(sequence[i], 400);  // show the pattern

  for (int i = 0; i < length; i++) {  // your turn
    if (waitForButton() != sequence[i]) {
      gameOver();
      return;
    }
  }
  Serial.print("Level ");
  Serial.print(length);
  Serial.println(" done!");
}
