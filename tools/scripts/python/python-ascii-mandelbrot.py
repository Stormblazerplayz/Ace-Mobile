# @title Mandelbrot Set in Text
# @category Drawing
# @kind Console program
# @where Save as mandelbrot.py and run: python3 mandelbrot.py (make your terminal window wide).
# @keywords python mandelbrot, python ascii fractal, python complex numbers, python fractal text art
# @about Draws the famous Mandelbrot fractal using only text characters and complex number math.

WIDTH, HEIGHT = 78, 32
CHARS = " .:-=+*#%@"   # from "escaped fast" to "never escaped"
MAX_STEPS = 60

for row in range(HEIGHT):
    line = ""
    for col in range(WIDTH):
        # Turn this character's position into a complex number c
        c = complex(-2.2 + col * 3.0 / WIDTH, -1.2 + row * 2.4 / HEIGHT)
        z = 0j
        steps = 0
        # Keep doing z = z*z + c. If z flies far away, c is NOT in the set.
        while abs(z) <= 2 and steps < MAX_STEPS:
            z = z * z + c
            steps += 1
        line += CHARS[min(steps * len(CHARS) // MAX_STEPS, len(CHARS) - 1)]
    print(line)

print("The @ shape in the middle is the Mandelbrot set. Its edge is infinitely detailed!")
