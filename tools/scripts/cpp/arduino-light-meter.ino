// @title Light Meter Bar in Serial Monitor
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; photoresistor from 5V to A0, and a 10k resistor from A0 to GND; open Serial Monitor at 9600.
// @keywords arduino light meter, photoresistor bar graph, how bright is it arduino, ldr serial bars
// @about Reads a light sensor and draws a bar of # signs that grows when it gets brighter.

const int LIGHT_PIN = A0;

void setup() {
  Serial.begin(9600);
}

void loop() {
  int light = analogRead(LIGHT_PIN);  // 0 (dark) to 1023 (bright)
  int bars = map(light, 0, 1023, 0, 40);

  Serial.print(light);
  Serial.print("\t|");
  for (int i = 0; i < 40; i++) {
    Serial.print(i < bars ? '#' : ' ');
  }
  Serial.print("| ");

  if (light < 200) Serial.println("dark");
  else if (light < 600) Serial.println("dim");
  else Serial.println("bright");

  delay(200);
}
