// @title RPM Meter with a Hall Sensor
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; A3144 hall sensor signal to pin 2 (INPUT_PULLUP), VCC 5V, GND; glue one small magnet on the spinning wheel or fan; open Serial Monitor at 9600.
// @keywords rpm meter, tachometer arduino, measure wheel speed, hall sensor rpm, count rotations
// @about Counts how many times a magnet passes the sensor each second and shows the speed in RPM.

const int SENSOR = 2;
volatile unsigned long pulses = 0;

void onMagnet() {
  pulses++;
}

void setup() {
  pinMode(SENSOR, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(SENSOR), onMagnet, FALLING);
  Serial.begin(9600);
}

void loop() {
  delay(1000);  // count for one second

  noInterrupts();
  unsigned long count = pulses;
  pulses = 0;
  interrupts();

  // One magnet = one pulse per turn. Turns per second x 60 = turns per minute.
  unsigned long rpm = count * 60;
  Serial.print("Turns this second: ");
  Serial.print(count);
  Serial.print("   RPM: ");
  Serial.println(rpm);
}
