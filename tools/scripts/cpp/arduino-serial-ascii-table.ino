// @title ASCII Table Printer
// @category Arduino
// @kind Arduino sketch
// @where Any Arduino; open Serial Monitor at 9600, then type any key to see its number.
// @keywords ascii table, character codes, what number is a letter, ascii arduino serial
// @about Prints every letter and symbol with its number in decimal, hex and binary, then tells you the code of any key you type.

void setup() {
  Serial.begin(9600);
  Serial.println("Char  Dec  Hex  Binary");
  for (int code = 33; code <= 126; code++) {  // the printable characters
    Serial.print("  ");
    Serial.print((char)code);
    Serial.print("   ");
    Serial.print(code);
    Serial.print("   ");
    Serial.print(code, HEX);
    Serial.print("   ");
    Serial.println(code, BIN);
  }
  Serial.println("\nNow type something and press Enter:");
}

void loop() {
  if (Serial.available()) {
    int c = Serial.read();
    if (c == '\n' || c == '\r') return;
    Serial.print("'");
    Serial.print((char)c);
    Serial.print("' is number ");
    Serial.println(c);
  }
}
