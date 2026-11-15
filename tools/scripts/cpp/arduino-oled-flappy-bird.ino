// @title OLED Flappy Bird
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Adafruit SSD1306" and "Adafruit GFX Library"; OLED SDA A4, SCL A5, VCC 5V, GND; flap button between pin 2 and GND.
// @keywords flappy bird arduino, oled flappy game, tap to fly game, pipes game oled
// @about Tap the button to flap and fly a little bird through gaps in the pipes.

#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

Adafruit_SSD1306 display(128, 64, &Wire, -1);
const int BUTTON = 2;
const int GAP = 24;
const int PIPE_W = 10;

float birdY, birdSpeed;
int pipeX, gapY, score;
bool lastButton = HIGH;

void newGame() {
  birdY = 32;
  birdSpeed = 0;
  pipeX = 128;
  gapY = random(8, 64 - GAP - 8);
  score = 0;
}

void setup() {
  pinMode(BUTTON, INPUT_PULLUP);
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  display.setTextColor(SSD1306_WHITE);
  randomSeed(analogRead(A0));
  newGame();
}

void loop() {
  bool button = digitalRead(BUTTON);
  if (button == LOW && lastButton == HIGH) birdSpeed = -3.2;  // flap!
  lastButton = button;

  birdSpeed += 0.35;  // gravity
  birdY += birdSpeed;
  pipeX -= 2;
  if (pipeX < -PIPE_W) {  // pipe left the screen: make a new one
    pipeX = 128;
    gapY = random(8, 64 - GAP - 8);
    score++;
  }

  // Crash check: hit the floor, the ceiling or a pipe (the bird sits at x = 20).
  bool inPipeColumn = pipeX < 24 && pipeX + PIPE_W > 16;
  bool outsideGap = birdY - 3 < gapY || birdY + 3 > gapY + GAP;
  if (birdY > 63 || birdY < 0 || (inPipeColumn && outsideGap)) {
    display.clearDisplay();
    display.setTextSize(2);
    display.setCursor(10, 10);
    display.print("GAME OVER");
    display.setTextSize(1);
    display.setCursor(34, 40);
    display.print("Score: ");
    display.print(score);
    display.display();
    delay(1500);
    while (digitalRead(BUTTON) == HIGH) {}
    newGame();
    return;
  }

  display.clearDisplay();
  display.fillRect(pipeX, 0, PIPE_W, gapY, SSD1306_WHITE);
  display.fillRect(pipeX, gapY + GAP, PIPE_W, 64 - gapY - GAP, SSD1306_WHITE);
  display.fillCircle(20, (int)birdY, 3, SSD1306_WHITE);
  display.setTextSize(1);
  display.setCursor(110, 0);
  display.print(score);
  display.display();
  delay(20);
}
