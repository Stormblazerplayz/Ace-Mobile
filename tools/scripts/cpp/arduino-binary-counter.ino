// @title Binary Counter with 8 LEDs
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; 8 LEDs with 220 ohm resistors on pins 2 to 9 (pin 2 is the smallest bit); open Serial Monitor at 9600.
// @keywords binary counter leds, count in binary, bitread arduino, learn binary with leds
// @about Counts from 0 to 255 and shows each number in binary on 8 LEDs.

const int FIRST_PIN = 2;

void setup() {
  for (int i = 0; i < 8; i++) pinMode(FIRST_PIN + i, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  for (int number = 0; number <= 255; number++) {
    // Bit 0 is worth 1, bit 1 is worth 2, bit 2 is worth 4... up to 128.
    for (int b = 0; b < 8; b++) {
      digitalWrite(FIRST_PIN + b, bitRead(number, b) ? HIGH : LOW);
    }
    Serial.print(number);
    Serial.print(" = ");
    Serial.println(number, BIN);
    delay(400);
  }
}
