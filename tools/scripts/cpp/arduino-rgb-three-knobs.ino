// @title RGB LED with Three Knobs
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; three potentiometers with middle legs on A0 (red), A1 (green), A2 (blue); RGB LED red to 9, green to 10, blue to 11 with 220 ohm resistors; Serial Monitor 9600.
// @keywords rgb potentiometer, mix your own color, three knob rgb, rgb color picker
// @about Lets you mix any color on an RGB LED with three knobs and prints the color code.

const int RED_PIN = 9, GREEN_PIN = 10, BLUE_PIN = 11;

void setup() {
  pinMode(RED_PIN, OUTPUT);
  pinMode(GREEN_PIN, OUTPUT);
  pinMode(BLUE_PIN, OUTPUT);
  Serial.begin(9600);
}

void printHex(int value) {
  if (value < 16) Serial.print('0');  // always two digits
  Serial.print(value, HEX);
}

void loop() {
  int r = analogRead(A0) / 4;  // 0..1023 -> 0..255
  int g = analogRead(A1) / 4;
  int b = analogRead(A2) / 4;

  analogWrite(RED_PIN, r);
  analogWrite(GREEN_PIN, g);
  analogWrite(BLUE_PIN, b);

  // Prints a web color code like #FF8000 that you can use in art apps.
  Serial.print("Color: #");
  printHex(r);
  printHex(g);
  printHex(b);
  Serial.println();
  delay(200);
}
