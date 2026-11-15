// @title Serial Plotter Wave Drawing
// @category Arduino
// @kind Arduino sketch
// @where Any Arduino; upload, then open Tools > Serial Plotter at 9600 (not the Serial Monitor).
// @keywords serial plotter, draw graphs arduino, sine wave plotter, plot multiple lines
// @about Draws a sine wave, a square wave and a sawtooth wave as three colored lines in the Serial Plotter.

float t = 0;

void setup() {
  Serial.begin(9600);
}

void loop() {
  float sine = sin(t) * 100;
  float square = (sin(t) >= 0) ? 80 : -80;
  // fmod gives the remainder, so the sawtooth climbs and then drops back.
  float saw = fmod(t, TWO_PI) / TWO_PI * 200 - 100;

  // Name:value pairs separated by commas = one line per name.
  Serial.print("sine:");
  Serial.print(sine);
  Serial.print(",square:");
  Serial.print(square);
  Serial.print(",sawtooth:");
  Serial.println(saw);

  t += 0.1;
  if (t > 1000) t = 0;  // keep the number from growing forever
  delay(20);
}
