// @title Motion Visitor Counter
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; PIR OUT to pin 2, VCC 5V, GND; open Serial Monitor at 9600. Set the PIR jumper to single trigger (L).
// @keywords pir counter, count people walking past, arduino visitor counter, count motion events
// @about Counts how many times the PIR sensor starts seeing motion and prints the total.

const int PIR_PIN = 2;
int lastState = LOW;
unsigned long count = 0;

void setup() {
  pinMode(PIR_PIN, INPUT);
  Serial.begin(9600);
  Serial.println("Counting visitors...");
}

void loop() {
  int state = digitalRead(PIR_PIN);

  // Count only the moment it changes from LOW to HIGH (a "rising edge").
  if (state == HIGH && lastState == LOW) {
    count++;
    Serial.print("Visitor number ");
    Serial.print(count);
    Serial.print(" at ");
    Serial.print(millis() / 1000);
    Serial.println(" seconds");
  }
  lastState = state;
  delay(20);
}
