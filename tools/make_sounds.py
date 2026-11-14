#!/usr/bin/env python3
"""Synthesizes Ace V4's sound set (mono, 44.1 kHz, 16-bit WAV).

Run from the repo root:  python3 tools/make_sounds.py
Every sound is made from math here, so there are no licensing worries.
The app adds stereo pan, random pitch and fades when it plays them.
"""
import os
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Ace", "Resources", "Sounds")
rng = np.random.default_rng(7)


def t_axis(seconds):
    return np.arange(int(SR * seconds)) / SR


def env(n, attack=0.01, release=0.2, curve=2.0):
    """Attack/release envelope over n samples (times in seconds)."""
    e = np.ones(n)
    a = max(1, int(attack * SR))
    r = max(1, int(release * SR))
    a = min(a, n)
    r = min(r, n)
    e[:a] = np.linspace(0, 1, a) ** 0.5
    e[n - r:] *= np.linspace(1, 0, r) ** curve
    return e


def sweep(f0, f1, seconds, shape="exp"):
    """Sine whose frequency glides from f0 to f1."""
    n = int(SR * seconds)
    if shape == "exp":
        f = f0 * (f1 / f0) ** np.linspace(0, 1, n)
    else:
        f = np.linspace(f0, f1, n)
    phase = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(phase)


def bell(freq, seconds, decay=4.0, partials=((1, 1.0), (2.01, 0.35), (3.02, 0.15), (4.2, 0.08))):
    t = t_axis(seconds)
    out = np.zeros_like(t)
    for mult, amp in partials:
        out += amp * np.sin(2 * np.pi * freq * mult * t) * np.exp(-decay * mult * t)
    return out


def lowpass(x, cutoff):
    """One-pole low-pass. cutoff may be a number or an array per sample."""
    cutoff = np.broadcast_to(np.asarray(cutoff, dtype=float), x.shape)
    alpha = 1 - np.exp(-2 * np.pi * cutoff / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += alpha[i] * (x[i] - acc)
        y[i] = acc
    return y


def place(buf, sig, at):
    i = int(at * SR)
    end = min(len(buf), i + len(sig))
    buf[i:end] += sig[: end - i]
    return buf


def finish(x, peak=0.85):
    x = x - np.mean(x)
    m = np.max(np.abs(x)) or 1.0
    x = x / m * peak
    # 3 ms fade in/out so nothing clicks
    f = int(0.003 * SR)
    x[:f] *= np.linspace(0, 1, f)
    x[-f:] *= np.linspace(1, 0, f)
    return x


def save(name, x):
    os.makedirs(OUT, exist_ok=True)
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(f"{name}.wav  {len(x) / SR:.2f}s")


# ---------------- the sounds ----------------

def orb_wake():
    """Rising glassy shimmer: the orb wakes up."""
    d = 1.0
    n = int(SR * d)
    buf = np.zeros(n)
    base = sweep(220, 660, d) * env(n, 0.25, 0.45)
    buf += 0.5 * base
    notes = [523.25, 659.25, 783.99, 1046.5, 1318.5]
    for i, f in enumerate(notes):
        place(buf, 0.35 * bell(f, 0.6, decay=5), 0.12 + i * 0.09)
    sparkle = rng.standard_normal(n) * env(n, 0.4, 0.4)
    buf += 0.05 * (sparkle - lowpass(sparkle, 3000))
    return finish(buf)


def eyes_pop():
    """Two quick bubbly pops as the eyes come out."""
    d = 0.4
    buf = np.zeros(int(SR * d))
    for at, f0 in ((0.0, 380), (0.11, 520)):
        n = int(SR * 0.12)
        pop = sweep(f0, f0 * 2.6, 0.12) * np.exp(-np.linspace(0, 6, n))
        place(buf, pop, at)
    return finish(buf, 0.8)


def blink():
    """Tiny soft tick for a blink."""
    d = 0.07
    n = int(SR * d)
    x = sweep(2200, 1200, d) * np.exp(-np.linspace(0, 9, n))
    return finish(x, 0.5)


def look_whir():
    """Short servo whir while the eyes glance around."""
    d = 0.26
    n = int(SR * d)
    t = t_axis(d)
    f = 300 + 180 * np.sin(np.pi * t / d)
    tone = np.sin(2 * np.pi * np.cumsum(f) / SR)
    buzz = np.sign(np.sin(2 * np.pi * np.cumsum(f * 2) / SR)) * 0.15
    x = (tone + buzz) * env(n, 0.04, 0.09)
    return finish(lowpass(x, 2500), 0.55)


def think_loop():
    """Calm hum that loops with no seam (all partials fit whole cycles in 2 s)."""
    d = 2.0
    t = t_axis(d)
    x = (0.6 * np.sin(2 * np.pi * 110 * t)
         + 0.3 * np.sin(2 * np.pi * 165 * t)
         + 0.18 * np.sin(2 * np.pi * 220 * t + 0.5 * np.sin(2 * np.pi * 1.0 * t))
         + 0.08 * np.sin(2 * np.pi * 440 * t) * (0.5 + 0.5 * np.sin(2 * np.pi * 2.0 * t)))
    x *= 0.8 + 0.2 * np.sin(2 * np.pi * 0.5 * t)
    x = x - np.mean(x)
    return x / np.max(np.abs(x)) * 0.6  # no fades: it has to loop cleanly


def success():
    """Bright three-note chime."""
    d = 0.9
    buf = np.zeros(int(SR * d))
    for i, f in enumerate((659.25, 830.61, 987.77)):
        place(buf, bell(f, 0.6, decay=4.5), i * 0.08)
    place(buf, 0.5 * bell(1318.5, 0.5, decay=6), 0.24)
    return finish(buf)


def alert():
    """Soft two-tone heads-up, not scary."""
    d = 0.7
    buf = np.zeros(int(SR * d))
    for at, f in ((0.0, 880.0), (0.18, 698.46)):
        n = int(SR * 0.4)
        tone = (np.sin(2 * np.pi * f * t_axis(0.4)) + 0.3 * np.sin(2 * np.pi * f * 2 * t_axis(0.4)))
        place(buf, tone * env(n, 0.01, 0.3), at)
    return finish(buf, 0.75)


def listen_start():
    d = 0.22
    n = int(SR * d)
    x = sweep(500, 1000, d) * env(n, 0.01, 0.08)
    x += 0.3 * sweep(1000, 2000, d) * env(n, 0.01, 0.08)
    return finish(x, 0.7)


def listen_stop():
    d = 0.22
    n = int(SR * d)
    x = sweep(1000, 500, d) * env(n, 0.01, 0.08)
    x += 0.3 * sweep(2000, 1000, d) * env(n, 0.01, 0.08)
    return finish(x, 0.7)


def type_tick():
    d = 0.03
    n = int(SR * d)
    noise = rng.standard_normal(n)
    x = (noise - lowpass(noise, 1800)) * np.exp(-np.linspace(0, 10, n))
    x += 0.4 * np.sin(2 * np.pi * 1600 * t_axis(d)) * np.exp(-np.linspace(0, 12, n))
    return finish(x, 0.4)


def greeting():
    """Warm little hello melody for the first open of the day."""
    d = 1.5
    buf = np.zeros(int(SR * d))
    melody = [(523.25, 0.0), (659.25, 0.16), (783.99, 0.32), (1046.5, 0.52)]
    for f, at in melody:
        place(buf, bell(f, 0.9, decay=3.2, partials=((1, 1.0), (2, 0.25), (3, 0.1))), at)
    pad_n = int(SR * 1.3)
    pad = (np.sin(2 * np.pi * 261.63 * t_axis(1.3)) + 0.5 * np.sin(2 * np.pi * 392.0 * t_axis(1.3)))
    place(buf, 0.25 * pad * env(pad_n, 0.3, 0.7), 0.1)
    return finish(buf)


def sleep_whoosh():
    """Soft falling whoosh as the eyes tuck back in."""
    d = 0.8
    n = int(SR * d)
    noise = rng.standard_normal(n)
    cutoff = np.geomspace(4000, 250, n)
    x = lowpass(noise, cutoff) * env(n, 0.15, 0.4)
    x += 0.25 * sweep(600, 200, d) * env(n, 0.1, 0.5)
    return finish(x, 0.6)


def send():
    """Quick upward swoosh when a message goes to Ace."""
    d = 0.25
    n = int(SR * d)
    noise = rng.standard_normal(n)
    cutoff = np.geomspace(600, 5000, n)
    x = lowpass(noise, cutoff) * env(n, 0.05, 0.12)
    x += 0.3 * sweep(400, 900, d) * env(n, 0.02, 0.12)
    return finish(x, 0.55)


SOUNDS = {
    "orb_wake": orb_wake, "eyes_pop": eyes_pop, "blink": blink, "look_whir": look_whir,
    "think_loop": think_loop, "success": success, "alert": alert, "listen_start": listen_start,
    "listen_stop": listen_stop, "type_tick": type_tick, "greeting": greeting,
    "sleep_whoosh": sleep_whoosh, "send": send,
}

if __name__ == "__main__":
    for name, fn in SOUNDS.items():
        save(name, fn())
