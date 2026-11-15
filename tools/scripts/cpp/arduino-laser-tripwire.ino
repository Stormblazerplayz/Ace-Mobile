// @title Laser Tripwire Alarm
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; laser module S to pin 7 (never point at eyes); photoresistor 5V to A0 with 10k from A0 to GND, aimed at the laser; buzzer on pin 8; button pin 2 to GND to reset.
// @keywords laser tripwire, laser alarm, spy laser beam, arduino beam break alarm
// @about Shines a laser at a light sensor and sounds the alarm when someone breaks the beam.

const int LASER_PIN = 7;
const int SENSOR_PIN = A0;
const int BUZZER_PIN = 8;
const int RESET_PIN = 2;

int threshold = 0;
bool alarm = false;

void setup() {
  pinMode(LASER_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(RESET_PIN, INPUT_PULLUP);
  Serial.begin(9600);

  digitalWrite(LASER_PIN, HIGH);
  delay(500);
  // Learn how bright the laser is, then trip at 70% of that.
  int laserLevel = analogRead(SENSOR_PIN);
  threshold = laserLevel * 7 / 10;
  Serial.print("Laser level ");
  Serial.print(laserLevel);
  Serial.print(", alarm below ");
  Serial.println(threshold);
}

void loop() {
  if (!alarm && analogRead(SENSOR_PIN) < threshold) {
    alarm = true;
    Serial.println("BEAM BROKEN! Press the button to reset.");
  }

  if (alarm) {
    tone(BUZZER_PIN, 1500, 150);
    delay(300);
    if (digitalRead(RESET_PIN) == LOW) {
      alarm = false;
      noTone(BUZZER_PIN);
      Serial.println("Alarm reset.");
      delay(500);
    }
  }
}
