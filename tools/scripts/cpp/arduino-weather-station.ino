// @title Mini Weather Station
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "DHT sensor library" and "LiquidCrystal I2C"; DHT11 data pin 2; photoresistor 5V to A0 with 10k to GND; LCD SDA A4, SCL A5; button pin 3 to GND switches pages.
// @keywords weather station arduino, dht11 lcd light sensor, min max temperature, weather pages lcd
// @about Shows temperature, humidity, light level and today's lowest and highest temperature on LCD pages you flip with a button.

#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <DHT.h>

DHT dht(2, DHT11);
LiquidCrystal_I2C lcd(0x27, 16, 2);
const int PAGE_BUTTON = 3;

float tempC = 0, humidity = 0;
float lowest = 999, highest = -999;
int page = 0;
unsigned long lastRead = 0;
bool lastButton = HIGH;

void readSensors() {
  float t = dht.readTemperature();
  float h = dht.readHumidity();
  if (isnan(t) || isnan(h)) return;  // keep the old values on a bad read
  tempC = t;
  humidity = h;
  if (t < lowest) lowest = t;
  if (t > highest) highest = t;
}

void drawPage() {
  lcd.clear();
  if (page == 0) {
    lcd.print("Temp: ");
    lcd.print(tempC, 1);
    lcd.print(" C");
    lcd.setCursor(0, 1);
    lcd.print("Humid: ");
    lcd.print(humidity, 0);
    lcd.print(" %");
  } else if (page == 1) {
    int light = analogRead(A0);
    lcd.print("Light: ");
    lcd.print(light);
    lcd.setCursor(0, 1);
    lcd.print(light < 200 ? "Night" : (light < 700 ? "Cloudy" : "Sunny"));
  } else {
    lcd.print("Low:  ");
    lcd.print(lowest, 1);
    lcd.print(" C");
    lcd.setCursor(0, 1);
    lcd.print("High: ");
    lcd.print(highest, 1);
    lcd.print(" C");
  }
}

void setup() {
  pinMode(PAGE_BUTTON, INPUT_PULLUP);
  dht.begin();
  lcd.init();
  lcd.backlight();
  delay(1000);
  readSensors();
  drawPage();
}

void loop() {
  bool button = digitalRead(PAGE_BUTTON);
  if (button == LOW && lastButton == HIGH) {
    page = (page + 1) % 3;
    drawPage();
    delay(40);
  }
  lastButton = button;

  if (millis() - lastRead >= 3000) {  // fresh readings every 3 seconds
    lastRead = millis();
    readSensors();
    drawPage();
  }
}
