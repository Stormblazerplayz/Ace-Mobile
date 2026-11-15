// @title Ultrasonic Radar Sweep
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; servo signal to pin 11 (red 5V, brown GND); HC-SR04 glued on the servo horn, Trig to 9, Echo to 10; open Serial Monitor at 9600.
// @keywords arduino radar, servo ultrasonic radar, sweep and scan distance, arduino sonar
// @about Sweeps an ultrasonic sensor back and forth on a servo and prints the angle and distance like a radar.

#include <Servo.h>

Servo radarServo;
const int TRIG_PIN = 9;
const int ECHO_PIN = 10;

int readDistanceCm() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  unsigned long duration = pulseIn(ECHO_PIN, HIGH, 25000UL);
  if (duration == 0) return 0;  // 0 means "nothing seen"
  return duration / 58;
}

void scanAt(int angle) {
  radarServo.write(angle);
  delay(30);  // let the servo get there
  int cm = readDistanceCm();
  Serial.print("Angle ");
  Serial.print(angle);
  Serial.print(" : ");
  if (cm == 0) {
    Serial.println("clear");
  } else {
    Serial.print(cm);
    Serial.print(" cm");
    if (cm < 30) Serial.print("  <-- OBJECT CLOSE!");
    Serial.println();
  }
}

void setup() {
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  radarServo.attach(11);
  Serial.begin(9600);
}

void loop() {
  for (int angle = 15; angle <= 165; angle += 3) scanAt(angle);  // sweep right
  for (int angle = 165; angle >= 15; angle -= 3) scanAt(angle);  // and back
}
