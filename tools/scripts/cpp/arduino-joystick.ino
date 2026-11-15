// @title Read a Joystick
// @category Arduino
// @kind Arduino sketch
// @where Paste this into a new Arduino IDE sketch, upload it and open Tools > Serial Monitor at 9600 baud; wire the joystick VRx to A0, VRy to A1, SW to pin 2, +5V to 5V and GND to GND.
// @keywords arduino joystick, arduino thumbstick, read joystick arduino, arduino analog stick
// @about Reads a joystick's X and Y and its press button, then prints them and which way it is pushed.

const int X_PIN = A0;
const int Y_PIN = A1;
const int BUTTON_PIN = 2;
const int DEAD_ZONE = 150;  // how far from the middle before it counts

void setup() {
  pinMode(BUTTON_PIN, INPUT_PULLUP);  // pressed = LOW
  Serial.begin(9600);
}

void loop() {
  int x = analogRead(X_PIN);  // 0 to 1023, about 512 in the middle
  int y = analogRead(Y_PIN);
  bool pressed = digitalRead(BUTTON_PIN) == LOW;

  // Work out the direction.
  const char *direction = "center";
  if (x < 512 - DEAD_ZONE) direction = "left";
  else if (x > 512 + DEAD_ZONE) direction = "right";
  else if (y < 512 - DEAD_ZONE) direction = "up";
  else if (y > 512 + DEAD_ZONE) direction = "down";

  Serial.print("X: ");
  Serial.print(x);
  Serial.print("  Y: ");
  Serial.print(y);
  Serial.print("  Button: ");
  Serial.print(pressed ? "PRESSED" : "-");
  Serial.print("  Direction: ");
  Serial.println(direction);

  delay(100);
}
