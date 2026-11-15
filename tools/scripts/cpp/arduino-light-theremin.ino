// @title Light Theremin
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; photoresistor from 5V to A0 with a 10k resistor from A0 to GND; passive buzzer on pin 8. Wave your hand over the sensor.
// @keywords light theremin, photoresistor music, wave hand make sound, ldr buzzer pitch
// @about Plays higher or lower notes as you move your hand over a light sensor, after learning the room's light.

const int SENSOR_PIN = A0;
const int BUZZER_PIN = 8;
int darkest = 1023;
int brightest = 0;

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  // For 5 seconds, wave your hand over the sensor so it learns the range.
  digitalWrite(LED_BUILTIN, HIGH);
  unsigned long start = millis();
  while (millis() - start < 5000) {
    int v = analogRead(SENSOR_PIN);
    if (v < darkest) darkest = v;
    if (v > brightest) brightest = v;
  }
  digitalWrite(LED_BUILTIN, LOW);
  if (brightest <= darkest) brightest = darkest + 1;  // never divide the range by zero
}

void loop() {
  int light = analogRead(SENSOR_PIN);
  int pitch = map(light, darkest, brightest, 120, 1500);
  pitch = constrain(pitch, 120, 1500);
  tone(BUZZER_PIN, pitch, 20);
  delay(10);
}
