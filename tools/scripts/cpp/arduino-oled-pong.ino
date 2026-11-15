// @title OLED Pong for Two Players
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Adafruit SSD1306" and "Adafruit GFX Library"; OLED SDA A4, SCL A5; left paddle knob middle leg on A0, right paddle knob on A1; buzzer pin 8.
// @keywords oled pong, pong game arduino, two player paddle game, potentiometer paddles
// @about Classic Pong on an OLED where each player turns a knob to move their paddle; first to 5 wins.

#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

Adafruit_SSD1306 display(128, 64, &Wire, -1);
const int PADDLE_H = 14;
const int BUZZER = 8;
float ballX, ballY, speedX, speedY;
int leftScore = 0, rightScore = 0;

void serve(int direction) {
  ballX = 64;
  ballY = 32;
  speedX = 1.6 * direction;
  speedY = random(-10, 11) / 10.0;
}

void setup() {
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  display.setTextColor(SSD1306_WHITE);
  randomSeed(analogRead(A2));
  serve(1);
}

void loop() {
  int leftY = map(analogRead(A0), 0, 1023, 0, 64 - PADDLE_H);
  int rightY = map(analogRead(A1), 0, 1023, 0, 64 - PADDLE_H);

  ballX += speedX;
  ballY += speedY;
  if (ballY <= 0 || ballY >= 63) { speedY = -speedY; tone(BUZZER, 400, 10); }

  // Paddle hits: bounce back a bit faster, and where it hits changes the angle.
  if (ballX <= 4 && ballY >= leftY && ballY <= leftY + PADDLE_H && speedX < 0) {
    speedX = -speedX * 1.05;
    speedY = (ballY - (leftY + PADDLE_H / 2)) / 4.0;
    tone(BUZZER, 800, 15);
  }
  if (ballX >= 123 && ballY >= rightY && ballY <= rightY + PADDLE_H && speedX > 0) {
    speedX = -speedX * 1.05;
    speedY = (ballY - (rightY + PADDLE_H / 2)) / 4.0;
    tone(BUZZER, 800, 15);
  }

  // Missed: a point for the other player.
  if (ballX < 0) { rightScore++; tone(BUZZER, 200, 200); serve(1); }
  if (ballX > 127) { leftScore++; tone(BUZZER, 200, 200); serve(-1); }

  display.clearDisplay();
  for (int y = 0; y < 64; y += 6) display.drawFastVLine(64, y, 3, SSD1306_WHITE);  // net
  display.fillRect(1, leftY, 3, PADDLE_H, SSD1306_WHITE);
  display.fillRect(124, rightY, 3, PADDLE_H, SSD1306_WHITE);
  display.fillRect((int)ballX - 1, (int)ballY - 1, 3, 3, SSD1306_WHITE);
  display.setCursor(50, 0);
  display.print(leftScore);
  display.setCursor(74, 0);
  display.print(rightScore);

  if (leftScore == 5 || rightScore == 5) {
    display.setCursor(28, 28);
    display.print(leftScore == 5 ? "LEFT WINS!" : "RIGHT WINS!");
    display.display();
    delay(4000);
    leftScore = rightScore = 0;
  }
  display.display();
}
