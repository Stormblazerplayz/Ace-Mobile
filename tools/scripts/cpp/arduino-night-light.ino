// @title Night Light with a Light Sensor
// @category Arduino
// @kind Arduino sketch
// @where Paste this into a new Arduino IDE sketch and upload it; wire a photoresistor from 5V to A0, a 10k resistor from A0 to GND, and an LED (long leg) through a 220 ohm resistor to pin 9 with the short leg to GND.
// @keywords arduino night light, arduino photoresistor, arduino light sensor, arduino ldr
// @about Makes an LED glow brighter as the room gets darker, like a night light.

const int SENSOR_PIN = A0;
const int LED_PIN = 9;  // a ~PWM pin so we can dim it

// Change these after watching the Serial Monitor in your room.
const int DARK_READING = 200;    // reading when it's dark
const int BRIGHT_READING = 800;  // reading when it's bright

void setup() {
  pinMode(LED_PIN, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  int light = analogRead(SENSOR_PIN);  // 0 (dark) to 1023 (bright)

  // Dark room -> bright LED. Bright room -> LED off.
  int brightness = map(light, DARK_READING, BRIGHT_READING, 255, 0);
  brightness = constrain(brightness, 0, 255);
  analogWrite(LED_PIN, brightness);

  Serial.print("Light: ");
  Serial.print(light);
  Serial.print("  LED: ");
  Serial.println(brightness);

  delay(100);
}
