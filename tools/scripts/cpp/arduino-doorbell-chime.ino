// @title Ding Dong Doorbell
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; push button between pin 2 and GND; passive buzzer on pin 8; LED on pin 13.
// @keywords doorbell, ding dong chime, bedroom doorbell arduino, button doorbell buzzer
// @about Plays a ding-dong chime and flashes a light when someone presses the doorbell button.

const int BUTTON_PIN = 2;
const int BUZZER_PIN = 8;
const int LED_PIN = 13;

void dingDong() {
  digitalWrite(LED_PIN, HIGH);
  tone(BUZZER_PIN, 659, 500);  // E5: ding
  delay(550);
  tone(BUZZER_PIN, 523, 800);  // C5: dong
  delay(850);
  digitalWrite(LED_PIN, LOW);
}

void setup() {
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
}

void loop() {
  if (digitalRead(BUTTON_PIN) == LOW) {
    dingDong();
    // Wait until the button is let go, so holding it only rings once.
    while (digitalRead(BUTTON_PIN) == LOW) delay(10);
    delay(300);
  }
}
