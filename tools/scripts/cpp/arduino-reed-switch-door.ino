// @title Door Open Alarm with a Reed Switch
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; magnetic reed switch (door sensor) between pin 2 and GND, magnet on the door; buzzer on pin 8; open Serial Monitor at 9600.
// @keywords reed switch, door sensor arduino, magnetic door alarm, door left open alarm, bedroom door alarm
// @about Tells you when a door opens and beeps if it is left open for more than 10 seconds.

const int REED_PIN = 2;
const int BUZZER_PIN = 8;
const unsigned long OPEN_TOO_LONG = 10000;

bool wasOpen = false;
unsigned long openedAt = 0;

void setup() {
  pinMode(REED_PIN, INPUT_PULLUP);  // magnet near = switch closed = LOW
  pinMode(BUZZER_PIN, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  bool open = digitalRead(REED_PIN) == HIGH;

  if (open && !wasOpen) {
    openedAt = millis();
    Serial.println("Door opened!");
    tone(BUZZER_PIN, 1800, 100);  // a quick chime
  }
  if (!open && wasOpen) {
    Serial.println("Door closed.");
    noTone(BUZZER_PIN);
  }

  if (open && millis() - openedAt > OPEN_TOO_LONG) {
    tone(BUZZER_PIN, 900, 200);  // nag beep
    delay(400);
  }

  wasOpen = open;
  delay(30);
}
