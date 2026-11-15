// @title Robot that Won't Fall Off the Table
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno robot car; L298N ENA 5, IN1 7, IN2 8, IN3 9, IN4 10, ENB 6; two IR obstacle sensors pointing DOWN at the front corners, left OUT to A0, right OUT to A1.
// @keywords edge avoiding robot, cliff sensor robot, table edge detection, robot does not fall
// @about Drives around a table and backs away whenever a downward IR sensor sees the edge.

const int ENA = 5, IN1 = 7, IN2 = 8, ENB = 6, IN3 = 9, IN4 = 10;
const int LEFT_EDGE = A0, RIGHT_EDGE = A1;

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
  delay(2000);
}

void loop() {
  // IR obstacle modules output LOW when they see the table (light bounces back),
  // and HIGH over the edge where nothing bounces back.
  bool leftEdge = digitalRead(LEFT_EDGE) == HIGH;
  bool rightEdge = digitalRead(RIGHT_EDGE) == HIGH;

  if (leftEdge || rightEdge) {
    motors(0, 0);
    delay(100);
    motors(-150, -150);  // back away from the edge
    delay(400);
    // Turn away from the side that saw the edge.
    if (leftEdge) motors(150, -150);
    else motors(-150, 150);
    delay(400);
  } else {
    motors(130, 130);  // slow and careful
  }
}
