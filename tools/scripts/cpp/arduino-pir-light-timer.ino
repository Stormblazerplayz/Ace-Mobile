// @title Motion Light that Stays On
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; PIR OUT to pin 2; LED (220 ohm) or relay IN on pin 9.
// @keywords motion activated light, pir light timer, light stays on after motion, automatic hallway light
// @about Turns a light on when motion is seen and keeps it on until nobody has moved for 20 seconds.

const int PIR_PIN = 2;
const int LIGHT_PIN = 9;
const unsigned long STAY_ON_MS = 20000;  // 20 seconds

unsigned long lastMotionTime = 0;
bool lightOn = false;

void setup() {
  pinMode(PIR_PIN, INPUT);
  pinMode(LIGHT_PIN, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  // Every time we see motion, restart the timer.
  if (digitalRead(PIR_PIN) == HIGH) {
    lastMotionTime = millis();
    if (!lightOn) {
      lightOn = true;
      digitalWrite(LIGHT_PIN, HIGH);
      Serial.println("Light ON");
    }
  }

  // millis() - start is the safe way to measure time, even when millis wraps around.
  if (lightOn && millis() - lastMotionTime >= STAY_ON_MS) {
    lightOn = false;
    digitalWrite(LIGHT_PIN, LOW);
    Serial.println("No motion for a while, light off");
  }
}
