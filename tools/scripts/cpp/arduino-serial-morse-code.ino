// @title Morse Code Translator
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; LED on pin 13 (built in) and passive buzzer on pin 8; open Serial Monitor at 9600, type a message and press Enter.
// @keywords morse code translator, text to morse arduino, morse buzzer led, send messages in morse
// @about Turns any message you type into Morse code beeps and flashes, and prints the dots and dashes.

const int LED = 13, BUZZER = 8;
const int UNIT = 120;  // ms for one dot

// Morse for A to Z, then 0 to 9.
const char *LETTERS[26] = {".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", ".---",
                           "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", "...", "-",
                           "..-", "...-", ".--", "-..-", "-.--", "--.."};
const char *DIGITS[10] = {"-----", ".----", "..---", "...--", "....-",
                          ".....", "-....", "--...", "---..", "----."};

void signal(int units) {
  digitalWrite(LED, HIGH);
  tone(BUZZER, 700);
  delay(UNIT * units);
  digitalWrite(LED, LOW);
  noTone(BUZZER);
  delay(UNIT);  // gap inside a letter
}

void sendChar(char c) {
  c = toupper(c);
  const char *code = nullptr;
  if (c >= 'A' && c <= 'Z') code = LETTERS[c - 'A'];
  else if (c >= '0' && c <= '9') code = DIGITS[c - '0'];
  else if (c == ' ') { Serial.print(" / "); delay(UNIT * 4); return; }  // word gap
  if (code == nullptr) return;  // skip symbols we don't know

  Serial.print(code);
  Serial.print(' ');
  for (int i = 0; code[i] != '\0'; i++) {
    signal(code[i] == '.' ? 1 : 3);  // a dash is 3 dots long
  }
  delay(UNIT * 2);  // gap between letters
}

void setup() {
  pinMode(LED, OUTPUT);
  pinMode(BUZZER, OUTPUT);
  Serial.begin(9600);
  Serial.println("Type a message:");
}

void loop() {
  if (Serial.available()) {
    char c = Serial.read();
    if (c == '\n' || c == '\r') Serial.println();
    else sendChar(c);
  }
}
