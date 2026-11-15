// @title MQ-2 Gas and Smoke Sensor
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; MQ-2 module AO to A0, VCC 5V, GND; buzzer pin 8; open Serial Monitor at 9600. It gets warm, and needs a few minutes to heat up.
// @keywords mq-2 gas sensor, smoke detector arduino, mq2 smoke alarm, air quality sensor
// @about Warms up the MQ-2 sensor, learns the clean air level, then warns when smoke or gas makes it rise.

const int GAS_PIN = A0;
const int BUZZER_PIN = 8;
int cleanAir = 0;

void setup() {
  Serial.begin(9600);
  Serial.println("Heating the sensor for 60 seconds...");
  delay(60000);

  // Average 20 readings to learn what clean air looks like.
  long total = 0;
  for (int i = 0; i < 20; i++) {
    total += analogRead(GAS_PIN);
    delay(100);
  }
  cleanAir = total / 20;
  Serial.print("Clean air level: ");
  Serial.println(cleanAir);
}

void loop() {
  int level = analogRead(GAS_PIN);
  Serial.print("Gas level: ");
  Serial.print(level);

  if (level > cleanAir + 150) {
    Serial.println("  WARNING: smoke or gas!");
    tone(BUZZER_PIN, 2000, 400);
  } else {
    Serial.println("  ok");
  }
  delay(1000);
}
