// @title Smart Robot that Looks Both Ways
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno robot car; L298N ENA 5, IN1 7, IN2 8, IN3 2, IN4 4, ENB 6; HC-SR04 Trig A2, Echo A3, sitting on a servo on pin 3. (Pins 9 and 10 lose PWM when the Servo library runs.)
// @keywords servo scan robot, look left and right robot, smart obstacle avoider, ultrasonic on servo robot
// @about When it finds a wall, the robot turns its head left and right, then drives toward whichever side is more open.

#include <Servo.h>

const int ENA = 5, IN1 = 7, IN2 = 8, ENB = 6, IN3 = 2, IN4 = 4;
const int TRIG = A2, ECHO = A3;
Servo head;

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
  return d == 0 ? 400 : d / 58;
}

long lookAt(int angle) {
  head.write(angle);
  delay(350);  // let the head stop wobbling
  return distanceCm();
}

void setup() {
  int pins[] = {ENA, IN1, IN2, ENB, IN3, IN4, TRIG};
  for (int i = 0; i < 7; i++) pinMode(pins[i], OUTPUT);
  pinMode(ECHO, INPUT);
  head.attach(3);
  head.write(90);  // look straight ahead
  delay(2000);
}

void loop() {
  if (distanceCm() > 30) {
    motors(160, 160);
    delay(50);
    return;
  }

  motors(0, 0);
  long right = lookAt(20);
  long left = lookAt(160);
  head.write(90);

  motors(-140, -140);  // back up a little first
  delay(300);
  if (left > right) motors(-160, 160);  // turn toward the bigger space
  else motors(160, -160);
  delay(450);
  motors(0, 0);
  delay(150);
}
