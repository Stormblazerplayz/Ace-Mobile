// @title Pomodoro Study Timer
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; red LED (220 ohm) on pin 9 for focus time, green LED on pin 10 for break time; buzzer pin 8; button pin 2 to GND to start; Serial Monitor 9600 shows minutes left.
// @keywords pomodoro timer, study timer, homework focus timer, 25 minute timer, work and break timer
// @about Times 25 minutes of focus (red light) then a 5 minute break (green light), and repeats, beeping at each change.

const int FOCUS_LED = 9, BREAK_LED = 10, BUZZER = 8, BUTTON = 2;
const unsigned long FOCUS_MS = 25UL * 60UL * 1000UL;  // UL = unsigned long, so the number fits
const unsigned long BREAK_MS = 5UL * 60UL * 1000UL;

void chime(int times) {
  for (int i = 0; i < times; i++) {
    tone(BUZZER, 1200, 150);
    delay(300);
  }
}

// Runs one block of time with a slowly pulsing LED.
void runBlock(int ledPin, unsigned long length, const char *name) {
  Serial.print(name);
  Serial.println(" started!");
  unsigned long start = millis();
  unsigned long lastReport = 0;
  while (millis() - start < length) {
    unsigned long passed = millis() - start;
    // Gentle pulse so you can tell it is running.
    analogWrite(ledPin, 40 + (passed / 8) % 200);
    if (passed - lastReport >= 60000UL) {
      lastReport = passed;
      Serial.print((length - passed) / 60000UL);
      Serial.println(" minutes left");
    }
  }
  analogWrite(ledPin, 0);
}

void setup() {
  pinMode(FOCUS_LED, OUTPUT);
  pinMode(BREAK_LED, OUTPUT);
  pinMode(BUZZER, OUTPUT);
  pinMode(BUTTON, INPUT_PULLUP);
  Serial.begin(9600);
  Serial.println("Press the button to start studying!");
}

void loop() {
  if (digitalRead(BUTTON) == HIGH) return;
  chime(1);
  runBlock(FOCUS_LED, FOCUS_MS, "Focus time");
  chime(3);
  runBlock(BREAK_LED, BREAK_MS, "Break time");
  chime(2);
  Serial.println("Press the button for another round.");
}
