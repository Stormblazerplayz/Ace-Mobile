// @title Light Seeking Robot
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno robot car; L298N ENA 5, IN1 7, IN2 8, IN3 9, IN4 10, ENB 6; left photoresistor 5V to A0 (10k from A0 to GND), right one the same on A1; point them forward-left and forward-right.
// @keywords light seeking robot, follow a flashlight, photovore robot, two ldr robot
// @about Steers toward the brightest light, so it chases a flashlight around the room.

const int ENA = 5, IN1 = 7, IN2 = 8, ENB = 6, IN3 = 9, IN4 = 10;

void motors(int left, int right) {
  left = constrain(left, -255, 255);
  right = constrain(right, -255, 255);
  digitalWrite(IN1, left > 0);
  digitalWrite(IN2, left < 0);
  analogWrite(ENA, abs(left));
  digitalWrite(IN3, right > 0);
  digitalWrite(IN4, right < 0);
  analogWrite(ENB, abs(right));
}

void setup() {
  int pins[] = {ENA, IN1, IN2, ENB, IN3, IN4};
  for (int i = 0; i < 6; i++) pinMode(pins[i], OUTPUT);
}

void loop() {
  int leftLight = analogRead(A0);
  int rightLight = analogRead(A1);
  int brightest = max(leftLight, rightLight);

  if (brightest < 400) {
    motors(0, 0);  // too dark: wait for a light
    return;
  }

  // More light on the right = speed up the left wheel to turn right.
  int difference = rightLight - leftLight;
  int steer = difference / 3;
  motors(140 + steer, 140 - steer);
  delay(20);
}
