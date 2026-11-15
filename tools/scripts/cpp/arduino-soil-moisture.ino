// @title Plant Soil Moisture Monitor
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; soil moisture sensor AO to A0, VCC to pin 7 (so it is only powered while reading), GND; green LED pin 4, red LED pin 5 (220 ohm each).
// @keywords soil moisture sensor, plant watering monitor, does my plant need water, arduino plant sensor
// @about Checks how wet the soil is and lights green when the plant is happy or red when it needs water.

const int SENSOR_PIN = A0;
const int SENSOR_POWER = 7;
const int GREEN_LED = 4;
const int RED_LED = 5;

// Test your sensor: write down the number in dry air and in a cup of water.
const int DRY_VALUE = 850;
const int WET_VALUE = 400;

void setup() {
  pinMode(SENSOR_POWER, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  pinMode(RED_LED, OUTPUT);
  Serial.begin(9600);
}

int readMoisturePercent() {
  digitalWrite(SENSOR_POWER, HIGH);  // power on only when reading: the sensor lasts longer
  delay(10);
  int raw = analogRead(SENSOR_PIN);
  digitalWrite(SENSOR_POWER, LOW);
  int percent = map(raw, DRY_VALUE, WET_VALUE, 0, 100);
  return constrain(percent, 0, 100);
}

void loop() {
  int moisture = readMoisturePercent();
  Serial.print("Soil moisture: ");
  Serial.print(moisture);
  Serial.println("%");

  bool thirsty = moisture < 30;
  digitalWrite(RED_LED, thirsty ? HIGH : LOW);
  digitalWrite(GREEN_LED, thirsty ? LOW : HIGH);
  if (thirsty) Serial.println("Water me please!");

  delay(5000);  // soil changes slowly, so check every 5 seconds
}
