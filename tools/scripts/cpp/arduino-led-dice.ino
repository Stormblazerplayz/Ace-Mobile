// @title LED Dice with Seven LEDs
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; 7 LEDs (220 ohm) arranged like dice dots: top-left 2, top-right 3, middle-left 4, center 5, middle-right 6, bottom-left 7, bottom-right 8; button pin 10 to GND.
// @keywords led dice, dice dots leds, roll dice button, arduino dice pattern
// @about Shows a dice roll as real dice dots using seven LEDs when you press the button.

// Dot positions:  TL=0  TR=1
//                 ML=2  C=3  MR=4
//                 BL=5  BR=6
const int DOTS[7] = {2, 3, 4, 5, 6, 7, 8};
const int BUTTON = 10;

// Which dots are on for faces 1 to 6 (bit 0 = TL ... bit 6 = BR).
const byte FACES[7] = {
  0,
  0b0001000,  // 1: center
  0b0100010,  // 2: top-right, bottom-left
  0b0101010,  // 3: diagonal
  0b1100011,  // 4: corners
  0b1101011,  // 5: corners + center
  0b1110111   // 6: two columns
};

void showFace(int n) {
  for (int d = 0; d < 7; d++) digitalWrite(DOTS[d], bitRead(FACES[n], d));
}

void setup() {
  for (int d = 0; d < 7; d++) pinMode(DOTS[d], OUTPUT);
  pinMode(BUTTON, INPUT_PULLUP);
  randomSeed(analogRead(A0));
  showFace(6);
}

void loop() {
  if (digitalRead(BUTTON) == LOW) {
    for (int i = 0; i < 15; i++) {  // tumble
      showFace(random(1, 7));
      delay(40 + i * 10);
    }
    showFace(random(1, 7));
    while (digitalRead(BUTTON) == LOW) delay(10);
  }
}
