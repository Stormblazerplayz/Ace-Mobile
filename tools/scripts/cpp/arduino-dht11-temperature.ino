// @title DHT11 Temperature and Humidity
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "DHT sensor library" by Adafruit; DHT11 data pin to pin 2 (with a 10k resistor to 5V if it is a bare sensor), + to 5V, - to GND; open Serial Monitor at 9600.
// @keywords arduino dht11, dht11 temperature sensor, arduino humidity sensor, read temperature arduino
// @about Reads the temperature and humidity from a DHT11 every two seconds and prints them.

#include <DHT.h>

const int DHT_PIN = 2;
DHT dht(DHT_PIN, DHT11);  // change DHT11 to DHT22 if you have the white one

void setup() {
  Serial.begin(9600);
  dht.begin();
  Serial.println("DHT11 ready!");
}

void loop() {
  // The DHT11 is slow: only read it every 2 seconds.
  delay(2000);

  float humidity = dht.readHumidity();
  float tempC = dht.readTemperature();      // Celsius
  float tempF = dht.readTemperature(true);  // true means Fahrenheit

  // isnan means "is not a number". It happens if a wire is loose.
  if (isnan(humidity) || isnan(tempC) || isnan(tempF)) {
    Serial.println("Could not read the sensor. Check the wires!");
    return;
  }

  Serial.print("Temperature: ");
  Serial.print(tempC, 1);
  Serial.print(" C / ");
  Serial.print(tempF, 1);
  Serial.print(" F   Humidity: ");
  Serial.print(humidity, 0);
  Serial.println(" %");
}
