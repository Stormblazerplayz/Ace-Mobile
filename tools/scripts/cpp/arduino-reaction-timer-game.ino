// @title Reaction Time Tester
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; LED with 220 ohm resistor on pin 9; push button between pin 2 and GND; open Serial Monitor at 9600.
// @keywords reaction time game, how fast are you, reflex tester, press when light turns on
// @about Waits a random time, turns on an LED, and measures how many milliseconds you take to press the button.

const int LED_PIN = 9;
const int BUTTON_PIN = 2;
unsigned long best = 0;

void setup() {
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  Serial.begin(9600);
  randomSeed(analogRead(A0));
  Serial.println("Press the button as soon as the light comes on!");
}

void loop() {
  Serial.println("Get ready...");
  delay(1000);

  // Wait 1 to 4 seconds. Pressing early is cheating!
  unsigned long waitTime = random(1000, 4000);
  unsigned long waitStart = millis();
  while (millis() - waitStart < waitTime) {
    if (digitalRead(BUTTON_PIN) == LOW) {
      Serial.println("Too early! Wait for the light.");
      while (digitalRead(BUTTON_PIN) == LOW) delay(10);
      return;  // start the round again
    }
  }

  digitalWrite(LED_PIN, HIGH);
  unsigned long start = millis();
  while (digitalRead(BUTTON_PIN) == HIGH) {}  // wait for the press
  unsigned long reaction = millis() - start;
  digitalWrite(LED_PIN, LOW);

  Serial.print("Your time: ");
  Serial.print(reaction);
  Serial.println(" ms");
  if (best == 0 || reaction < best) {
    best = reaction;
    Serial.println("NEW BEST!");
  }
  Serial.print("Best so far: ");
  Serial.print(best);
  Serial.println(" ms\n");

  while (digitalRead(BUTTON_PIN) == LOW) delay(10);
  delay(1500);
}
