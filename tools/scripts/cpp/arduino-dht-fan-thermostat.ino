// @title Thermostat Fan with DHT11 and a Relay
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; DHT11 data to pin 2; relay module IN to pin 7, VCC to 5V, GND to GND; the fan goes through the relay with its own power supply.
// @keywords arduino thermostat, temperature controlled fan, arduino relay fan, dht11 relay
// @about Turns a fan on through a relay when it gets too hot and off again when it cools down.

#include <DHT.h>

DHT dht(2, DHT11);
const int RELAY_PIN = 7;
const float TURN_ON_AT = 27.0;   // degrees C
const float TURN_OFF_AT = 25.0;  // a gap stops the fan clicking on and off

bool fanOn = false;

void setup() {
  Serial.begin(9600);
  dht.begin();
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);  // most relay modules: HIGH = on (some are the other way round)
}

void loop() {
  float tempC = dht.readTemperature();
  if (isnan(tempC)) {
    Serial.println("Sensor error");
    delay(2000);
    return;
  }

  // Only change when we pass a limit. This is called "hysteresis".
  if (!fanOn && tempC >= TURN_ON_AT) {
    fanOn = true;
  } else if (fanOn && tempC <= TURN_OFF_AT) {
    fanOn = false;
  }
  digitalWrite(RELAY_PIN, fanOn ? HIGH : LOW);

  Serial.print("Temp: ");
  Serial.print(tempC, 1);
  Serial.print(" C   Fan: ");
  Serial.println(fanOn ? "ON" : "off");
  delay(2000);
}
