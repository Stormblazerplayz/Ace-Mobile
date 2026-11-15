// @title DC Motor with L298N
// @category Arduino
// @kind Arduino sketch
// @where Paste this into a new Arduino IDE sketch and upload it; wire L298N ENA to pin 9, IN1 to pin 8, IN2 to pin 7, the motor to OUT1 and OUT2, a battery pack to 12V and GND, and the L298N GND to the Arduino GND.
// @keywords arduino dc motor, arduino l298n, motor driver arduino, arduino motor speed control, spin a motor with arduino
// @about Spins a DC motor forward, then backward, speeding up and slowing down with analogWrite.

// Tip: pull the little jumper off the L298N's ENA pins so the Arduino can set the speed.
const int ENA_PIN = 9;  // speed pin (must be a ~PWM pin)
const int IN1_PIN = 8;  // direction pin 1
const int IN2_PIN = 7;  // direction pin 2

void setup() {
  pinMode(ENA_PIN, OUTPUT);
  pinMode(IN1_PIN, OUTPUT);
  pinMode(IN2_PIN, OUTPUT);
  Serial.begin(9600);
}

// Set the direction: true = forward, false = backward.
void setDirection(bool forward) {
  digitalWrite(IN1_PIN, forward ? HIGH : LOW);
  digitalWrite(IN2_PIN, forward ? LOW : HIGH);
}

// Stop the motor.
void stopMotor() {
  digitalWrite(IN1_PIN, LOW);
  digitalWrite(IN2_PIN, LOW);
  analogWrite(ENA_PIN, 0);
}

// Speed up from slow to full, then slow back down.
void rampSpeed() {
  for (int speed = 80; speed <= 255; speed += 5) {
    analogWrite(ENA_PIN, speed);
    delay(30);
  }
  for (int speed = 255; speed >= 80; speed -= 5) {
    analogWrite(ENA_PIN, speed);
    delay(30);
  }
}

void loop() {
  Serial.println("Forward");
  setDirection(true);
  rampSpeed();

  stopMotor();
  delay(1000);

  Serial.println("Backward");
  setDirection(false);
  rampSpeed();

  stopMotor();
  delay(1000);
}
