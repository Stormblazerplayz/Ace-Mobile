// @title DS18B20 Waterproof Temperature Probe
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "OneWire" and "DallasTemperature"; DS18B20 yellow (data) to pin 4, red to 5V, black to GND, and a 4.7k resistor between data and 5V.
// @keywords ds18b20, waterproof temperature probe, dallastemperature, onewire sensor, measure water temperature
// @about Reads the temperature from a waterproof DS18B20 probe, great for fish tanks and drinks.

#include <OneWire.h>
#include <DallasTemperature.h>

OneWire oneWire(4);               // the data wire is on pin 4
DallasTemperature sensors(&oneWire);

void setup() {
  Serial.begin(9600);
  sensors.begin();
  Serial.print("Probes found: ");
  Serial.println(sensors.getDeviceCount());
}

void loop() {
  sensors.requestTemperatures();          // ask every probe to measure
  float tempC = sensors.getTempCByIndex(0);  // 0 = the first probe

  if (tempC == DEVICE_DISCONNECTED_C) {
    Serial.println("Probe not connected!");
  } else {
    Serial.print("Temperature: ");
    Serial.print(tempC, 2);
    Serial.print(" C  (");
    Serial.print(tempC * 9.0 / 5.0 + 32.0, 1);
    Serial.println(" F)");
  }
  delay(1000);
}
