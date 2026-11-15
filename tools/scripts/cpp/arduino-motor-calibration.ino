// @title Robot Motor Speed Matcher
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno robot car; L298N ENA 5, IN1 7, IN2 8, IN3 9, IN4 10, ENB 6; open Serial Monitor at 9600 with "Newline"; type l or r to trim, g to go.
// @keywords motor trim, robot drives crooked, calibrate robot motors, match motor speeds
// @about Helps your robot drive straight by letting you trim the left or right motor speed from the Serial Monitor.

const int ENA = 5, IN1 = 7, IN2 = 8, ENB = 6, IN3 = 9, IN4 = 10;
int leftTrim = 0;   // added to the left motor speed
int rightTrim = 0;
const int BASE = 180;

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

void printTrims() {
  Serial.print("Left speed: ");
  Serial.print(BASE + leftTrim);
  Serial.print("   Right speed: ");
  Serial.println(BASE + rightTrim);
}

void setup() {
  int pins[] = {ENA, IN1, IN2, ENB, IN3, IN4};
  for (int i = 0; i < 6; i++) pinMode(pins[i], OUTPUT);
  Serial.begin(9600);
  Serial.println("If it veers LEFT, type r (slow the right motor). If it veers RIGHT, type l.");
  Serial.println("Type g to drive for 2 seconds. Copy the final numbers into your robot code!");
  printTrims();
}

void loop() {
  if (!Serial.available()) return;
  char c = Serial.read();
  if (c == 'l') { leftTrim -= 5; printTrims(); }
  if (c == 'r') { rightTrim -= 5; printTrims(); }
  if (c == 'g') {
    Serial.println("Driving...");
    motors(BASE + leftTrim, BASE + rightTrim);
    delay(2000);
    motors(0, 0);
  }
}
