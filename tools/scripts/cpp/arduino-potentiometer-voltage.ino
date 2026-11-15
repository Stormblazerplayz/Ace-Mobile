// @title Read a Potentiometer and its Voltage
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; potentiometer outer legs to 5V and GND, middle leg to A0; open Serial Monitor at 9600 (or Tools > Serial Plotter).
// @keywords arduino potentiometer, analogread potentiometer, knob value arduino, read voltage arduino
// @about Reads a knob, then prints the raw number, the voltage and a percentage.

const int POT_PIN = A0;

void setup() {
  Serial.begin(9600);
}

void loop() {
  int raw = analogRead(POT_PIN);  // 0 to 1023
  float volts = raw * (5.0 / 1023.0);
  int percent = map(raw, 0, 1023, 0, 100);

  Serial.print("Raw: ");
  Serial.print(raw);
  Serial.print("   Volts: ");
  Serial.print(volts, 2);
  Serial.print("   Percent: ");
  Serial.print(percent);
  Serial.println("%");
  delay(200);
}
