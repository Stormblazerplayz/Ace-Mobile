// @title NTC Thermistor Thermometer
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; 10k NTC thermistor from 5V to A0, and a 10k resistor from A0 to GND (or use a KY-013 module); open Serial Monitor at 9600.
// @keywords ntc thermistor, steinhart hart, ky-013, thermistor temperature arduino, beta equation
// @about Works out the temperature from a thermistor using the beta equation.

const int THERM_PIN = A0;
const float SERIES_RESISTOR = 10000.0;  // the fixed 10k resistor
const float NOMINAL_RESISTANCE = 10000.0;  // thermistor is 10k at 25 C
const float NOMINAL_TEMP = 25.0;
const float BETA = 3950.0;  // from the thermistor's data sheet

void setup() {
  Serial.begin(9600);
}

void loop() {
  int reading = analogRead(THERM_PIN);
  if (reading <= 0 || reading >= 1023) {
    Serial.println("Check the wiring!");
    delay(1000);
    return;
  }

  // Thermistor on top, resistor on the bottom: work out the thermistor's resistance.
  float resistance = SERIES_RESISTOR * (1023.0 / reading - 1.0);

  // Beta equation: 1/T = 1/T0 + (1/B) * ln(R/R0), with T in Kelvin.
  float kelvin = 1.0 / (1.0 / (NOMINAL_TEMP + 273.15) + log(resistance / NOMINAL_RESISTANCE) / BETA);
  float tempC = kelvin - 273.15;

  Serial.print("Resistance: ");
  Serial.print(resistance, 0);
  Serial.print(" ohms   Temperature: ");
  Serial.print(tempC, 1);
  Serial.println(" C");
  delay(1000);
}
