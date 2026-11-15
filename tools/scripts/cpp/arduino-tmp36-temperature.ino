// @title TMP36 Temperature Sensor
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; TMP36 flat side facing you: left leg 5V, middle leg A0, right leg GND; open Serial Monitor at 9600.
// @keywords tmp36, analog temperature sensor, starter kit temperature, tmp36 celsius
// @about Turns the TMP36 sensor's voltage into degrees Celsius and Fahrenheit.

const int SENSOR_PIN = A0;

void setup() {
  Serial.begin(9600);
}

void loop() {
  // Average 10 readings to smooth out noise.
  long total = 0;
  for (int i = 0; i < 10; i++) {
    total += analogRead(SENSOR_PIN);
    delay(5);
  }
  float reading = total / 10.0;

  float volts = reading * 5.0 / 1024.0;
  // The TMP36 gives 0.5 V at 0 C and 0.01 V more for each degree.
  float tempC = (volts - 0.5) * 100.0;
  float tempF = tempC * 9.0 / 5.0 + 32.0;

  Serial.print(volts, 3);
  Serial.print(" V  ->  ");
  Serial.print(tempC, 1);
  Serial.print(" C  /  ");
  Serial.print(tempF, 1);
  Serial.println(" F");
  delay(1000);
}
