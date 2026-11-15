"""Builds data/coding/gen_arduino_ref.txt from the official Arduino language reference
(github.com/arduino/reference-en, CC BY-SA 3.0). Each page gives what a function or keyword does,
its syntax, what it takes and what it returns, reworded into short kid-friendly answers.
Needs network access the first time; pages are cached in .cache/arduino/."""
import os
import re
import sys
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
KNOW = os.path.dirname(HERE)
sys.path.insert(0, KNOW)
sys.path.insert(0, HERE)
from check_data import keyset, norm  # noqa: E402
from coding_common import existing  # noqa: E402

BASE = "https://raw.githubusercontent.com/arduino/reference-en/master/Language/"
CACHE = os.path.join(KNOW, ".cache", "arduino")
OUT = os.path.join(KNOW, "data", "coding", "gen_arduino_ref.txt")

FUNCS = {
    "Digital IO": "digitalRead digitalWrite pinMode",
    "Analog IO": "analogRead analogReadResolution analogReference analogWrite analogWriteResolution",
    "Advanced IO": "noTone pulseIn pulseInLong shiftIn shiftOut tone",
    "Time": "delay delayMicroseconds micros millis",
    "Math": "abs constrain map max min pow sq sqrt",
    "Trigonometry": "cos sin tan",
    "Characters": "isAlpha isAlphaNumeric isAscii isControl isDigit isGraph isHexadecimalDigit isLowerCase "
                  "isPrintable isPunct isSpace isUpperCase isWhitespace",
    "Random Numbers": "random randomSeed",
    "Bits and Bytes": "bit bitClear bitRead bitSet bitWrite highByte lowByte",
    "External Interrupts": "attachInterrupt detachInterrupt digitalPinToInterrupt",
    "Interrupts": "interrupts noInterrupts",
}
OBJS = {
    "Communication/Serial": "available availableForWrite begin end find findUntil flush parseFloat parseInt peek "
                            "print println read readBytes readBytesUntil readString readStringUntil setTimeout "
                            "write serialEvent ifSerial",
    "Communication/Wire": "begin end requestFrom beginTransmission endTransmission write available read setClock "
                          "onReceive onRequest setWireTimeout clearWireTimeoutFlag getWireTimeoutFlag",
    "Communication/SPI": "begin end beginTransaction endTransaction transfer usingInterrupt SPISettings",
    "USB/Keyboard": "keyboardBegin keyboardEnd keyboardPress keyboardPrint keyboardPrintln keyboardRelease "
                    "keyboardReleaseAll keyboardWrite",
    "USB/Mouse": "mouseBegin mouseClick mouseEnd mouseIsPressed mouseMove mousePress mouseRelease",
}
TOPS = ["Communication/Serial", "Communication/Wire", "Communication/SPI", "Communication/stream",
        "USB/Keyboard", "USB/Mouse"]
VARS = {
    "Constants": "highLow inputOutputPullup ledbuiltin trueFalse floatingPointConstants integerConstants",
    "Conversion": "byteCast charCast floatCast intCast longCast unsignedIntCast unsignedLongCast wordcast",
    "Data Types": "array bool boolean byte char double float int long short size_t string stringObject "
                  "unsignedChar unsignedInt unsignedLong void word",
    "Variable Scope & Qualifiers": "const scope static volatile",
    "Utilities": "PROGMEM sizeof",
}
STRUCT = {
    "Sketch": "setup loop",
    "Control Structure": "break continue doWhile else for goto if return switchCase while",
    "Further Syntax": "define include blockComment singleLineComment semicolon curlyBraces",
}
# Words people say for a page name that is not a plain keyword.
SAY = {
    "highLow": "high and low", "inputOutputPullup": "input output and input_pullup", "ledbuiltin": "led_builtin",
    "trueFalse": "true and false", "floatingPointConstants": "floating point constants",
    "integerConstants": "integer constants", "byteCast": "byte()", "charCast": "char()", "floatCast": "float()",
    "intCast": "int()", "longCast": "long()", "unsignedIntCast": "unsigned int()",
    "unsignedLongCast": "unsigned long()", "wordcast": "word()", "stringObject": "the String object",
    "string": "char array strings", "unsignedChar": "unsigned char", "unsignedInt": "unsigned int",
    "unsignedLong": "unsigned long", "doWhile": "do while", "switchCase": "switch case",
    "blockComment": "block comments", "singleLineComment": "single line comments",
    "curlyBraces": "curly braces", "define": "#define", "include": "#include", "scope": "variable scope",
    "ifSerial": "if (Serial)",
}
DATED = re.compile(r"\b(currently|right now|these days|nowadays|the current|at the moment|today's)\b", re.I)


def fetch(path):
    local = os.path.join(CACHE, path.replace("/", "__") + ".adoc")
    if not os.path.exists(local):
        os.makedirs(CACHE, exist_ok=True)
        try:
            with urllib.request.urlopen(BASE + urllib.parse.quote(path) + ".adoc", timeout=30) as r:
                open(local, "wb").write(r.read())
        except Exception as ex:  # noqa: BLE001
            print("skip", path, ex, file=sys.stderr)
            open(local, "w").write("")
    return open(local, encoding="utf-8").read()


def section(text, name):
    m = re.search(r"===\s*" + name + r"\s*\n(.*?)(?=\n\[float\]|\n===|\n--\s*\n|\Z)", text, re.S)
    return m.group(1).strip() if m else ""


def plain(s):
    s = re.sub(r"\[%hardbreaks\]", " ", s)
    s = re.sub(r"https?://\S+?\[([^\]]*)\]", r"\1", s)
    s = re.sub(r"link:[^\[]*\[([^\]]*)\]", r"\1", s)
    s = re.sub(r"\^\]", "]", s)
    s = re.sub(r"\[\.?\w*\]#([^#]*)#", r"\1", s)
    s = re.sub(r"(\d+)\^(\d+)\^?", r"\1 to the power of \2", s)
    s = s.replace(" +\n", " ").replace("\n", " ").replace("^", "")
    s = re.sub(r"\*([^*\s][^*]*)\*", r"\1", s)
    s = re.sub(r"(?<![\w`])_([A-Za-z][^_]*?)_(?![\w`])", r"\1", s)
    s = s.replace("_Serial_", "Serial").replace("link:", "")
    s = re.sub(r"\s+", " ", s).strip()
    s = s.replace("—", ", ").replace("–", " to ").replace(" -- ", ", ")
    return s


def sentences(s, limit=300):
    s = re.sub(r"\bthe current (program|sketch)", r"the \1", s)
    s = s.replace("e.g.", "for example").replace("i.e.", "that is").replace("etc.", "and so on.")
    parts = re.split(r"(?<=[.!])\s+(?=[A-Z`(])", s)
    out = ""
    for p in parts:
        if DATED.search(p) or p.rstrip().endswith(":") or re.search(r"\b(See|see|below|above|example|Example|visit|Please note|NOTE|This page|There's a description)\b", p) or "Note:" in p \
                or "=>" in p or "||" in p:
            break
        if len(out) + len(p) + 1 > limit:
            break
        out = (out + " " + p).strip()
    return out


CALL = [""]


def build(text, nm):
    desc = plain(section(text, "Description"))
    a = sentences(desc)
    if not a:
        return None, None, (None, None)
    a = re.sub(r"^(This|The) function\b", "`" + str(CALL[0]) + "`", a)
    a = re.sub(r"^Analy[sz]e if a char", "`" + str(CALL[0]) + "` checks if a char", a)
    first = a.split()[0]
    if CALL[0] is None:
        pass
    elif re.match(r"`?" + re.escape(nm) + r"(\(\))?`?$", first, re.I):
        a = "`" + CALL[0] + "`" + a[len(first):]
    elif first[0].isupper() and first.endswith("s") and first not in ("This", "Arduino", "Allows", "Its"):
        a = "`" + CALL[0] + "` " + first.lower() + a[len(first):]
    if a[0].islower() and not a.startswith("`"):
        a = a[0].upper() + a[1:]
    syn = plain(section(text, "Syntax")).split("`")
    syn = [x for i, x in enumerate(syn) if i % 2 == 1]
    ret = plain(section(text, "Returns"))
    par = plain(section(text, "Parameters"))
    return a, syn, (ret, par)


entries, seen, seen_k, seen_a = [], set(), set(), set()


def add(tag, qs, a):
    if not a or len(a) < 15 or len(a) > 600 or not (a[0].isupper() or a[0] in "`#"):
        return
    if a[0] in "`#":
        a = "In Arduino, " + a
    if not a.endswith((".", ".)")):
        a += "."
    if a in seen_a:
        return
    keep = []
    for q in qs:
        q = re.sub(r"\s+", " ", q.lower()).strip()
        k = keyset(q)
        if not q or "?" in q or norm(q) in seen or (len(k) >= 2 and k in seen_k) or q in keep:
            continue
        keep.append(q)
    if len(keep) < 2:
        return
    for q in keep:
        seen.add(norm(q))
        if len(keyset(q)) >= 2:
            seen_k.add(keyset(q))
    seen_a.add(a)
    entries.append((tag, keep, a))


def func_entries(tag, path, nm, call):
    text = fetch(path)
    if not text:
        return
    CALL[0] = call
    a, syn, (ret, par) = build(text, nm)
    if not a:
        return
    low = nm.lower()
    if not a.endswith((".", ".)")):
        a += "."
    s = ""
    if syn and len(syn[0]) < 70 and len(a) + len(syn[0]) < 390:
        s = f" Use it like `{syn[0]}`."
    add(tag, [f"what does {low} do in arduino", f"arduino {low}", f"how do i use {low} on arduino",
              f"{low} arduino explained"], a + s)
    ret = sentences(ret, 250)
    if ret and "* " not in ret and not re.match(r"(`|[Dd]ata type|[Rr]eturns|.*\breturns?\b)", ret) and len(ret) < 250 and not DATED.search(ret) and "=>" not in ret:
        r = ret.rstrip(".")
        if r.lower() in ("nothing", "none"):
            ans = f"`{call}` returns nothing, it just does its job."
        else:
            ans = f"`{call}` returns {r[0].lower() + r[1:]}." if not r.startswith("`") else f"`{call}` returns {r}."
        add(tag, [f"what does {low} return in arduino", f"arduino {low} return value"], ans)
    par = par.replace("`Serial`: serial port object.", "").strip()
    par = sentences(par, 330)
    if par and not par.endswith("."):
        par += "."
    if par and 20 < len(par) and not re.search(r"(\* |- `|^- )", par):
        add(tag, [f"what are the parameters of {low} arduino", f"what goes inside {low} arduino"],
            f"`{call}` takes: {par}" if par[0] == "`" else f"For `{call}`: {par}")


def main():
    w, k = existing(OUT)
    seen.update(w)
    seen_k.update(k)
    for cat, names in FUNCS.items():
        for n in names.split():
            func_entries("coding.arduino.reference", f"Functions/{cat}/{n}", n, n + "()")
    for top in TOPS:
        text = fetch("Functions/" + top)
        CALL[0] = top.rsplit("/", 1)[1].capitalize()
        if text:
            a, _s, _r = build(text, top)
            nm = top.rsplit("/", 1)[1].capitalize() if top.endswith("stream") else top.rsplit("/", 1)[1]
            add("coding.arduino.reference", [f"what is {nm.lower()} in arduino", f"arduino {nm.lower()} library",
                                             f"{nm.lower()} object arduino"], a)
    for obj, names in OBJS.items():
        base = obj.rsplit("/", 1)[1]
        for n in names.split():
            short = re.sub(r"^(keyboard|mouse)", "", n)
            short = short[0].lower() + short[1:]
            if n == "ifSerial":
                call, label = "if (Serial)", "if serial"
            elif n == "serialEvent":
                call, label = "serialEvent()", "serialevent"
            elif n == "SPISettings":
                call, label = "SPISettings", "spisettings"
            else:
                call, label = f"{base}.{short}()", f"{base.lower()}.{short.lower()}"
            func_entries("coding.arduino.reference", f"Functions/{obj}/{n}", label, call)
    for cat, names in list(VARS.items()) + list(STRUCT.items()):
        root = "Variables" if cat in VARS else "Structure"
        for n in names.split():
            text = fetch(f"{root}/{cat}/{n}")
            if not text:
                continue
            CALL[0] = None
            a, _s, _r = build(text, n)
            if not a:
                continue
            say = SAY.get(n, n)
            add("coding.arduino.reference", [f"what is {say} in arduino", f"arduino {say}",
                                             f"how does {say} work in arduino code"], a)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("# Generated by gen/coding_arduino_ref.py from the Arduino language reference "
                "(github.com/arduino/reference-en, CC BY-SA 3.0). Do not edit by hand.\n")
        tag = None
        for t, qs, a in entries:
            if t != tag:
                f.write(f"# tag: {t}\n")
                tag = t
            f.write(" | ".join(qs) + " => " + a + "\n")
    print(len(entries), "entries ->", OUT)


if __name__ == "__main__":
    main()
