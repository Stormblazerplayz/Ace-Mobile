// @title Magnet Detector (Hall Sensor)
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; KY-003 or A3144 hall sensor signal to pin 2 (with 10k pull-up or INPUT_PULLUP), VCC 5V, GND; LED on pin 13.
// @keywords hall effect sensor, magnet detector, a3144, ky-003, detect a magnet arduino
// @about Lights an LED and prints a message when a magnet comes near the hall effect sensor.

const int HALL_PIN = 2;
const int LED_PIN = 13;
bool wasNear = false;

void setup() {
  pinMode(HALL_PIN, INPUT_PULLUP);
  pinMode(LED_PIN, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  // The A3144 pulls its pin LOW when it feels a magnet's south pole.
  bool near = digitalRead(HALL_PIN) == LOW;
  digitalWrite(LED_PIN, near ? HIGH : LOW);

  if (near && !wasNear) Serial.println("Magnet arrived!");
  if (!near && wasNear) Serial.println("Magnet gone.");
  wasNear = near;
  delay(20);
}
