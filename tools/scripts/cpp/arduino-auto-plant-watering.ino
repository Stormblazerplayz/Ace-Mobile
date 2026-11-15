// @title Automatic Plant Watering Pump
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; soil sensor AO to A0; relay IN to pin 7 driving a small 5V water pump on its own battery pack; open Serial Monitor at 9600.
// @keywords automatic plant watering, water pump relay, self watering plant, arduino irrigation
// @about Waters a plant with a pump for a few seconds whenever the soil gets too dry.

const int SENSOR_PIN = A0;
const int PUMP_RELAY = 7;
const int DRY_LEVEL = 700;           // higher number = drier soil (check yours)
const unsigned long PUMP_MS = 3000;  // water for 3 seconds
const unsigned long SOAK_MS = 60000; // then wait a minute for it to soak in

void setup() {
  pinMode(PUMP_RELAY, OUTPUT);
  digitalWrite(PUMP_RELAY, LOW);
  Serial.begin(9600);
}

void loop() {
  int reading = analogRead(SENSOR_PIN);
  Serial.print("Soil reading: ");
  Serial.println(reading);

  if (reading > DRY_LEVEL) {
    Serial.println("Too dry! Pumping water...");
    digitalWrite(PUMP_RELAY, HIGH);
    delay(PUMP_MS);
    digitalWrite(PUMP_RELAY, LOW);
    Serial.println("Done. Waiting for the water to soak in.");
    delay(SOAK_MS);  // stops it flooding the pot before the sensor notices
  } else {
    delay(5000);
  }
}
