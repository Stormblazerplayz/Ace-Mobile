// @title Traffic Light State Machine with Crossing Button
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; car lights red 4, yellow 5, green 6; walker lights red 7, green 8 (220 ohm each); crossing button pin 2 to GND; buzzer pin 9.
// @keywords state machine arduino, pedestrian crossing, enum states, traffic light with button, switch case states
// @about A pedestrian crossing built as a state machine with millis(), so the button is noticed at any moment.

const int CAR_RED = 4, CAR_YELLOW = 5, CAR_GREEN = 6, WALK_RED = 7, WALK_GREEN = 8;
const int BUTTON = 2, BUZZER = 9;

enum State { CARS_GO, CARS_SLOW, WALKERS_GO, WALKERS_HURRY };
State state = CARS_GO;
unsigned long stateStart = 0;
bool someoneWaiting = false;

void lights(int carR, int carY, int carG, int walkR, int walkG) {
  digitalWrite(CAR_RED, carR);
  digitalWrite(CAR_YELLOW, carY);
  digitalWrite(CAR_GREEN, carG);
  digitalWrite(WALK_RED, walkR);
  digitalWrite(WALK_GREEN, walkG);
}

void goTo(State next) {
  state = next;
  stateStart = millis();
}

void setup() {
  int pins[] = {CAR_RED, CAR_YELLOW, CAR_GREEN, WALK_RED, WALK_GREEN, BUZZER};
  for (int i = 0; i < 6; i++) pinMode(pins[i], OUTPUT);
  pinMode(BUTTON, INPUT_PULLUP);
}

void loop() {
  unsigned long inState = millis() - stateStart;  // how long we've been in this state
  if (digitalRead(BUTTON) == LOW) someoneWaiting = true;

  switch (state) {
    case CARS_GO:
      lights(LOW, LOW, HIGH, HIGH, LOW);
      // Cars get at least 5 seconds of green before walkers can cross.
      if (someoneWaiting && inState > 5000) goTo(CARS_SLOW);
      break;
    case CARS_SLOW:
      lights(LOW, HIGH, LOW, HIGH, LOW);
      if (inState > 2000) goTo(WALKERS_GO);
      break;
    case WALKERS_GO:
      lights(HIGH, LOW, LOW, LOW, HIGH);
      // Beep-beep while it's safe to walk.
      if ((inState / 300) % 2 == 0) tone(BUZZER, 1800); else noTone(BUZZER);
      someoneWaiting = false;
      if (inState > 6000) { noTone(BUZZER); goTo(WALKERS_HURRY); }
      break;
    case WALKERS_HURRY:
      // Flash the walking man: hurry up!
      lights(HIGH, LOW, LOW, LOW, (inState / 250) % 2 == 0);
      if (inState > 3000) goTo(CARS_GO);
      break;
  }
}
