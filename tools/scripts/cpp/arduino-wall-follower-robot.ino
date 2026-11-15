// @title Wall Following Robot
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno robot car; L298N ENA 5, IN1 7, IN2 8, IN3 9, IN4 10, ENB 6; HC-SR04 pointing to the RIGHT side, Trig A2, Echo A3; another HC-SR04 pointing forward, Trig A4, Echo A5.
// @keywords wall follower robot, follow the right wall, maze robot, keep distance from wall
// @about Drives along a wall on its right, keeping about 15 cm away, and turns left at corners.

const int ENA = 5, IN1 = 7, IN2 = 8, ENB = 6, IN3 = 9, IN4 = 10;
const int SIDE_TRIG = A2, SIDE_ECHO = A3, FRONT_TRIG = A4, FRONT_ECHO = A5;
const int WANT_CM = 15;

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

long distanceCm(int trig, int echo) {
  digitalWrite(trig, LOW);
  delayMicroseconds(2);
  digitalWrite(trig, HIGH);
  delayMicroseconds(10);
  digitalWrite(trig, LOW);
  unsigned long d = pulseIn(echo, HIGH, 20000UL);
  return d == 0 ? 300 : d / 58;
}

void setup() {
  int outs[] = {ENA, IN1, IN2, ENB, IN3, IN4, SIDE_TRIG, FRONT_TRIG};
  for (int i = 0; i < 8; i++) pinMode(outs[i], OUTPUT);
  pinMode(SIDE_ECHO, INPUT);
  pinMode(FRONT_ECHO, INPUT);
  delay(2000);
}

void loop() {
  if (distanceCm(FRONT_TRIG, FRONT_ECHO) < 20) {
    motors(-150, 150);  // wall ahead: spin left
    delay(300);
    return;
  }

  long side = distanceCm(SIDE_TRIG, SIDE_ECHO);
  if (side > 60) side = 60;  // lost the wall: turn right gently to find it
  // Too far from the wall -> steer right. Too close -> steer left.
  int error = side - WANT_CM;
  int steer = constrain(error * 6, -90, 90);
  motors(150 + steer, 150 - steer);
  delay(40);
}
