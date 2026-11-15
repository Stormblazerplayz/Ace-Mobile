// @title Feels-Like Temperature (Heat Index)
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "DHT sensor library" by Adafruit; DHT22 or DHT11 data to pin 2; open Serial Monitor at 9600.
// @keywords arduino heat index, feels like temperature, dht computeheatindex, arduino comfort level
// @about Uses temperature and humidity to work out how hot it really feels and gives a comfort message.

#include <DHT.h>

DHT dht(2, DHT22);

void setup() {
  Serial.begin(9600);
  dht.begin();
}

void loop() {
  delay(2500);
  float humidity = dht.readHumidity();
  float tempC = dht.readTemperature();
  if (isnan(humidity) || isnan(tempC)) {
    Serial.println("Sensor error");
    return;
  }

  // false = we give it Celsius and want Celsius back.
  float feelsLike = dht.computeHeatIndex(tempC, humidity, false);

  Serial.print("Real: ");
  Serial.print(tempC, 1);
  Serial.print(" C  Humidity: ");
  Serial.print(humidity, 0);
  Serial.print("%  Feels like: ");
  Serial.print(feelsLike, 1);
  Serial.print(" C  -> ");

  if (feelsLike < 18) Serial.println("Chilly, grab a hoodie.");
  else if (feelsLike < 27) Serial.println("Comfy!");
  else if (feelsLike < 32) Serial.println("Warm, drink some water.");
  else Serial.println("Very hot! Stay in the shade.");
}
