// @title Double Clap Light Switch
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; sound sensor module (KY-038 or similar) DO to pin 2, VCC 5V, GND; LED (220 ohm) or relay IN on pin 9. Turn the sensor's screw until its light only blinks on loud sounds.
// @keywords clap switch, double clap light, sound sensor relay, ky-038 clap, clap on clap off
// @about Turns a light on or off when you clap twice quickly.

const int SOUND_PIN = 2;
const int LIGHT_PIN = 9;

unsigned long firstClapTime = 0;
int claps = 0;
bool lightOn = false;

void setup() {
  pinMode(SOUND_PIN, INPUT);
  pinMode(LIGHT_PIN, OUTPUT);
}

void loop() {
  if (digitalRead(SOUND_PIN) == HIGH) {
    unsigned long now = millis();
    if (claps == 0) {
      claps = 1;
      firstClapTime = now;
    } else if (now - firstClapTime > 150) {  // ignore the echo of the same clap
      claps = 2;
    }
    delay(80);  // wait for the clap sound to finish
  }

  // Two claps inside 800 ms: flip the light.
  if (claps == 2) {
    lightOn = !lightOn;
    digitalWrite(LIGHT_PIN, lightOn ? HIGH : LOW);
    claps = 0;
    delay(300);
  }

  // Too slow? Forget the first clap.
  if (claps == 1 && millis() - firstClapTime > 800) {
    claps = 0;
  }
}
