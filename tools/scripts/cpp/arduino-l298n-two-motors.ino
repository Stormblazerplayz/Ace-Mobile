// @title L298N Two Motor Test
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; L298N ENA to 5, IN1 to 7, IN2 to 8, IN3 to 9, IN4 to 10, ENB to 6 (remove the ENA/ENB jumpers); motors on OUT1/2 and OUT3/4; battery to 12V and GND, GND joined to Arduino.
// @keywords l298n two motors, robot car motor test, drive forward backward turn, dual motor driver
// @about Tests a two-motor robot base by driving forward, backward, turning left and right, then stopping.

const int ENA = 5, IN1 = 7, IN2 = 8;   // left motor
const int ENB = 6, IN3 = 9, IN4 = 10;  // right motor

// speed: -255 (full backward) to 255 (full forward)
void setMotor(int en, int inA, int inB, int speed) {
  digitalWrite(inA, speed > 0 ? HIGH : LOW);
  digitalWrite(inB, speed < 0 ? HIGH : LOW);
  analogWrite(en, abs(speed));
}

void drive(int left, int right, int ms) {
  setMotor(ENA, IN1, IN2, left);
  setMotor(ENB, IN3, IN4, right);
  delay(ms);
}

void setup() {
  int pins[] = {ENA, IN1, IN2, ENB, IN3, IN4};
  for (int i = 0; i < 6; i++) pinMode(pins[i], OUTPUT);
  Serial.begin(9600);
}

void loop() {
  Serial.println("Forward");    drive(200, 200, 1500);
  Serial.println("Stop");       drive(0, 0, 500);
  Serial.println("Backward");   drive(-200, -200, 1500);
  Serial.println("Stop");       drive(0, 0, 500);
  Serial.println("Spin left");  drive(-180, 180, 800);
  Serial.println("Spin right"); drive(180, -180, 800);
  Serial.println("Stop");       drive(0, 0, 2000);
}
