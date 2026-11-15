// @title Mini Sumo Robot
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno robot; L298N ENA 5, IN1 7, IN2 8, IN3 9, IN4 10, ENB 6; HC-SR04 forward Trig A2, Echo A3; IR line sensor pointing down at the front, OUT to A0 (sees the white ring edge); start button pin 2 to GND.
// @keywords sumo robot, robot sumo arduino, push the enemy out, sumo bot ring
// @about Waits 5 seconds after the start button, then hunts for the enemy robot, charges it, and avoids the white ring edge.

const int ENA = 5, IN1 = 7, IN2 = 8, ENB = 6, IN3 = 9, IN4 = 10;
const int TRIG = A2, ECHO = A3, EDGE_SENSOR = A0, START_BUTTON = 2;

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
  unsigned long d = pulseIn(ECHO, HIGH, 15000UL);
  return d == 0 ? 200 : d / 58;
}

void setup() {
  int pins[] = {ENA, IN1, IN2, ENB, IN3, IN4, TRIG};
  for (int i = 0; i < 7; i++) pinMode(pins[i], OUTPUT);
  pinMode(START_BUTTON, INPUT_PULLUP);
  pinMode(LED_BUILTIN, OUTPUT);

  while (digitalRead(START_BUTTON) == HIGH) {}  // wait for the start button
  for (int i = 0; i < 5; i++) {                // the rules say wait 5 seconds
    digitalWrite(LED_BUILTIN, HIGH);
    delay(500);
    digitalWrite(LED_BUILTIN, LOW);
    delay(500);
  }
}

void loop() {
  // Most line modules read LOW over the white edge (light bounces back).
  if (digitalRead(EDGE_SENSOR) == LOW) {
    motors(-255, -255);  // edge! reverse fast
    delay(300);
    motors(200, -200);   // and turn around
    delay(350);
    return;
  }

  if (distanceCm() < 40) {
    motors(255, 255);    // enemy in front: CHARGE!
  } else {
    motors(140, -140);   // spin slowly to search
  }
}
