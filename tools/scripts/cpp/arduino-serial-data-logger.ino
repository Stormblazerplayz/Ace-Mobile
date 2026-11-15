// @title Sensor Data Logger (CSV)
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; light sensor on A0 (photoresistor + 10k), temperature TMP36 on A1; open Serial Monitor at 9600, then copy the lines into a spreadsheet.
// @keywords data logger, csv logging arduino, log sensor to spreadsheet, science fair data
// @about Prints the time, light level and temperature every 5 seconds as CSV lines that paste straight into a spreadsheet.

const unsigned long EVERY_MS = 5000;
unsigned long lastLog = 0;

void setup() {
  Serial.begin(9600);
  // The header row names each column.
  Serial.println("seconds,light,temperature_c");
}

void loop() {
  if (millis() - lastLog < EVERY_MS) return;
  lastLog = millis();

  int light = analogRead(A0);
  float volts = analogRead(A1) * 5.0 / 1024.0;
  float tempC = (volts - 0.5) * 100.0;  // TMP36 formula

  Serial.print(millis() / 1000);
  Serial.print(',');
  Serial.print(light);
  Serial.print(',');
  Serial.println(tempC, 1);
}
