// @title DC Motor Speed with a Transistor
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; small DC motor: + to battery +, - to the drain of an IRLZ44N MOSFET (or collector of a TIP120); gate/base to pin 9 through 220 ohm; source/emitter to GND; diode 1N4001 across the motor; join battery - to Arduino GND; knob on A0.
// @keywords dc motor transistor, mosfet motor control, tip120 motor, motor speed knob, fan speed pwm
// @about Controls a small DC motor's speed with a knob using a transistor and PWM.

const int MOTOR_PIN = 9;
const int KNOB_PIN = A0;

void setup() {
  pinMode(MOTOR_PIN, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  int knob = analogRead(KNOB_PIN);
  int speed = map(knob, 0, 1023, 0, 255);

  // Many motors won't start below about 60, so treat small numbers as stop.
  if (speed < 60) speed = 0;

  analogWrite(MOTOR_PIN, speed);
  Serial.print("Motor speed: ");
  Serial.print(speed * 100 / 255);
  Serial.println("%");
  delay(100);
}
