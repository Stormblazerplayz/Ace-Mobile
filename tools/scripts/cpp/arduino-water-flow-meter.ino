// @title Water Flow Meter (YF-S201)
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; YF-S201 flow sensor red to 5V, black to GND, yellow to pin 2; open Serial Monitor at 9600.
// @keywords water flow sensor, yf-s201, liters per minute, measure water used, flow meter interrupt
// @about Counts pulses from a water flow sensor to show liters per minute and the total liters used.

const int FLOW_PIN = 2;
const float PULSES_PER_LITER = 450.0;  // the YF-S201 gives about 450 pulses per liter

volatile unsigned long pulses = 0;
float totalLiters = 0;

void onPulse() {
  pulses++;
}

void setup() {
  pinMode(FLOW_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(FLOW_PIN), onPulse, RISING);
  Serial.begin(9600);
}

void loop() {
  delay(1000);

  noInterrupts();
  unsigned long count = pulses;
  pulses = 0;
  interrupts();

  float litersThisSecond = count / PULSES_PER_LITER;
  totalLiters += litersThisSecond;

  Serial.print("Flow: ");
  Serial.print(litersThisSecond * 60.0, 2);  // per minute
  Serial.print(" L/min   Total: ");
  Serial.print(totalLiters, 2);
  Serial.println(" L");
}
