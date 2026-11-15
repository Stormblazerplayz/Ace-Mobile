// @title Button Interrupt Counter
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; push button between pin 2 and GND (pins 2 and 3 are the Uno's interrupt pins); open Serial Monitor at 9600.
// @keywords arduino interrupt, attachinterrupt, volatile variable, isr button, catch every press
// @about Uses an interrupt so a button press is caught instantly even while the main loop is busy with a long delay.

const int BUTTON = 2;
volatile unsigned int pressCount = 0;   // volatile: it changes inside the interrupt
volatile unsigned long lastPressTime = 0;

// An ISR (interrupt service routine) must be short and fast. No Serial or delay in here!
void onPress() {
  unsigned long now = millis();
  if (now - lastPressTime > 50) {  // ignore bounces
    pressCount++;
    lastPressTime = now;
  }
}

void setup() {
  pinMode(BUTTON, INPUT_PULLUP);
  // FALLING = when the pin goes from HIGH to LOW (the moment you press).
  attachInterrupt(digitalPinToInterrupt(BUTTON), onPress, FALLING);
  Serial.begin(9600);
}

void loop() {
  // Pretend the loop is very busy. The interrupt still counts every press!
  delay(3000);

  noInterrupts();  // pause interrupts while we copy the number safely
  unsigned int count = pressCount;
  interrupts();

  Serial.print("Presses so far: ");
  Serial.println(count);
}
