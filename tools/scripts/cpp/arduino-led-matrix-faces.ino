// @title 8x8 LED Matrix Faces (MAX7219)
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "LedControl" by Eberhard Fahle; MAX7219 module DIN to 12, CLK to 11, CS to 10, VCC 5V, GND.
// @keywords max7219, 8x8 led matrix, ledcontrol, matrix smiley face, led matrix heart
// @about Shows a smiley, a heart and a surprised face on an 8x8 LED matrix.

#include <LedControl.h>

LedControl matrix(12, 11, 10, 1);  // DIN, CLK, CS, number of matrices

// Each row is one byte: 1 = LED on. Draw them in binary so you can "see" the picture.
const byte SMILE[8]    = {0b00111100, 0b01000010, 0b10100101, 0b10000001,
                          0b10100101, 0b10011001, 0b01000010, 0b00111100};
const byte HEART[8]    = {0b00000000, 0b01100110, 0b11111111, 0b11111111,
                          0b11111111, 0b01111110, 0b00111100, 0b00011000};
const byte SURPRISE[8] = {0b00111100, 0b01000010, 0b10100101, 0b10000001,
                          0b10011001, 0b10011001, 0b01000010, 0b00111100};

void showPicture(const byte picture[8]) {
  for (int row = 0; row < 8; row++) {
    matrix.setRow(0, row, picture[row]);
  }
}

void setup() {
  matrix.shutdown(0, false);  // wake it up (it starts asleep)
  matrix.setIntensity(0, 4);  // brightness 0 to 15
  matrix.clearDisplay(0);
}

void loop() {
  showPicture(SMILE);
  delay(1500);
  // Make the heart beat.
  for (int i = 0; i < 3; i++) {
    showPicture(HEART);
    matrix.setIntensity(0, 12);
    delay(250);
    matrix.setIntensity(0, 3);
    delay(250);
  }
  matrix.setIntensity(0, 4);
  showPicture(SURPRISE);
  delay(1500);
}
