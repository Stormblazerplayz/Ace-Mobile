// @title Whack-a-Mole with LEDs
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; 4 LEDs (220 ohm) on pins 8 to 11; 4 buttons from pins 2 to 5 to GND (in the same order); buzzer on pin 12; open Serial Monitor at 9600.
// @keywords whack a mole, hit the light game, arduino arcade game, led button game
// @about A random LED lights up and you must hit its button before it goes out; the game gets faster as you score.

const int LEDS[4] = {8, 9, 10, 11};
const int BUTTONS[4] = {2, 3, 4, 5};
const int BUZZER = 12;
int score = 0;
int misses = 0;
unsigned long moleTime = 1000;  // how long a mole stays up

void setup() {
  for (int i = 0; i < 4; i++) {
    pinMode(LEDS[i], OUTPUT);
    pinMode(BUTTONS[i], INPUT_PULLUP);
  }
  Serial.begin(9600);
  randomSeed(analogRead(A0));
  Serial.println("Whack the moles! 3 misses and you're out.");
}

int buttonPressed() {
  for (int i = 0; i < 4; i++) {
    if (digitalRead(BUTTONS[i]) == LOW) return i;
  }
  return -1;
}

void loop() {
  int mole = random(4);
  digitalWrite(LEDS[mole], HIGH);
  unsigned long start = millis();
  int hit = -1;

  while (millis() - start < moleTime && hit == -1) {
    hit = buttonPressed();
  }
  digitalWrite(LEDS[mole], LOW);

  if (hit == mole) {
    score++;
    tone(BUZZER, 1500, 80);
    if (moleTime > 300) moleTime -= 40;  // faster each hit!
  } else {
    misses++;
    tone(BUZZER, 200, 300);
  }
  Serial.print("Score: ");
  Serial.print(score);
  Serial.print("  Misses: ");
  Serial.println(misses);

  while (buttonPressed() != -1) delay(5);  // wait for all buttons to be let go
  delay(random(200, 700));

  if (misses >= 3) {
    Serial.print("GAME OVER! Final score: ");
    Serial.println(score);
    score = 0;
    misses = 0;
    moleTime = 1000;
    delay(3000);
    Serial.println("New game!");
  }
}
