// @title LCD Dino Jump Game
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "LiquidCrystal I2C"; LCD SDA A4, SCL A5, VCC 5V, GND; jump button between pin 2 and GND.
// @keywords lcd game, dino jump game, runner game 16x2, jump over cactus arduino, lcd endless runner
// @about An endless runner on a 16x2 LCD: press the button to make the dino jump over cactuses.

#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);
const int JUMP_BUTTON = 2;

byte dino[8]   = {0b00111, 0b00101, 0b00111, 0b10110, 0b11111, 0b01110, 0b01010, 0b01010};
byte cactus[8] = {0b00100, 0b00101, 0b10101, 0b10101, 0b10111, 0b11100, 0b00100, 0b00100};

bool cactusAt[16];      // which bottom columns have a cactus
int jumpTimer = 0;      // > 0 while the dino is in the air
unsigned long score = 0;

void newGame() {
  for (int i = 0; i < 16; i++) cactusAt[i] = false;
  jumpTimer = 0;
  score = 0;
}

void setup() {
  pinMode(JUMP_BUTTON, INPUT_PULLUP);
  lcd.init();
  lcd.backlight();
  lcd.createChar(0, dino);
  lcd.createChar(1, cactus);
  randomSeed(analogRead(A0));
  newGame();
}

void loop() {
  // Jump if the button is pressed and we are on the ground.
  if (digitalRead(JUMP_BUTTON) == LOW && jumpTimer == 0) jumpTimer = 4;

  // Slide every cactus one step to the left.
  for (int i = 0; i < 15; i++) cactusAt[i] = cactusAt[i + 1];
  // Maybe add a new one on the right, but never two in a row (impossible to jump).
  cactusAt[15] = !cactusAt[14] && !cactusAt[13] && random(100) < 30;

  bool inAir = jumpTimer > 0;
  if (cactusAt[1] && !inAir) {  // the dino lives in column 1
    lcd.clear();
    lcd.print("  GAME OVER!");
    lcd.setCursor(0, 1);
    lcd.print("  Score: ");
    lcd.print(score);
    delay(3000);
    while (digitalRead(JUMP_BUTTON) == HIGH) {}  // press to play again
    newGame();
    return;
  }

  // Draw everything.
  lcd.clear();
  for (int i = 0; i < 16; i++) {
    if (cactusAt[i]) {
      lcd.setCursor(i, 1);
      lcd.write(byte(1));
    }
  }
  lcd.setCursor(1, inAir ? 0 : 1);
  lcd.write(byte(0));
  lcd.setCursor(11, 0);
  lcd.print(score);

  if (jumpTimer > 0) jumpTimer--;
  score++;
  // Speed up as the score grows, but never faster than 90 ms a step.
  delay(score < 160 ? 250 - score : 90);
}
