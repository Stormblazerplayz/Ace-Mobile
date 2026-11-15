// @title Type Commands to Control LEDs
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; red LED pin 9, green LED pin 10, blue LED pin 11 (220 ohm each); open Serial Monitor at 9600 with line ending "Newline".
// @keywords serial commands, readstringuntil, type commands arduino, serial monitor control leds, command parser
// @about Understands typed commands like "red on", "all off" and "blink green" to control three LEDs.

const int RED = 9, GREEN = 10, BLUE = 11;

int pinFor(const String &name) {
  if (name == "red") return RED;
  if (name == "green") return GREEN;
  if (name == "blue") return BLUE;
  return -1;
}

void setup() {
  pinMode(RED, OUTPUT);
  pinMode(GREEN, OUTPUT);
  pinMode(BLUE, OUTPUT);
  Serial.begin(9600);
  Serial.println("Commands: red on, red off, blink blue, all on, all off, help");
}

void loop() {
  if (!Serial.available()) return;

  String command = Serial.readStringUntil('\n');  // read one whole line
  command.trim();          // remove spaces and the Enter key
  command.toLowerCase();   // so "RED ON" works too

  int space = command.indexOf(' ');
  if (space < 0) {
    Serial.println("Try something like: red on");
    return;
  }
  String first = command.substring(0, space);
  String second = command.substring(space + 1);

  if (first == "all") {
    int level = (second == "on") ? HIGH : LOW;
    digitalWrite(RED, level);
    digitalWrite(GREEN, level);
    digitalWrite(BLUE, level);
    Serial.println("OK");
  } else if (first == "blink" && pinFor(second) >= 0) {
    int pin = pinFor(second);
    for (int i = 0; i < 5; i++) {
      digitalWrite(pin, HIGH);
      delay(150);
      digitalWrite(pin, LOW);
      delay(150);
    }
    Serial.println("Blinked!");
  } else if (pinFor(first) >= 0 && (second == "on" || second == "off")) {
    digitalWrite(pinFor(first), second == "on" ? HIGH : LOW);
    Serial.println("OK");
  } else {
    Serial.println("I don't know that command.");
  }
}
