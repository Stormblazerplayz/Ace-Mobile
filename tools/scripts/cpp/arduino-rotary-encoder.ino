// @title Rotary Encoder Counter
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; KY-040 rotary encoder CLK to pin 2, DT to pin 3, SW to pin 4, + to 5V, GND to GND; open Serial Monitor at 9600.
// @keywords rotary encoder, ky-040, arduino encoder knob, infinite knob counter, encoder interrupt
// @about Counts up and down as you turn a rotary encoder, and resets to zero when you push it.

const int CLK_PIN = 2;  // interrupt pin
const int DT_PIN = 3;
const int SW_PIN = 4;

volatile long position = 0;  // volatile: changed inside an interrupt
long lastPrinted = -1;

// Runs by itself every time CLK falls.
void onTurn() {
  // If DT is different from CLK, we turned clockwise.
  if (digitalRead(DT_PIN) != digitalRead(CLK_PIN)) {
    position++;
  } else {
    position--;
  }
}

void setup() {
  pinMode(CLK_PIN, INPUT_PULLUP);
  pinMode(DT_PIN, INPUT_PULLUP);
  pinMode(SW_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(CLK_PIN), onTurn, FALLING);
  Serial.begin(9600);
}

void loop() {
  // Copy the number with interrupts paused so it does not change halfway.
  noInterrupts();
  long now = position;
  interrupts();

  if (now != lastPrinted) {
    Serial.print("Position: ");
    Serial.println(now);
    lastPrinted = now;
  }

  if (digitalRead(SW_PIN) == LOW) {
    noInterrupts();
    position = 0;
    interrupts();
    delay(250);
  }
}
