// @title Snake Game on an 8x8 LED Matrix
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "LedControl"; MAX7219 matrix DIN 12, CLK 11, CS 10, VCC 5V, GND; joystick VRx A0, VRy A1, 5V, GND.
// @keywords snake game arduino, led matrix snake, max7219 game, joystick snake
// @about Plays Snake on an 8x8 LED matrix: steer with a joystick, eat the blinking food and don't bite yourself.

#include <LedControl.h>

LedControl matrix(12, 11, 10, 1);
const int MAX_LEN = 64;
int snakeX[MAX_LEN], snakeY[MAX_LEN];
int length;
int dirX, dirY;
int foodX, foodY;

void placeFood() {
  bool onSnake;
  do {  // keep picking until the food is not on the snake
    foodX = random(8);
    foodY = random(8);
    onSnake = false;
    for (int i = 0; i < length; i++) {
      if (snakeX[i] == foodX && snakeY[i] == foodY) onSnake = true;
    }
  } while (onSnake);
}

void newGame() {
  length = 2;
  snakeX[0] = 4; snakeY[0] = 4;
  snakeX[1] = 3; snakeY[1] = 4;
  dirX = 1; dirY = 0;
  placeFood();
}

void setup() {
  matrix.shutdown(0, false);
  matrix.setIntensity(0, 3);
  randomSeed(analogRead(A2));
  newGame();
}

void readJoystick() {
  int x = analogRead(A0), y = analogRead(A1);
  // Never let the snake turn straight back into itself.
  if (x < 300 && dirX != 1) { dirX = -1; dirY = 0; }
  else if (x > 700 && dirX != -1) { dirX = 1; dirY = 0; }
  else if (y < 300 && dirY != 1) { dirX = 0; dirY = -1; }
  else if (y > 700 && dirY != -1) { dirX = 0; dirY = 1; }
}

void loop() {
  for (int i = 0; i < 10; i++) { readJoystick(); delay(25); }  // 250 ms per move

  int newX = (snakeX[0] + dirX + 8) % 8;  // wrap around the edges
  int newY = (snakeY[0] + dirY + 8) % 8;
  for (int i = 0; i < length - 1; i++) {  // the tail end moves away, so skip it
    if (snakeX[i] == newX && snakeY[i] == newY) {
      for (int k = 0; k < 3; k++) {  // crash: flash the screen
        for (int r = 0; r < 8; r++) matrix.setRow(0, r, 0xFF);
        delay(200);
        matrix.clearDisplay(0);
        delay(200);
      }
      newGame();
      return;
    }
  }

  bool ate = newX == foodX && newY == foodY;
  if (ate && length < MAX_LEN) length++;
  for (int i = length - 1; i > 0; i--) {  // body follows the head
    snakeX[i] = snakeX[i - 1];
    snakeY[i] = snakeY[i - 1];
  }
  snakeX[0] = newX;
  snakeY[0] = newY;
  if (ate) {
    if (length == MAX_LEN) newGame();  // you filled the board: you win!
    else placeFood();
  }

  matrix.clearDisplay(0);
  for (int i = 0; i < length; i++) matrix.setLed(0, snakeY[i], snakeX[i], true);
  matrix.setLed(0, foodY, foodX, (millis() / 250) % 2);  // blinking food
}
