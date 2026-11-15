// @title 8 LEDs from 3 Pins (74HC595 Shift Register)
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; 74HC595: DS (pin 14) to Arduino 11, SHCP (pin 11) to 12, STCP (pin 12) to 8, MR (10) to 5V, OE (13) to GND, VCC (16) 5V, GND (8); 8 LEDs on Q0 to Q7 with 220 ohm resistors.
// @keywords 74hc595, shift register, more outputs arduino, shiftout, control 8 leds with 3 pins
// @about Uses a 74HC595 chip to control 8 LEDs with just 3 Arduino pins and plays a few light patterns.

const int DATA_PIN = 11;
const int CLOCK_PIN = 12;
const int LATCH_PIN = 8;

// Send 8 on/off bits to the chip, then "latch" them so the LEDs update together.
void writeLeds(byte pattern) {
  digitalWrite(LATCH_PIN, LOW);
  shiftOut(DATA_PIN, CLOCK_PIN, MSBFIRST, pattern);
  digitalWrite(LATCH_PIN, HIGH);
}

void setup() {
  pinMode(DATA_PIN, OUTPUT);
  pinMode(CLOCK_PIN, OUTPUT);
  pinMode(LATCH_PIN, OUTPUT);
}

void loop() {
  // Pattern 1: one light walking along.
  for (int i = 0; i < 8; i++) {
    writeLeds(1 << i);
    delay(100);
  }
  // Pattern 2: fill up.
  byte bar = 0;
  for (int i = 0; i < 8; i++) {
    bar |= (1 << i);
    writeLeds(bar);
    delay(100);
  }
  // Pattern 3: flash odd and even LEDs.
  for (int i = 0; i < 6; i++) {
    writeLeds(i % 2 ? 0b10101010 : 0b01010101);
    delay(200);
  }
  writeLeds(0);
  delay(300);
}
