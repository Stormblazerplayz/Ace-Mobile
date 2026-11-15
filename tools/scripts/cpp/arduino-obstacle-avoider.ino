// @title Obstacle Avoiding Robot
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno robot car; L298N ENA 5, IN1 7, IN2 8, IN3 9, IN4 10, ENB 6; HC-SR04 on the front, Trig A2, Echo A3.
// @keywords obstacle avoiding robot, ultrasonic robot car, avoid walls robot, autonomous robot arduino
// @about Drives forward and, when a wall gets close, backs up and turns a random way before carrying on.

const int ENA = 5, IN1 = 7, IN2 = 8, ENB = 6, IN3 = 9, IN4 = 10;
const int TRIG = A2, ECHO = A3;
const int STOP_DISTANCE = 25;  // cm

void motors(int left, int right) {
  digitalWrite(IN1, left > 0);
  digitalWrite(IN2, left < 0);
  analogWrite(ENA, abs(left));
  digitalWrite(IN3, right > 0);
  digitalWrite(IN4, right < 0);
  analogWrite(ENB, abs(right));
}

long distanceCm() {
  digitalWrite(TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG, LOW);
  unsigned long d = pulseIn(ECHO, HIGH, 30000UL);
  return d == 0 ? 400 : d / 58;  // no echo = nothing close
}

void setup() {
  int pins[] = {ENA, IN1, IN2, ENB, IN3, IN4, TRIG};
  for (int i = 0; i < 7; i++) pinMode(pins[i], OUTPUT);
  pinMode(ECHO, INPUT);
  randomSeed(analogRead(A0));
  delay(2000);
}

void loop() {
  if (distanceCm() > STOP_DISTANCE) {
    motors(170, 170);  // all clear
  } else {
    motors(0, 0);
    delay(200);
    motors(-150, -150);  // back up
    delay(400);
    if (random(2) == 0) motors(-160, 160);  // spin left
    else motors(160, -160);                 // or right
    delay(random(300, 700));
    motors(0, 0);
    delay(100);
  }
  delay(30);
}
