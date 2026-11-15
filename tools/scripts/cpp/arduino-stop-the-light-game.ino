// @title Stop the Light Arcade Game
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; 7 LEDs (220 ohm) on pins 3 to 9, the middle one (pin 6) a different color; button pin 2 to GND; buzzer pin 11.
// @keywords stop the light, cyclone arcade game, timing game leds, hit the middle led
// @about A light races along the LEDs and you must press the button exactly when it reaches the middle one.

const int FIRST_LED = 3;
const int LED_COUNT = 7;
const int TARGET = 3;  // the 4th LED (pin 6) is the jackpot
const int BUTTON = 2;
const int BUZZER = 11;
int level = 1;

void setup() {
  for (int i = 0; i < LED_COUNT; i++) pinMode(FIRST_LED + i, OUTPUT);
  pinMode(BUTTON, INPUT_PULLUP);
  Serial.begin(9600);
}

void loop() {
  int wait = max(30, 150 - level * 15);  // faster every level
  int pos = 0, dir = 1;

  while (true) {
    for (int i = 0; i < LED_COUNT; i++) digitalWrite(FIRST_LED + i, i == pos);
    // Check the button many times while this LED is lit.
    unsigned long start = millis();
    while (millis() - start < (unsigned long)wait) {
      if (digitalRead(BUTTON) == LOW) {
        if (pos == TARGET) {
          Serial.print("JACKPOT! Level ");
          Serial.println(++level);
          tone(BUZZER, 2000, 300);
        } else {
          Serial.println("Missed! Back to level 1.");
          level = 1;
          tone(BUZZER, 200, 500);
        }
        delay(800);
        while (digitalRead(BUTTON) == LOW) delay(10);
        return;
      }
    }
    pos += dir;
    if (pos == LED_COUNT - 1 || pos == 0) dir = -dir;  // bounce at the ends
  }
}
