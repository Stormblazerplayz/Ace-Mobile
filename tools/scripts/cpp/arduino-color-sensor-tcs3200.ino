// @title Color Sensor TCS3200
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; TCS3200/TCS230 module S0 to 4, S1 to 5, S2 to 6, S3 to 7, OUT to 8, VCC 5V, GND; open Serial Monitor at 9600.
// @keywords color sensor, tcs3200, tcs230, detect colors arduino, rgb color sensor
// @about Measures red, green and blue light with a TCS3200 and guesses which color is in front of it.

const int S0 = 4, S1 = 5, S2 = 6, S3 = 7, OUT_PIN = 8;

// The sensor sends pulses. A SHORTER pulse means MORE of that color.
unsigned long readColor(int s2, int s3) {
  digitalWrite(S2, s2);
  digitalWrite(S3, s3);
  delay(20);
  return pulseIn(OUT_PIN, LOW, 50000UL);
}

void setup() {
  pinMode(S0, OUTPUT);
  pinMode(S1, OUTPUT);
  pinMode(S2, OUTPUT);
  pinMode(S3, OUTPUT);
  pinMode(OUT_PIN, INPUT);
  digitalWrite(S0, HIGH);  // S0 high + S1 low = 20% speed, good for Arduino
  digitalWrite(S1, LOW);
  Serial.begin(9600);
}

void loop() {
  unsigned long red = readColor(LOW, LOW);
  unsigned long blue = readColor(LOW, HIGH);
  unsigned long green = readColor(HIGH, HIGH);

  Serial.print("R: ");
  Serial.print(red);
  Serial.print("  G: ");
  Serial.print(green);
  Serial.print("  B: ");
  Serial.print(blue);
  Serial.print("  -> ");

  // The smallest number is the strongest color.
  if (red < green && red < blue) Serial.println("RED");
  else if (green < red && green < blue) Serial.println("GREEN");
  else if (blue < red && blue < green) Serial.println("BLUE");
  else Serial.println("not sure");
  delay(500);
}
