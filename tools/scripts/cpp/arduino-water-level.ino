// @title Water Level Sensor
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; water level sensor S to A0, + to pin 7, - to GND; buzzer on pin 8; open Serial Monitor at 9600.
// @keywords water level sensor, rain sensor, tank overflow alarm, arduino water detector, flood alarm
// @about Measures how deep the water is on the sensor and beeps when it gets too high.

const int SENSOR_PIN = A0;
const int SENSOR_POWER = 7;
const int BUZZER_PIN = 8;

void setup() {
  pinMode(SENSOR_POWER, OUTPUT);
  digitalWrite(SENSOR_POWER, LOW);
  Serial.begin(9600);
}

int readLevel() {
  digitalWrite(SENSOR_POWER, HIGH);  // only power it while reading so it rusts slower
  delay(10);
  int value = analogRead(SENSOR_PIN);
  digitalWrite(SENSOR_POWER, LOW);
  return value;
}

void loop() {
  int level = readLevel();
  Serial.print("Water level: ");
  Serial.print(level);

  if (level < 100) {
    Serial.println("  (dry)");
  } else if (level < 400) {
    Serial.println("  (low)");
  } else if (level < 550) {
    Serial.println("  (medium)");
  } else {
    Serial.println("  (HIGH! overflow warning)");
    tone(BUZZER_PIN, 2500, 300);
  }
  delay(1000);
}
