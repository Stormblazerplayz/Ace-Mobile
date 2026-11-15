// @title DHT22 Weather Display on an LCD
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "DHT sensor library" and "LiquidCrystal I2C"; DHT22 data to pin 2, LCD I2C SDA to A4, SCL to A5, VCC to 5V, GND to GND.
// @keywords arduino dht22, dht22 lcd display, arduino weather station lcd, temperature on lcd 16x2
// @about Shows the temperature and humidity from a DHT22 on a 16x2 I2C LCD screen.

#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <DHT.h>

DHT dht(2, DHT22);
// 0x27 is the usual address. Some screens use 0x3F instead.
LiquidCrystal_I2C lcd(0x27, 16, 2);

// A little degree symbol drawn with 5x8 dots.
byte degreeSymbol[8] = {0b00110, 0b01001, 0b01001, 0b00110, 0, 0, 0, 0};

void setup() {
  dht.begin();
  lcd.init();
  lcd.backlight();
  lcd.createChar(0, degreeSymbol);
  lcd.setCursor(0, 0);
  lcd.print("Weather station");
  delay(1500);
}

void loop() {
  float humidity = dht.readHumidity();
  float tempC = dht.readTemperature();

  lcd.clear();
  if (isnan(humidity) || isnan(tempC)) {
    lcd.print("Sensor error!");
  } else {
    lcd.setCursor(0, 0);
    lcd.print("Temp: ");
    lcd.print(tempC, 1);
    lcd.write(byte(0));  // our custom degree symbol
    lcd.print("C");

    lcd.setCursor(0, 1);
    lcd.print("Humidity: ");
    lcd.print(humidity, 0);
    lcd.print("%");
  }
  delay(2000);  // the DHT22 likes 2 seconds between reads
}
