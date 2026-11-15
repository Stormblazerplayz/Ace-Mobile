// @title Smooth Out Jumpy Sensor Readings
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; any analog sensor or potentiometer on A0; open Tools > Serial Plotter at 9600 to see both lines.
// @keywords moving average, smooth sensor readings, analog smoothing, noisy sensor fix, running average
// @about Keeps the last 10 readings and averages them, then plots the raw and smooth values together.

const int SENSOR_PIN = A0;
const int SAMPLES = 10;

int readings[SAMPLES];  // a ring of the last 10 readings
int slot = 0;
long total = 0;

void setup() {
  Serial.begin(9600);
  for (int i = 0; i < SAMPLES; i++) readings[i] = 0;
}

void loop() {
  int raw = analogRead(SENSOR_PIN);

  // Take the oldest reading out of the total and put the new one in.
  total -= readings[slot];
  readings[slot] = raw;
  total += raw;
  slot = (slot + 1) % SAMPLES;

  int average = total / SAMPLES;

  // "Label:value" lines give the Serial Plotter named lines.
  Serial.print("raw:");
  Serial.print(raw);
  Serial.print(",smooth:");
  Serial.println(average);
  delay(20);
}
