// @title Line Follower Robot (2 Sensors)
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno robot car; L298N ENA 5, IN1 7, IN2 8, IN3 9, IN4 10, ENB 6; left IR line sensor OUT to A0, right to A1 (both on the front, either side of the black line).
// @keywords line follower robot, line following car, ir line sensor, tcrt5000 robot, follow black tape
// @about Follows a black tape line on the floor using two IR sensors and two motors.

const int ENA = 5, IN1 = 7, IN2 = 8, ENB = 6, IN3 = 9, IN4 = 10;
const int LEFT_SENSOR = A0, RIGHT_SENSOR = A1;
const int SPEED = 150;  // go slow at first; faster robots fly off the line

void motors(int left, int right) {
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
  pinMode(LEFT_SENSOR, INPUT);
  pinMode(RIGHT_SENSOR, INPUT);
  delay(2000);  // time to put it on the track
}

void loop() {
  // Most IR line modules give HIGH over black and LOW over white.
  bool leftOnBlack = digitalRead(LEFT_SENSOR) == HIGH;
  bool rightOnBlack = digitalRead(RIGHT_SENSOR) == HIGH;

  if (!leftOnBlack && !rightOnBlack) {
    motors(SPEED, SPEED);   // line is between the sensors: go straight
  } else if (leftOnBlack && !rightOnBlack) {
    motors(-80, SPEED);     // line drifted left: turn left
  } else if (!leftOnBlack && rightOnBlack) {
    motors(SPEED, -80);     // line drifted right: turn right
  } else {
    motors(0, 0);           // both on black: a crossing or the finish line, stop
  }
}
