#!/usr/bin/env python3
"""Builds data/coding/gen_python_api.txt: plain-words answers about Python built-ins and standard library.

Source: the descriptions below were written by hand for Ace from the Python 3 documentation
(docs.python.org, PSF license). The script checks every name really exists in the Python that runs it
(it imports the module and looks the name up), so typos or made-up functions fail the build.

Run from the repo root:
    python3 tools/knowledge/gen/coding_python_api.py
"""
import builtins
import importlib
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
KNOW = os.path.dirname(HERE)
OUT = os.path.join(KNOW, "data", "coding", "gen_python_api.txt")
sys.path.insert(0, KNOW)
from check_data import keyset, norm  # noqa: E402
from coding_common import existing  # noqa: E402

BUILTINS = {
    "abs": "abs(x) gives the distance from zero, so abs(-7) is 7 and abs(3.5) is 3.5.",
    "all": "all(items) is True if every item is truthy (or the list is empty), like all([1, 2, 3]). One falsy item makes it False.",
    "any": "any(items) is True if at least one item is truthy, like any([0, 0, 5]). An empty list gives False.",
    "bin": "bin(n) turns a whole number into a binary string, so bin(5) is '0b101'.",
    "bool": "bool(x) turns a value into True or False. 0, empty strings, empty lists and None become False; almost everything else is True.",
    "chr": "chr(n) gives the character for a Unicode number, so chr(65) is 'A'. It is the opposite of ord.",
    "dict": "dict() makes a dictionary, like dict(name='Sam', age=12) or dict([('a', 1), ('b', 2)]).",
    "dir": "dir(obj) lists the names (attributes and methods) an object has, which is handy for exploring in the Python shell.",
    "divmod": "divmod(a, b) gives the whole-number quotient and the remainder together, so divmod(17, 5) is (3, 2).",
    "enumerate": "enumerate(items) gives the index and the item together in a loop: for i, name in enumerate(names): print(i, name). Use enumerate(items, 1) to start at 1.",
    "eval": "eval(text) runs a string as a Python expression and returns the result. Never use it on text a user typed, because it can run any code.",
    "filter": "filter(func, items) keeps only items where func returns True, like list(filter(lambda n: n > 0, nums)). A list comprehension often reads easier.",
    "float": "float(x) turns a number or a string like '3.5' into a decimal number. It raises ValueError if the text is not a number.",
    "format": "format(value, spec) formats a value, like format(3.14159, '.2f') giving '3.14' or format(1234567, ',') giving '1,234,567'.",
    "getattr": "getattr(obj, 'name', default) reads an attribute by its name as a string, and returns default instead of crashing if it is missing.",
    "hasattr": "hasattr(obj, 'name') is True if the object has that attribute or method.",
    "hash": "hash(x) gives the number Python uses to store x in sets and dict keys. Only immutable things like numbers, strings and tuples can be hashed.",
    "help": "help(thing) shows the built-in documentation for a function, module or class, like help(str.split), in the Python shell.",
    "hex": "hex(n) turns a whole number into a hexadecimal string, so hex(255) is '0xff'.",
    "id": "id(obj) gives a number that is unique for that object while it exists. Two names with the same id point to the same object.",
    "input": "input('prompt ') shows the prompt, waits for the user to type and press Enter, and returns what they typed as a string. Use int(input()) for numbers.",
    "int": "int(x) turns a string or number into a whole number. int('42') is 42 and int(3.9) is 3, because it cuts off the decimal instead of rounding.",
    "isinstance": "isinstance(x, int) is True if x is that type or a subclass of it. You can pass a tuple of types: isinstance(x, (int, float)).",
    "issubclass": "issubclass(Dog, Animal) is True if the Dog class inherits from Animal.",
    "iter": "iter(items) gets an iterator from a list or other iterable, which next() can step through one item at a time.",
    "len": "len(x) gives how many items are in a list, tuple, dict or set, or how many characters are in a string. len('hello') is 5.",
    "list": "list(x) makes a new list from any iterable, like list('abc') giving ['a', 'b', 'c'] or list(range(3)) giving [0, 1, 2].",
    "map": "map(func, items) runs func on every item, like list(map(int, ['1', '2'])) giving [1, 2]. It returns a lazy map object, so wrap it in list() to see it.",
    "max": "max(items) gives the biggest item, and max(a, b, c) the biggest argument. max(words, key=len) gives the longest word.",
    "min": "min(items) gives the smallest item, and min(a, b) the smaller one. Use key= to compare by something, like min(people, key=lambda p: p.age).",
    "next": "next(iterator) gets the next item from an iterator, and next(it, default) returns default instead of raising StopIteration at the end.",
    "oct": "oct(n) turns a whole number into an octal (base 8) string, so oct(8) is '0o10'.",
    "open": "open(path, mode) opens a file. Use with open('notes.txt', 'r') as f: text = f.read(). Modes: 'r' read, 'w' write (erases first), 'a' append, 'b' for binary.",
    "ord": "ord(c) gives the Unicode number of one character, so ord('A') is 65. It is the opposite of chr.",
    "pow": "pow(a, b) is a to the power of b, the same as a ** b. pow(a, b, m) also takes the remainder by m quickly.",
    "print": "print(a, b) shows values on screen separated by spaces. Use sep='' to change the separator and end='' to stop the new line at the end.",
    "range": "range(stop), range(start, stop) or range(start, stop, step) makes a sequence of whole numbers for loops. The stop number is not included, so range(5) is 0 to 4.",
    "repr": "repr(x) gives a string that shows the value the way a programmer would type it, like repr('hi') giving \"'hi'\" with quotes.",
    "reversed": "reversed(items) gives the items in reverse order as an iterator, like list(reversed([1, 2, 3])) giving [3, 2, 1]. It does not change the original.",
    "round": "round(x) rounds to the nearest whole number and round(x, 2) to 2 decimals. Halfway values round to the even number, so round(2.5) is 2 and round(3.5) is 4.",
    "set": "set(items) makes a set, which keeps only unique values with no order, like set([1, 1, 2]) giving {1, 2}. Use set() for an empty set, since {} is an empty dict.",
    "setattr": "setattr(obj, 'name', value) sets an attribute by its name as a string, the same as obj.name = value.",
    "sorted": "sorted(items) returns a new sorted list and leaves the original alone. Use reverse=True for big to small and key= to sort by something, like key=len.",
    "str": "str(x) turns a value into a string, like str(42) giving '42', so you can join it with other text.",
    "sum": "sum(numbers) adds up a list of numbers, like sum([1, 2, 3]) giving 6. sum(nums, 10) starts counting from 10.",
    "super": "super() lets a method call the same method in the parent class, most often super().__init__(...) inside a child class's __init__.",
    "tuple": "tuple(items) makes a tuple, an ordered list that cannot be changed, like tuple([1, 2]) giving (1, 2).",
    "type": "type(x) tells you the type of a value, like type(5) giving <class 'int'>. For checks, isinstance is usually better.",
    "vars": "vars(obj) returns the object's __dict__, a dictionary of its attributes, which is handy for printing what an object holds.",
    "zip": "zip(a, b) pairs up items from several lists: list(zip([1, 2], ['a', 'b'])) gives [(1, 'a'), (2, 'b')]. It stops at the shortest list.",
    "callable": "callable(x) is True if x can be called like a function, such as functions, classes and objects with __call__.",
    "globals": "globals() returns a dictionary of the module's global variables. You rarely need it in normal programs.",
    "exec": "exec(code) runs a string of Python statements. Like eval, never run text you did not write yourself.",
    "frozenset": "frozenset(items) is a set that cannot be changed after it is made, so it can be a dict key or go inside another set.",
    "bytes": "bytes makes an unchangeable sequence of bytes (numbers 0 to 255), like b'hi' or 'hi'.encode('utf-8'). Files opened with 'rb' give bytes.",
    "bytearray": "bytearray is like bytes but can be changed in place, which is useful for building binary data.",
    "slice": "slice(start, stop, step) makes a slice object, the same thing as writing items[start:stop:step].",
    "complex": "complex(real, imag) makes a complex number, like complex(2, 3) which is 2+3j. Python writes the imaginary unit as j.",
    "object": "object is the base class every Python class inherits from. object() makes a plain empty object, sometimes used as a unique marker.",
    "property": "property turns a method into an attribute you read without parentheses. Put @property above a method like def area(self) and read it as shape.area.",
    "staticmethod": "@staticmethod marks a method that does not get self or cls, so it works like a normal function stored in the class.",
    "classmethod": "@classmethod marks a method that gets the class as cls instead of an instance. It is often used for other ways to build objects, like Date.from_string().",
    "breakpoint": "breakpoint() pauses your program and opens the pdb debugger at that line, so you can look at variables and step through code.",
    "ascii": "ascii(x) is like repr(x) but turns non-ASCII characters into escape codes, so ascii('café') gives \"'caf\\xe9'\".",
    "aiter": "aiter(x) gets an async iterator, the async version of iter(), used with async for loops.",
    "memoryview": "memoryview(data) lets you look at the bytes of an object like bytes or bytearray without copying them.",
}

STR = {
    "upper": "s.upper() returns a copy with all letters in capitals, so 'hi'.upper() is 'HI'.",
    "lower": "s.lower() returns a copy in all lowercase, handy for comparing text without caring about capitals.",
    "title": "s.title() capitalizes the first letter of every word, so 'hello world'.title() is 'Hello World'.",
    "capitalize": "s.capitalize() makes the first character uppercase and the rest lowercase, so 'hELLO' becomes 'Hello'.",
    "swapcase": "s.swapcase() flips the case of every letter, so 'Hi' becomes 'hI'.",
    "strip": "s.strip() removes spaces, tabs and new lines from both ends. s.strip('!') removes that character from the ends instead.",
    "lstrip": "s.lstrip() removes whitespace (or the characters you give) only from the left side.",
    "rstrip": "s.rstrip() removes whitespace only from the right side, often used to drop the '\\n' at the end of a line from a file.",
    "split": "s.split() breaks a string into a list of words on whitespace. s.split(',') splits on commas, so 'a,b'.split(',') is ['a', 'b'].",
    "rsplit": "s.rsplit(sep, maxsplit) splits from the right side, so 'a.b.c'.rsplit('.', 1) gives ['a.b', 'c'].",
    "splitlines": "s.splitlines() splits text into a list of lines and removes the line endings.",
    "join": "sep.join(items) glues a list of strings together with sep between them, so ', '.join(['a', 'b']) is 'a, b'. Every item must be a string.",
    "replace": "s.replace(old, new) returns a copy with every old part changed to new. Add a count to limit it: s.replace('a', 'b', 1).",
    "find": "s.find(sub) returns the index where sub first appears, or -1 if it is not there.",
    "rfind": "s.rfind(sub) returns the index of the last place sub appears, or -1.",
    "index": "s.index(sub) is like find but raises ValueError if sub is missing.",
    "count": "s.count(sub) counts how many times sub appears without overlapping, so 'banana'.count('a') is 3.",
    "startswith": "s.startswith(prefix) is True if the string begins with prefix. You can pass a tuple to check several.",
    "endswith": "s.endswith(suffix) is True if the string ends with suffix, like name.endswith('.png').",
    "isdigit": "s.isdigit() is True if the string is not empty and every character is a digit, so '123'.isdigit() is True but '-1' and '1.5' are False.",
    "isalpha": "s.isalpha() is True if the string is not empty and has only letters.",
    "isalnum": "s.isalnum() is True if every character is a letter or digit and the string is not empty.",
    "isspace": "s.isspace() is True if the string is not empty and has only whitespace.",
    "isupper": "s.isupper() is True if it has at least one letter and all its letters are uppercase.",
    "islower": "s.islower() is True if it has at least one letter and all its letters are lowercase.",
    "isnumeric": "s.isnumeric() is True for strings made of number characters, including things like '½' that isdigit rejects.",
    "zfill": "s.zfill(width) pads a number string with zeros on the left, so '7'.zfill(3) is '007'.",
    "center": "s.center(width) pads the string with spaces on both sides to that width. s.center(20, '*') uses stars.",
    "ljust": "s.ljust(width) pads on the right so text lines up in columns. rjust pads on the left.",
    "rjust": "s.rjust(width) pads on the left, good for lining up numbers on the right.",
    "format": "s.format(...) fills {} placeholders: 'Hi {}!'.format(name). f-strings like f'Hi {name}!' do the same and are easier to read.",
    "encode": "s.encode('utf-8') turns a string into bytes so it can be saved or sent. bytes.decode('utf-8') turns it back.",
    "partition": "s.partition(sep) splits at the first sep into a 3-part tuple: before, sep, after. 'key=value'.partition('=') gives ('key', '=', 'value').",
    "removeprefix": "s.removeprefix(prefix) removes that exact text from the start if it is there (Python 3.9 and newer).",
    "removesuffix": "s.removesuffix(suffix) removes that exact text from the end if it is there, like 'photo.png'.removesuffix('.png') (Python 3.9 and newer).",
    "casefold": "s.casefold() is a stronger lower() meant for comparing text without caring about case in every language.",
    "expandtabs": "s.expandtabs(4) replaces tab characters with spaces, using tab stops every 4 columns.",
    "translate": "s.translate(table) replaces or deletes characters using a table made with str.maketrans, like removing all punctuation at once.",
}

LIST = {
    "append": "items.append(x) adds one item to the end of the list. It changes the list and returns None, so do not write items = items.append(x).",
    "extend": "items.extend(other) adds every item from another list to the end. append(other) would add the whole list as one item instead.",
    "insert": "items.insert(i, x) puts x at position i and shifts the rest right. items.insert(0, x) adds to the front.",
    "remove": "items.remove(x) deletes the first item equal to x. It raises ValueError if x is not in the list.",
    "pop": "items.pop() removes and returns the last item, and items.pop(i) removes the one at index i. It raises IndexError on an empty list.",
    "clear": "items.clear() removes everything from the list, leaving it empty.",
    "index": "items.index(x) returns the position of the first x. It raises ValueError if x is missing, so check with 'if x in items' first.",
    "count": "items.count(x) returns how many times x appears in the list.",
    "sort": "items.sort() sorts the list in place and returns None. Use items.sort(reverse=True) for big to small, or key=len to sort by length.",
    "reverse": "items.reverse() flips the list in place. items[::-1] makes a reversed copy instead.",
    "copy": "items.copy() makes a shallow copy, the same as items[:]. Lists inside it are still shared.",
}

DICT = {
    "get": "d.get(key) returns the value or None if the key is missing, and d.get(key, 0) returns 0 instead. It never raises KeyError.",
    "keys": "d.keys() gives a live view of all the keys. Loop it with for k in d.keys(), or just for k in d.",
    "values": "d.values() gives a view of all the values, like sum(scores.values()) to add them up.",
    "items": "d.items() gives (key, value) pairs, so you can loop with for name, score in d.items().",
    "pop": "d.pop(key) removes the key and returns its value. d.pop(key, None) avoids a KeyError when it is missing.",
    "popitem": "d.popitem() removes and returns the last added (key, value) pair.",
    "update": "d.update(other) adds or overwrites keys from another dict. In Python 3.9+ you can also write d |= other.",
    "setdefault": "d.setdefault(key, default) returns the value if the key exists, otherwise sets it to default and returns that.",
    "clear": "d.clear() removes every key, leaving an empty dict.",
    "copy": "d.copy() makes a shallow copy of the dictionary.",
    "fromkeys": "dict.fromkeys(keys, value) makes a new dict with every key set to the same value, like dict.fromkeys(['a', 'b'], 0).",
}

SET = {
    "add": "s.add(x) puts x in the set. Adding something already there does nothing.",
    "discard": "s.discard(x) removes x if it is there and does nothing if it is not.",
    "union": "a.union(b), or a | b, gives a new set with everything from both.",
    "intersection": "a.intersection(b), or a & b, gives the items that are in both sets.",
    "difference": "a.difference(b), or a - b, gives the items in a that are not in b.",
    "symmetric_difference": "a.symmetric_difference(b), or a ^ b, gives items in one set or the other but not both.",
    "issubset": "a.issubset(b), or a <= b, is True if every item of a is also in b.",
    "issuperset": "a.issuperset(b), or a >= b, is True if a contains every item of b.",
    "isdisjoint": "a.isdisjoint(b) is True if the sets share no items.",
}
SET_REMOVE = "s.remove(x) deletes x from the set and raises KeyError if it is missing; use discard to avoid the error."

MODULES = {
    "math": {
        "sqrt": "math.sqrt(x) gives the square root, so math.sqrt(16) is 4.0. For a whole number answer use math.isqrt.",
        "floor": "math.floor(x) rounds down to a whole number, so math.floor(3.9) is 3 and math.floor(-1.5) is -2.",
        "ceil": "math.ceil(x) rounds up to a whole number, so math.ceil(3.1) is 4.",
        "trunc": "math.trunc(x) cuts off the decimal part, so math.trunc(-2.7) is -2.",
        "pi": "math.pi is pi, about 3.141592653589793.",
        "e": "math.e is Euler's number, about 2.718281828459045, the base of natural logarithms.",
        "tau": "math.tau is 2 times pi, about 6.283, one full turn in radians.",
        "inf": "math.inf is infinity, bigger than every number. -math.inf is smaller than every number.",
        "pow": "math.pow(x, y) is x to the power y and always returns a float. The ** operator keeps whole numbers whole.",
        "sin": "math.sin(x) is the sine of an angle in radians. Use math.radians(deg) to convert from degrees first.",
        "cos": "math.cos(x) is the cosine of an angle in radians.",
        "tan": "math.tan(x) is the tangent of an angle in radians.",
        "atan2": "math.atan2(y, x) gives the angle in radians from the x axis to the point (x, y), handling every direction correctly.",
        "radians": "math.radians(deg) converts degrees to radians, so math.radians(180) is pi.",
        "degrees": "math.degrees(rad) converts radians to degrees.",
        "log": "math.log(x) is the natural log, and math.log(x, base) uses another base, like math.log(8, 2) giving 3.0.",
        "log10": "math.log10(x) is the base 10 logarithm, so math.log10(1000) is 3.0.",
        "log2": "math.log2(x) is the base 2 logarithm, so math.log2(8) is 3.0.",
        "exp": "math.exp(x) is e to the power x.",
        "factorial": "math.factorial(n) multiplies 1 x 2 x ... x n, so math.factorial(5) is 120.",
        "gcd": "math.gcd(a, b) gives the greatest common divisor, the biggest number that divides both, so math.gcd(12, 18) is 6.",
        "lcm": "math.lcm(a, b) gives the least common multiple, so math.lcm(4, 6) is 12 (Python 3.9+).",
        "hypot": "math.hypot(x, y) gives the length of the hypotenuse, sqrt(x*x + y*y), handy for distances.",
        "dist": "math.dist(p, q) gives the straight-line distance between two points, like math.dist((0, 0), (3, 4)) giving 5.0.",
        "isclose": "math.isclose(a, b) checks if two floats are almost equal, which is the right way to compare decimals like 0.1 + 0.2 and 0.3.",
        "fabs": "math.fabs(x) gives the absolute value as a float.",
        "comb": "math.comb(n, k) counts the ways to choose k items from n without caring about order, so math.comb(5, 2) is 10.",
        "perm": "math.perm(n, k) counts the ways to arrange k items out of n where order matters.",
        "isqrt": "math.isqrt(n) gives the whole-number square root rounded down, so math.isqrt(10) is 3.",
        "prod": "math.prod(items) multiplies all the numbers together, like math.prod([2, 3, 4]) giving 24.",
        "fsum": "math.fsum(items) adds floats with less rounding error than sum().",
        "copysign": "math.copysign(x, y) gives x with the sign of y.",
        "isnan": "math.isnan(x) is True if x is NaN (not a number), which you get from things like float('nan').",
    },
    "random": {
        "random": "random.random() gives a random float from 0.0 up to but not including 1.0.",
        "randint": "random.randint(a, b) gives a random whole number from a to b, including both ends, so randint(1, 6) is a dice roll.",
        "randrange": "random.randrange(start, stop, step) picks a random number from range(start, stop, step); stop is not included.",
        "choice": "random.choice(items) picks one random item from a list or string.",
        "choices": "random.choices(items, k=3) picks 3 items with replacement (repeats allowed). Add weights=[...] to make some more likely.",
        "sample": "random.sample(items, k) picks k different items with no repeats, like drawing cards.",
        "shuffle": "random.shuffle(items) mixes a list into random order in place and returns None.",
        "uniform": "random.uniform(a, b) gives a random float between a and b.",
        "seed": "random.seed(n) sets the starting point so you get the same random numbers every run, which helps with testing.",
        "gauss": "random.gauss(mu, sigma) gives a random number from a bell curve with that average and spread.",
    },
    "os": {
        "getcwd": "os.getcwd() returns the working directory, the folder your program is running from.",
        "chdir": "os.chdir(path) changes the working directory to that folder.",
        "listdir": "os.listdir(path) returns a list of the names of files and folders inside a folder.",
        "mkdir": "os.mkdir(path) makes one new folder and raises FileExistsError if it is already there.",
        "makedirs": "os.makedirs(path, exist_ok=True) makes a folder and any missing parent folders, without an error if it exists.",
        "remove": "os.remove(path) deletes a file. It cannot delete folders; use os.rmdir or shutil.rmtree.",
        "rmdir": "os.rmdir(path) deletes an empty folder.",
        "rename": "os.rename(old, new) renames or moves a file or folder.",
        "walk": "os.walk(top) goes through a folder and all its subfolders, giving (folder, subfolders, files) for each, so you can process every file.",
        "getenv": "os.getenv('NAME', default) reads an environment variable, or returns default if it is not set.",
        "environ": "os.environ is a dict-like object of environment variables, like os.environ['PATH'].",
        "system": "os.system('command') runs a shell command. subprocess.run is the more modern and safer choice.",
        "sep": "os.sep is the folder separator for the computer: a backslash on Windows and '/' on macOS and Linux.",
        "cpu_count": "os.cpu_count() returns how many CPU cores (logical processors) the computer has.",
        "scandir": "os.scandir(path) lists folder entries with extra info like is_file() and stat(), and is faster than listdir when you need that info.",
    },
    "os.path": {
        "join": "os.path.join('folder', 'file.txt') builds a path with the right separator for the computer.",
        "exists": "os.path.exists(path) is True if a file or folder is at that path.",
        "isfile": "os.path.isfile(path) is True if the path is an existing file.",
        "isdir": "os.path.isdir(path) is True if the path is an existing folder.",
        "basename": "os.path.basename('/a/b/photo.png') gives 'photo.png', the last part of a path.",
        "dirname": "os.path.dirname('/a/b/photo.png') gives '/a/b', the folder part of a path.",
        "splitext": "os.path.splitext('photo.png') gives ('photo', '.png'), splitting off the file extension.",
        "abspath": "os.path.abspath(path) turns a relative path into a full path from the root.",
        "getsize": "os.path.getsize(path) returns a file's size in bytes.",
        "expanduser": "os.path.expanduser('~/notes') replaces ~ with the user's home folder.",
    },
    "sys": {
        "argv": "sys.argv is the list of command-line arguments; sys.argv[0] is the script name and the rest are what was typed after it.",
        "exit": "sys.exit() stops the program. sys.exit(1) signals an error to whatever started it.",
        "path": "sys.path is the list of folders Python searches when you import a module.",
        "version": "sys.version is a string describing the Python version that is running.",
        "platform": "sys.platform tells you the operating system, like 'win32', 'darwin' (macOS) or 'linux'.",
        "stdin": "sys.stdin is the input stream; sys.stdin.readline() reads a line, often faster than input() in big programs.",
        "getrecursionlimit": "sys.getrecursionlimit() shows how deep recursion can go before RecursionError, usually 1000. sys.setrecursionlimit changes it.",
        "executable": "sys.executable is the full path to the Python program that is running your script.",
    },
    "time": {
        "time": "time.time() returns the seconds since January 1, 1970 as a float. Subtract two of them to measure how long something took.",
        "sleep": "time.sleep(seconds) pauses the program, like time.sleep(0.5) for half a second.",
        "perf_counter": "time.perf_counter() is a very precise clock for measuring how long code takes; subtract a start value from an end value.",
        "strftime": "time.strftime('%H:%M:%S') formats the local time as text using codes like %Y year, %m month, %d day.",
        "localtime": "time.localtime() returns the local date and time as a struct with fields like tm_year and tm_hour.",
        "monotonic": "time.monotonic() is a clock that never goes backward, good for timeouts.",
    },
    "datetime": {
        "datetime": "datetime.datetime holds a date and a time together. datetime.datetime.now() gives the local date and time.",
        "date": "datetime.date holds just a date. datetime.date.today() gives today's date, and date(2025, 12, 25) makes one.",
        "timedelta": "datetime.timedelta is a length of time, like timedelta(days=7). Add it to a date to move forward, or subtract two dates to get one.",
        "time": "datetime.time holds a time of day without a date, like time(14, 30).",
        "timezone": "datetime.timezone represents a fixed UTC offset; datetime.now(timezone.utc) gives an aware UTC time.",
    },
    "json": {
        "dumps": "json.dumps(obj) turns a Python dict or list into a JSON string. Add indent=2 to make it easy to read.",
        "loads": "json.loads(text) turns a JSON string into Python dicts and lists.",
        "dump": "json.dump(obj, f) writes JSON straight into an open file.",
        "load": "json.load(f) reads JSON from an open file into Python objects.",
    },
    "re": {
        "search": "re.search(pattern, text) finds the first match anywhere in the text and returns a Match object or None.",
        "match": "re.match(pattern, text) only matches at the start of the text. Use re.search to look anywhere.",
        "fullmatch": "re.fullmatch(pattern, text) only succeeds if the whole string matches, good for checking input formats.",
        "findall": "re.findall(pattern, text) returns a list of every match, like re.findall(r'\\d+', 'a1b22') giving ['1', '22'].",
        "sub": "re.sub(pattern, replacement, text) replaces every match, like re.sub(r'\\s+', ' ', text) to squash extra spaces.",
        "split": "re.split(pattern, text) splits text wherever the pattern matches, like splitting on commas or spaces at once.",
        "compile": "re.compile(pattern) saves a pattern as an object you can reuse, with methods like .search and .findall.",
        "finditer": "re.finditer(pattern, text) loops over Match objects, so you get each match's position too.",
        "IGNORECASE": "re.IGNORECASE (or re.I) is a flag that makes a pattern ignore uppercase and lowercase differences.",
    },
    "collections": {
        "Counter": "collections.Counter(items) counts how many times each item appears, like Counter('hello')['l'] being 2. .most_common(3) gives the top 3.",
        "defaultdict": "collections.defaultdict(list) is a dict that makes a default value for missing keys, so d[k].append(x) works without checking first.",
        "deque": "collections.deque is a list-like queue that adds and removes from both ends fast, with append, appendleft, pop and popleft.",
        "namedtuple": "collections.namedtuple('Point', ['x', 'y']) makes a small tuple class whose items have names, so you can write p.x.",
        "OrderedDict": "collections.OrderedDict is a dict with extra ordering methods like move_to_end. Normal dicts keep insertion order since Python 3.7.",
        "ChainMap": "collections.ChainMap groups several dicts so lookups check each one in order, like settings overriding defaults.",
    },
    "itertools": {
        "count": "itertools.count(start, step) counts up forever, like an endless range.",
        "cycle": "itertools.cycle(items) repeats the items over and over forever.",
        "repeat": "itertools.repeat(x, n) gives the same value n times (or forever without n).",
        "chain": "itertools.chain(a, b) loops through several lists one after another as if they were one.",
        "permutations": "itertools.permutations(items, r) gives every ordering of r items, so permutations('abc', 2) includes ('a', 'b') and ('b', 'a').",
        "combinations": "itertools.combinations(items, r) gives every group of r items where order does not matter.",
        "product": "itertools.product(a, b) gives every pair from both lists, like nested for loops. product('ab', repeat=2) gives aa, ab, ba, bb.",
        "groupby": "itertools.groupby(items, key) groups items that are next to each other with the same key, so sort by that key first.",
        "accumulate": "itertools.accumulate(nums) gives running totals, so [1, 2, 3] becomes 1, 3, 6.",
        "islice": "itertools.islice(it, n) takes the first n items from any iterator, like slicing but for things without indexes.",
        "zip_longest": "itertools.zip_longest(a, b, fillvalue=None) zips lists of different lengths and fills the gaps.",
        "pairwise": "itertools.pairwise(items) gives each item with the next one, like (1, 2), (2, 3) (Python 3.10+).",
    },
    "functools": {
        "lru_cache": "@functools.lru_cache remembers results of a function for arguments it has seen, which makes slow recursive functions like Fibonacci very fast.",
        "cache": "@functools.cache is a simpler unlimited version of lru_cache that remembers every result (Python 3.9+).",
        "reduce": "functools.reduce(func, items) combines items into one value step by step, like reduce(lambda a, b: a * b, [1, 2, 3, 4]) giving 24.",
        "partial": "functools.partial(func, x) makes a new function with some arguments already filled in.",
        "wraps": "@functools.wraps(func) is used inside decorators so the wrapped function keeps its original name and docstring.",
    },
    "pathlib": {
        "Path": "pathlib.Path(path) makes a path object with handy tools: p.exists(), p.read_text(), p / 'file.txt', p.suffix, p.name and p.iterdir().",
    },
    "shutil": {
        "copy": "shutil.copy(src, dst) copies a file. shutil.copy2 also keeps the file's timestamps.",
        "copytree": "shutil.copytree(src, dst) copies a whole folder and everything inside it.",
        "rmtree": "shutil.rmtree(path) deletes a folder and everything in it. Be careful, it does not go to the recycle bin.",
        "move": "shutil.move(src, dst) moves a file or folder, even to another drive.",
        "make_archive": "shutil.make_archive('backup', 'zip', folder) zips a whole folder into backup.zip.",
        "which": "shutil.which('git') returns the full path of a program on the PATH, or None if it is not installed.",
        "disk_usage": "shutil.disk_usage(path) returns the total, used and free space of that drive in bytes.",
    },
    "subprocess": {
        "run": "subprocess.run(['git', 'status'], capture_output=True, text=True) runs another program and waits; the result's .stdout holds its output and .returncode its exit code.",
        "Popen": "subprocess.Popen starts another program without waiting, so you can talk to it or keep working while it runs.",
        "check_output": "subprocess.check_output(cmd) runs a command and returns its output, raising an error if it fails.",
    },
    "statistics": {
        "mean": "statistics.mean(nums) gives the average.",
        "median": "statistics.median(nums) gives the middle value after sorting.",
        "mode": "statistics.mode(items) gives the most common value.",
        "stdev": "statistics.stdev(nums) gives the sample standard deviation, how spread out the numbers are.",
    },
    "string": {
        "ascii_letters": "string.ascii_letters is 'abc...zABC...Z', all English letters in one string.",
        "ascii_lowercase": "string.ascii_lowercase is 'abcdefghijklmnopqrstuvwxyz'.",
        "digits": "string.digits is '0123456789'.",
        "punctuation": "string.punctuation is a string of ASCII punctuation marks like !\"#$%&'()*+,-./ and more.",
        "ascii_uppercase": "string.ascii_uppercase is 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.",
    },
    "csv": {
        "reader": "csv.reader(f) reads a CSV file row by row, giving each row as a list of strings. Open the file with newline=''.",
        "writer": "csv.writer(f) writes rows to a CSV file with writer.writerow([...]).",
        "DictReader": "csv.DictReader(f) reads each row as a dict using the header row as keys.",
        "DictWriter": "csv.DictWriter(f, fieldnames=[...]) writes dicts as rows; call writeheader() first.",
    },
    "copy": {
        "copy": "copy.copy(x) makes a shallow copy: a new outer object, but things inside are shared.",
        "deepcopy": "copy.deepcopy(x) copies an object and everything inside it, so changing the copy never affects the original.",
    },
    "turtle": {
        "forward": "turtle.forward(100) moves the turtle 100 steps the way it faces, drawing a line if the pen is down.",
        "backward": "turtle.backward(50) moves the turtle back without turning around.",
        "left": "turtle.left(90) turns the turtle left by 90 degrees.",
        "right": "turtle.right(90) turns the turtle right by 90 degrees.",
        "penup": "turtle.penup() lifts the pen so moving does not draw. pendown() puts it back.",
        "pendown": "turtle.pendown() puts the pen down so moving draws again.",
        "color": "turtle.color('red') sets the pen and fill color. turtle.color('red', 'yellow') sets them separately.",
        "goto": "turtle.goto(x, y) moves the turtle straight to that point; (0, 0) is the middle of the window.",
        "circle": "turtle.circle(50) draws a circle with radius 50. circle(50, 180) draws half a circle.",
        "begin_fill": "Call turtle.begin_fill() before drawing a shape and turtle.end_fill() after to fill it with the fill color.",
        "speed": "turtle.speed(0) makes drawing as fast as possible; 1 is slowest and 10 is fast.",
        "done": "turtle.done() keeps the window open after drawing, so it does not close right away.",
        "bgcolor": "turtle.bgcolor('black') sets the window's background color.",
        "pensize": "turtle.pensize(5) makes the drawn lines 5 pixels thick.",
        "hideturtle": "turtle.hideturtle() hides the arrow so only your drawing shows.",
        "write": "turtle.write('Hi', font=('Arial', 16, 'normal')) writes text where the turtle is.",
    },
}

MODULES.update({
    "glob": {
        "glob": "glob.glob('*.txt') returns a list of file paths matching a pattern. Use '**/*.txt' with recursive=True to search subfolders.",
    },
    "zipfile": {
        "ZipFile": "zipfile.ZipFile('a.zip') opens a zip file; use .extractall(folder) to unzip or open it with 'w' and .write(path) to add files.",
    },
    "hashlib": {
        "sha256": "hashlib.sha256(data).hexdigest() gives the SHA-256 fingerprint of some bytes, used to check files are the same or unchanged.",
        "md5": "hashlib.md5(data).hexdigest() gives an MD5 hash. It is fine for spotting changed files but not safe for passwords or security.",
    },
    "uuid": {
        "uuid4": "uuid.uuid4() makes a random unique ID like 'f47ac10b-58cc-...', handy for naming things that must never clash.",
    },
    "secrets": {
        "token_hex": "secrets.token_hex(16) makes a random, secure hex string, good for tokens and keys.",
        "choice": "secrets.choice(items) picks a random item in a way that is safe for passwords and codes, unlike random.choice.",
        "randbelow": "secrets.randbelow(n) gives a secure random whole number from 0 up to n - 1.",
    },
    "base64": {
        "b64encode": "base64.b64encode(data) turns bytes into Base64 text-safe bytes, used to send images or files inside JSON or email. b64decode turns it back.",
        "b64decode": "base64.b64decode(text) turns Base64 text back into the original bytes.",
    },
    "textwrap": {
        "wrap": "textwrap.wrap(text, width=40) splits long text into a list of lines no longer than 40 characters.",
        "dedent": "textwrap.dedent(text) removes the common indentation from every line, handy for triple-quoted strings inside functions.",
    },
    "calendar": {
        "month": "calendar.month(2025, 6) returns a text calendar of that month you can print.",
        "isleap": "calendar.isleap(year) is True if that year is a leap year.",
    },
    "platform": {
        "system": "platform.system() returns 'Windows', 'Darwin' (macOS) or 'Linux'.",
        "python_version": "platform.python_version() returns the Python version as a string like '3.12.4'.",
    },
    "webbrowser": {
        "open": "webbrowser.open(url) opens a web page in the default browser.",
    },
    "timeit": {
        "timeit": "timeit.timeit('code', number=1000) runs a small piece of code many times and returns the total seconds, for comparing which version is faster.",
    },
    "getpass": {
        "getpass": "getpass.getpass('Password: ') reads typed text without showing it on screen.",
    },
    "sqlite3": {
        "connect": "sqlite3.connect('app.db') opens (or creates) a small database file. Use cursor.execute with ? placeholders for values, and commit() to save.",
    },
    "threading": {
        "Thread": "threading.Thread(target=func).start() runs func in a background thread; .join() waits for it to finish.",
        "Lock": "threading.Lock() stops two threads from changing the same data at once; use it with `with lock:`.",
    },
    "queue": {
        "Queue": "queue.Queue() is a thread-safe first-in first-out queue with put() and get(), perfect for passing work between threads.",
    },
    "heapq": {
        "heappush": "heapq.heappush(heap, x) adds x to a list kept as a min-heap, so the smallest item is always at heap[0].",
        "heappop": "heapq.heappop(heap) removes and returns the smallest item from a heap list.",
        "nlargest": "heapq.nlargest(3, items) returns the 3 biggest items without sorting everything. nsmallest does the opposite.",
    },
    "bisect": {
        "bisect_left": "bisect.bisect_left(sorted_list, x) finds where x would go in a sorted list using binary search.",
        "insort": "bisect.insort(sorted_list, x) puts x into a sorted list at the right spot so it stays sorted.",
    },
    "operator": {
        "itemgetter": "operator.itemgetter('score') makes a function that pulls that key, handy as a sort key: sorted(rows, key=itemgetter('score')).",
        "attrgetter": "operator.attrgetter('age') makes a function that reads an attribute, useful as a sort key for objects.",
    },
    "contextlib": {
        "suppress": "contextlib.suppress(FileNotFoundError) used in a with block ignores that error, a short way to try something that may fail.",
        "contextmanager": "@contextlib.contextmanager turns a generator function into a context manager: code before yield runs on enter and after yield on exit.",
    },
    "tempfile": {
        "TemporaryDirectory": "tempfile.TemporaryDirectory() makes a temporary folder that is deleted when the with block ends.",
        "NamedTemporaryFile": "tempfile.NamedTemporaryFile() makes a temporary file with a real path that is removed when closed (by default).",
    },
    "fractions": {
        "Fraction": "fractions.Fraction(1, 3) stores exact fractions, so Fraction(1, 3) + Fraction(1, 6) gives Fraction(1, 2) with no rounding.",
    },
    "decimal": {
        "Decimal": "decimal.Decimal('0.1') stores decimals exactly, so Decimal('0.1') + Decimal('0.2') equals Decimal('0.3'). Pass strings, not floats.",
    },
    "socket": {
        "socket": "socket.socket() makes a network connection endpoint for low-level networking; most programs use requests or http libraries instead.",
        "gethostname": "socket.gethostname() returns the computer's network name.",
    },
    "unittest": {
        "TestCase": "unittest.TestCase is the base class for tests: write methods starting with test_ that use self.assertEqual and run with python -m unittest.",
    },
    "dataclasses": {
        "dataclass": "@dataclasses.dataclass writes __init__, __repr__ and __eq__ for a class from its annotated fields.",
        "field": "dataclasses.field(default_factory=list) gives each object its own new list as a default, avoiding the shared default problem.",
        "asdict": "dataclasses.asdict(obj) turns a dataclass object into a dictionary, handy before saving it as JSON.",
    },
    "enum": {
        "Enum": "enum.Enum is the base class for named constants: class Color(Enum): RED = 1. Use Color.RED, and Color.RED.name gives 'RED'.",
        "auto": "enum.auto() fills in enum values for you so you do not have to number them.",
    },
    "typing": {
        "Optional": "typing.Optional[int] means an int or None. In Python 3.10+ you can write int | None instead.",
        "Any": "typing.Any means any type at all, which turns off type checking for that value.",
        "Callable": "typing.Callable[[int], str] is the type of a function that takes an int and returns a str.",
    },
    "urllib.request": {
        "urlopen": "urllib.request.urlopen(url) downloads a web page with only the standard library; .read() gives the bytes. The requests package is easier.",
    },
    "urllib.parse": {
        "urlencode": "urllib.parse.urlencode({'q': 'cats'}) builds a safe query string like 'q=cats' for URLs.",
        "quote": "urllib.parse.quote('a b') makes text safe for a URL, giving 'a%20b'.",
    },
    "string.extra": {
        "Template": "string.Template('Hi $name').substitute(name='Sam') fills in $ placeholders, a simple way to make text from user templates.",
    },
    "logging": {
        "basicConfig": "logging.basicConfig(level=logging.INFO) sets up logging to show INFO messages and above, with an optional filename= to log to a file.",
        "getLogger": "logging.getLogger(__name__) gets a named logger for your module, so messages show where they came from.",
    },
    "argparse": {
        "ArgumentParser": "argparse.ArgumentParser() reads command-line options: add_argument('--count', type=int) then parse_args() gives args.count.",
    },
    "configparser": {
        "ConfigParser": "configparser.ConfigParser() reads and writes .ini settings files with [sections] and key = value lines.",
    },
    "pprint": {
        "pprint": "pprint.pprint(data) prints big nested dicts and lists neatly over several lines.",
    },
    "shlex": {
        "split": "shlex.split('cmd \"two words\"') splits a command line the way a shell would, keeping quoted parts together.",
    },
    "difflib": {
        "get_close_matches": "difflib.get_close_matches(word, options) finds the most similar strings, great for 'did you mean' suggestions.",
    },
    "struct": {
        "pack": "struct.pack('<hf', 1, 2.5) packs numbers into bytes in an exact layout, useful for files or talking to hardware.",
        "unpack": "struct.unpack('<hf', data) reads numbers back out of bytes using the same format string.",
    },
    "array": {
        "array": "array.array('i', [1, 2, 3]) stores numbers of one type compactly, using less memory than a list.",
    },
    "atexit": {
        "register": "atexit.register(func) runs func when the program exits normally, good for saving or cleanup.",
    },
    "signal": {
        "signal": "signal.signal(signal.SIGINT, handler) lets you run your own function when the program gets a signal like Ctrl+C.",
    },
    "http.server": {
        "HTTPServer": "http.server.HTTPServer is a basic web server class. From a terminal, python -m http.server 8000 serves the files in a folder at localhost:8000.",
    },
    "tkinter": {
        "Tk": "tkinter.Tk() makes the main window. Add widgets to it and call root.mainloop() to show it and react to clicks.",
        "Label": "tkinter.Label(root, text='Hi') shows text or an image in a tkinter window. Call .pack() or .grid() to place it.",
        "Button": "tkinter.Button(root, text='Go', command=func) makes a button that calls func when clicked.",
        "Entry": "tkinter.Entry(root) is a one-line text box; read what was typed with entry.get().",
        "Canvas": "tkinter.Canvas(root, width=400, height=300) is a drawing area with create_line, create_rectangle, create_oval and create_text.",
        "Frame": "tkinter.Frame(root) is a container for grouping widgets, so you can lay out sections of a window.",
        "messagebox": "tkinter.messagebox.showinfo('Title', 'Text') pops up a message box. There are also showerror and askyesno.",
        "StringVar": "tkinter.StringVar() holds text that widgets can share; set it with .set() and read it with .get(), and a Label with textvariable= updates by itself.",
    },
})


def check(obj, name):
    if not hasattr(obj, name):
        raise SystemExit(f"{obj!r} has no {name!r}; fix the table")


entries, seen, seen_k = [], set(), set()


def add(tag, qs, a):
    keep = []
    for q in qs:
        k = keyset(q)
        if norm(q) in seen or (len(k) >= 2 and k in seen_k) or q in keep:
            continue
        keep.append(q)
    if len(keep) < 2:
        return
    for q in keep:
        seen.add(norm(q))
        if len(keyset(q)) >= 2:
            seen_k.add(keyset(q))
    if len(a) > 420:
        raise SystemExit(f"answer too long for {qs[0]}")
    entries.append((tag, keep, a))


def main():
    w, k = existing(OUT)
    seen.update(w)
    seen_k.update(k)
    for f, a in BUILTINS.items():
        check(builtins, f)
        add("coding.python.builtins", [f"what does {f} do in python", f"python {f} function",
                                       f"how do i use {f}() in python"], a)
    for m, a in STR.items():
        check(str, m)
        add("coding.python.strings", [f"what does {m} do to a string in python", f"python string {m} method",
                                      f"how do i use .{m}() on a string"], a)
    for m, a in LIST.items():
        check(list, m)
        add("coding.python.lists", [f"what does list.{m} do in python", f"python list {m} method",
                                    f"how do i use .{m}() on a list"], a)
    for m, a in DICT.items():
        check(dict, m)
        add("coding.python.dicts", [f"what does dict.{m} do in python", f"python dictionary {m} method",
                                    f"how do i use .{m}() on a dictionary"], a)
    for m, a in SET.items():
        check(set, m)
        add("coding.python.sets", [f"what does set.{m} do in python", f"python set {m}",
                                   f"how do i get the {m.replace('_', ' ')} of two sets"], a)
    check(set, "remove")
    add("coding.python.sets", ["what does set.remove do in python", "remove vs discard python set"], SET_REMOVE)
    for mod, funcs in MODULES.items():
        mod = mod.replace(".extra", "")
        try:
            module = importlib.import_module(mod)
            if mod == "tkinter":
                importlib.import_module("tkinter.messagebox")
        except ImportError:  # turtle needs tkinter, which some servers lack: check the source instead
            from importlib.util import find_spec
            spec = find_spec(mod.split(".")[0])
            if spec is None:  # tkinter may be missing on build servers; these names are from the tkinter docs
                print(f"note: {mod} is not installed here, names not checked", file=sys.stderr)
                src = None
            else:
                src = open(spec.origin, encoding="utf-8").read()
            module = None
        for f, a in funcs.items():
            if module is not None:
                check(module, f)
            elif src is None:
                pass
            elif f"def {f}(" not in src and f"'{f}'" not in src and f"class {f}" not in src and f"import {f}" not in src:
                raise SystemExit(f"{mod} has no {f}")
            full = f"{mod}.{f}"
            qs = [f"what does {full.lower()} do in python", f"python {mod} {f.lower().replace('_', ' ')}",
                  f"how do i use {full.lower()}"]
            if mod == "turtle":
                qs = [f"what does turtle.{f} do", f"python turtle {f.replace('_', ' ')}",
                      f"how do i use {f} in turtle"]
            add(f"coding.python.stdlib", qs, a)
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write("# Generated by tools/knowledge/gen/coding_python_api.py (hand-written answers based on docs.python.org).\n")
        fh.write("# Do not edit by hand.\n")
        tag = None
        for t, qs, a in entries:
            if t != tag:
                fh.write(f"# tag: {t}\n")
                tag = t
            fh.write(" | ".join(qs) + " => " + a + "\n")
    print(f"wrote {len(entries)} entries to {OUT}")


if __name__ == "__main__":
    main()
