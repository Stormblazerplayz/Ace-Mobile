// @title Sound Level Meter with LEDs
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; sound sensor AO to A0, VCC 5V, GND; 5 LEDs with 220 ohm resistors on pins 3 to 7 (green, green, yellow, yellow, red).
// @keywords sound level meter, vu meter leds, noise meter arduino, microphone led bar
// @about Listens with a microphone module and lights more LEDs the louder it is.

const int MIC_PIN = A0;
const int LED_PINS[] = {3, 4, 5, 6, 7};
const int LED_COUNT = 5;

void setup() {
  for (int i = 0; i < LED_COUNT; i++) pinMode(LED_PINS[i], OUTPUT);
  Serial.begin(9600);
}

void loop() {
  // Sound is a wave, so we measure how far it swings in 50 ms.
  int highest = 0;
  int lowest = 1023;
  unsigned long start = millis();
  while (millis() - start < 50) {
    int sample = analogRead(MIC_PIN);
    if (sample > highest) highest = sample;
    if (sample < lowest) lowest = sample;
  }
  int loudness = highest - lowest;  // bigger swing = louder

  // Change 200 if your sensor is more or less sensitive.
  int lit = map(constrain(loudness, 0, 200), 0, 200, 0, LED_COUNT);
  for (int i = 0; i < LED_COUNT; i++) {
    digitalWrite(LED_PINS[i], i < lit ? HIGH : LOW);
  }
  Serial.println(loudness);
}
