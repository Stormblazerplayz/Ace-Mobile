// @title Secret Knock Detector
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; piezo disc + to A0 and - to GND, with a 1 megohm resistor across A0 and GND; LED on pin 13; tape the piezo to a door or box.
// @keywords knock sensor, piezo knock detector, secret knock, vibration sensor piezo
// @about Listens for knocks with a piezo disc and lights up after three knocks in a row.

const int PIEZO_PIN = A0;
const int LED_PIN = 13;
const int KNOCK_THRESHOLD = 60;     // raise this if it triggers by itself
const unsigned long WINDOW_MS = 2000;

int knocks = 0;
unsigned long firstKnock = 0;

void setup() {
  pinMode(LED_PIN, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  int level = analogRead(PIEZO_PIN);
  if (level > KNOCK_THRESHOLD) {
    if (knocks == 0) firstKnock = millis();
    knocks++;
    Serial.print("Knock ");
    Serial.print(knocks);
    Serial.print(" (strength ");
    Serial.print(level);
    Serial.println(")");
    delay(120);  // skip the wobble of the same knock
  }

  if (knocks >= 3) {
    Serial.println("Secret knock accepted!");
    digitalWrite(LED_PIN, HIGH);
    delay(2000);
    digitalWrite(LED_PIN, LOW);
    knocks = 0;
  }

  // Too slow: start over.
  if (knocks > 0 && millis() - firstKnock > WINDOW_MS) {
    knocks = 0;
    Serial.println("Too slow, try again.");
  }
}
