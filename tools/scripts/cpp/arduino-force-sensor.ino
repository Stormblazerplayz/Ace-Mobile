// @title Force Sensor Squeeze Meter
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; FSR (force sensitive resistor) from 5V to A0, with a 10k resistor from A0 to GND; LED on pin 9; open Serial Monitor at 9600.
// @keywords force sensitive resistor, fsr sensor, pressure sensor arduino, squeeze meter
// @about Measures how hard you press the force sensor and makes an LED glow brighter the harder you squeeze.

const int FSR_PIN = A0;
const int LED_PIN = 9;

void setup() {
  pinMode(LED_PIN, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  int pressure = analogRead(FSR_PIN);
  analogWrite(LED_PIN, map(pressure, 0, 1023, 0, 255));

  Serial.print("Pressure: ");
  Serial.print(pressure);
  if (pressure < 10) Serial.println("  no touch");
  else if (pressure < 200) Serial.println("  light touch");
  else if (pressure < 500) Serial.println("  light squeeze");
  else if (pressure < 800) Serial.println("  medium squeeze");
  else Serial.println("  BIG squeeze!");
  delay(200);
}
