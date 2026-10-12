#!/usr/bin/env python3
"""สร้างเสียงเพลงพื้นหลังและเสียงเอฟเฟกต์ (สังเคราะห์เอง ไม่มีลิขสิทธิ์) -> sounds/*.ogg
ใช้: python3 tools/gen_audio.py   (ต้องมี numpy และ ffmpeg)"""
import numpy as np, subprocess, os, wave, tempfile

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "sounds")
rng = np.random.default_rng(7)

def t_of(d): return np.arange(int(SR * d)) / SR
def midi(n): return 440.0 * 2 ** ((n - 69) / 12)
def env(n, a=0.005, r=0.08):
    e = np.ones(n); na = max(1, int(a * SR)); nr = max(1, int(r * SR))
    e[:na] = np.linspace(0, 1, na); e[-nr:] *= np.linspace(1, 0, nr)
    return e
def square(f, t, duty=0.5): return np.where(((f * t) % 1.0) < duty, 1.0, -1.0)
def saw(f, t): return 2 * ((f * t) % 1.0) - 1
def tri(f, t): return 2 * np.abs(2 * ((f * t) % 1.0) - 1) - 1
def sine(f, t): return np.sin(2 * np.pi * f * t)
def lowpass(x, k):
    y = np.copy(x); a = 1 / k
    for i in range(1, len(x)): y[i] = y[i - 1] + a * (x[i] - y[i - 1])
    return y

def save(name, x, gain=0.9):
    x = x / max(1e-9, np.max(np.abs(x))) * gain
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f: p = f.name
    with wave.open(p, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", p, "-c:a", "libvorbis", "-q:a", "4",
                    os.path.join(OUT, name + ".ogg")], check=True)
    os.remove(p)

# ------------------------------------------------------------- music
def music():
    bpm = 138; beat = 60 / bpm; bars = 16; total = bars * 4 * beat
    n = int(total * SR); out = np.zeros(n + SR)
    def add(start, x):
        i = int(start * SR); out[i:i + len(x)] += x[:len(out) - i]
    # Am F C G  (แต่ละคอร์ด 1 ห้อง) x 4
    prog = [(57, [69, 72, 76]), (53, [65, 69, 72]), (48, [67, 72, 76]), (55, [67, 71, 74])]
    mel = [  # ทำนองสั้น ๆ 16 โน้ต/ห้อง แบบ 8th notes (offset จากคอร์ด)
        [0, 3, 7, 3, 12, 7, 3, 7], [0, 4, 7, 4, 12, 9, 7, 4],
        [0, 4, 7, 12, 7, 4, 7, 4], [0, 4, 7, 11, 14, 11, 7, 4]]
    for b in range(bars):
        root, ch = prog[b % 4]
        t0 = b * 4 * beat
        # เบส (เล่นจังหวะ 8th)
        for k in range(8):
            d = beat / 2
            tt = t_of(d)
            f = midi(root - 12 + (12 if k % 4 == 3 else 0))
            add(t0 + k * d, 0.55 * square(f, tt, 0.4) * env(len(tt), 0.003, 0.05))
        # คอร์ดสั้น ๆ ตีจังหวะ off-beat
        for k in range(4):
            tt = t_of(beat * 0.4)
            x = sum(0.12 * square(midi(m), tt, 0.25) for m in ch) * env(len(tt), 0.004, 0.12)
            add(t0 + k * beat + beat * 0.5, x)
        # ทำนองหลัก (ท่อนที่ 2 และ 4 ของทุก 4 ห้องใช้ออกเสียงสูงขึ้น)
        if (b // 4) % 2 == 1 or b % 4 in (2, 3):
            pat = mel[b % 4]
            for k, off in enumerate(pat):
                d = beat / 2; tt = t_of(d)
                f = midi(ch[0] + 12 + off - 12 + (0 if off < 12 else 0))
                add(t0 + k * d, 0.30 * tri(f * 2, tt) * env(len(tt), 0.004, 0.06))
        else:  # อาร์เปจจิโอเบา ๆ
            for k in range(8):
                d = beat / 2; tt = t_of(d)
                f = midi(ch[k % 3] + 12)
                add(t0 + k * d, 0.16 * square(f, tt, 0.25) * env(len(tt), 0.003, 0.07))
        # กลอง
        for k in range(4):
            tt = t_of(0.16); kick = sine(110 * np.exp(-tt * 18) * 1.0 + 40, tt) * np.exp(-tt * 14)
            kick = np.sin(2 * np.pi * np.cumsum(60 + 120 * np.exp(-tt * 30)) / SR) * np.exp(-tt * 13)
            add(t0 + k * beat, 0.9 * kick)
            if k in (1, 3):
                ts = t_of(0.14); sn = (rng.standard_normal(len(ts)) * 0.6 + sine(190, ts) * 0.4) * np.exp(-ts * 22)
                add(t0 + k * beat, 0.45 * sn)
        for k in range(8):
            th = t_of(0.04); hh = rng.standard_normal(len(th)) * np.exp(-th * 90)
            add(t0 + k * beat / 2 + (0 if k % 2 == 0 else 0), (0.16 if k % 2 else 0.1) * hh)
    # ทำให้วนต่อเนื่อง: เอาส่วนหางไปทับหัว
    tail = out[n:]; out = out[:n].copy(); out[:len(tail)] += tail[:n]
    return out

def whoosh(d, f0, f1):
    t = t_of(d); n = rng.standard_normal(len(t))
    f = np.linspace(f0, f1, len(t))
    ph = 2 * np.pi * np.cumsum(f) / SR
    return (n * 0.5 + np.sin(ph) * 0.5) * np.sin(np.pi * t / d) ** 1.5

def sfx():
    # เก็บไอเท็ม: อาร์เปจจิโอขึ้น
    x = np.concatenate([tri(midi(m), t_of(0.09)) * env(int(0.09 * SR), 0.003, 0.04) for m in [72, 76, 79, 84, 88]])
    save("item", x)
    # โล่พัง
    t = t_of(0.5); nz = lowpass(rng.standard_normal(len(t)), 3) * np.exp(-t * 9)
    th = sine(90 * np.exp(-t * 4) + 40, t) * np.exp(-t * 8)
    save("shield_break", nz * 0.7 + th)
    # พุ่ง (boost)
    save("boost", whoosh(0.9, 200, 1800))
    # กระโดดสูง (boing)
    t = t_of(0.45); f = 260 + 520 * (1 - np.exp(-t * 9)); vib = 1 + 0.03 * np.sin(2 * np.pi * 22 * t)
    save("highjump", np.sin(2 * np.pi * np.cumsum(f * vib) / SR) * np.exp(-t * 4) * 0.8)
    # แตรรถ
    t = t_of(0.5); x = (square(392, t, 0.45) + square(494, t, 0.45)) * 0.35
    x = lowpass(x, 2) * env(len(t), 0.01, 0.12)
    save("horn", x)
    # นกหวีดครู
    t = t_of(0.7); trill = 1 + 0.015 * np.sin(2 * np.pi * 38 * t)
    x = np.sin(2 * np.pi * np.cumsum(2750 * trill) / SR) * 0.6 + rng.standard_normal(len(t)) * 0.06
    x *= env(len(t), 0.02, 0.15) * (0.75 + 0.25 * (np.sin(2 * np.pi * 38 * t) > 0))
    save("whistle", x)
    # กดปุ่ม
    t = t_of(0.07); save("click", square(880, t) * env(len(t), 0.002, 0.04) * 0.5)
    # นับถอยหลัง / ออกวิ่ง
    t = t_of(0.18); save("beep", sine(660, t) * env(len(t), 0.005, 0.08))
    t = t_of(0.45); save("go", (square(880, t, 0.5) * 0.5 + sine(1320, t) * 0.5) * env(len(t), 0.005, 0.2))
    # จบเกม
    x = np.concatenate([tri(midi(m), t_of(0.22)) * env(int(0.22 * SR), 0.01, 0.1) for m in [67, 64, 60, 55]])
    save("gameover", x)
    # สลับเลน (ลมวูบ)
    save("swish", whoosh(0.16, 900, 400) * 0.5)
    # ชนจนล้ม
    t = t_of(0.5); crash = (rng.standard_normal(len(t)) * np.exp(-t * 8) + sine(70 * np.exp(-t * 3) + 35, t)) * 0.9
    save("crash", crash)

if __name__ == "__main__":
    save("music", music(), 0.8)
    sfx()
    print("done")
