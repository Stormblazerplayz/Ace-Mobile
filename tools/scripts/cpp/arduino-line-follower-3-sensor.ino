// @title Smooth Line Follower (3 Sensors, P Control)
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno robot car; L298N ENA 5, IN1 7, IN2 8, IN3 9, IN4 10, ENB 6; three IR line sensors left A0, middle A1, right A2.
// @keywords proportional control, smooth line follower, 3 sensor line follower, p controller robot, line follower error
// @about Follows a line smoothly by working out how far off-center it is and steering in proportion.

const int ENA = 5, IN1 = 7, IN2 = 8, ENB = 6, IN3 = 9, IN4 = 10;
const int SENSORS[3] = {A0, A1, A2};
const int BASE_SPEED = 140;
const int KP = 60;  // how hard to steer; tune this number!
int lastError = 0;

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
  delay(2000);
}

void loop() {
  bool l = digitalRead(SENSORS[0]) == HIGH;  // HIGH = sees black
  bool m = digitalRead(SENSORS[1]) == HIGH;
  bool r = digitalRead(SENSORS[2]) == HIGH;

  // Error: negative = line is to the left, positive = to the right.
  int error;
  if (l && !m && !r) error = -2;
  else if (l && m && !r) error = -1;
  else if (!l && m && !r) error = 0;
  else if (!l && m && r) error = 1;
  else if (!l && !m && r) error = 2;
  else if (!l && !m && !r) error = lastError > 0 ? 3 : -3;  // lost it: keep turning the way it went
  else error = 0;
  lastError = error;

  // P control: steering is proportional to the error.
  int steer = KP * error;
  motors(BASE_SPEED + steer, BASE_SPEED - steer);
}
