"""Sustained whistle WAV üretici.

Modern pea-less koruyucu düdük tınısını taklit eder: 2.8kHz temel + 3.5kHz
ikinci ses + ufak tremolo + hafif vibrato. Sürekli ('feeeeeeeeee') ses,
loop edilince kesintisiz duyulur.
"""

import math
import struct
import sys
from pathlib import Path

SAMPLE_RATE = 44100
DURATION_SEC = 3.0  # 3 sn segment, loop'la sonsuz uzar
FREQ_PRIMARY = 2800.0
FREQ_SECONDARY = 3500.0
TREMOLO_HZ = 6.5  # hafif şiddet titremesi
TREMOLO_DEPTH = 0.15  # %15 amplitude swing
VIBRATO_HZ = 5.0
VIBRATO_DEPTH_HZ = 8.0  # ±8Hz pitch swing
PEAK_AMPLITUDE = 0.92  # clipping marjı


def synth_sample(t: float) -> float:
    """Tek bir sample değeri üretir (-1..1)."""
    vib = VIBRATO_DEPTH_HZ * math.sin(2 * math.pi * VIBRATO_HZ * t)
    f1 = FREQ_PRIMARY + vib
    f2 = FREQ_SECONDARY + vib * 1.25

    s = 0.7 * math.sin(2 * math.pi * f1 * t)
    s += 0.4 * math.sin(2 * math.pi * f2 * t)

    # Tremolo
    trem = 1.0 - TREMOLO_DEPTH * (1 - math.sin(2 * math.pi * TREMOLO_HZ * t)) / 2

    return s * trem * PEAK_AMPLITUDE / 1.1  # normalize


def write_wav(path: Path) -> None:
    n = int(SAMPLE_RATE * DURATION_SEC)
    data = bytearray()
    for i in range(n):
        t = i / SAMPLE_RATE
        v = synth_sample(t)
        # 16-bit PCM
        sample = max(-1.0, min(1.0, v))
        data += struct.pack("<h", int(sample * 32767))

    data_size = len(data)
    file_size = 36 + data_size

    with open(path, "wb") as f:
        # RIFF header
        f.write(b"RIFF")
        f.write(struct.pack("<I", file_size))
        f.write(b"WAVE")
        # fmt chunk
        f.write(b"fmt ")
        f.write(struct.pack("<I", 16))         # fmt chunk size
        f.write(struct.pack("<H", 1))           # PCM
        f.write(struct.pack("<H", 1))           # mono
        f.write(struct.pack("<I", SAMPLE_RATE))
        f.write(struct.pack("<I", SAMPLE_RATE * 2))  # byte rate (mono * 2 byte)
        f.write(struct.pack("<H", 2))           # block align
        f.write(struct.pack("<H", 16))          # bits per sample
        # data chunk
        f.write(b"data")
        f.write(struct.pack("<I", data_size))
        f.write(data)

    print(f"OK: {path} ({path.stat().st_size:,} bytes, {DURATION_SEC}s)")


if __name__ == "__main__":
    out = Path(sys.argv[1] if len(sys.argv) > 1
               else "assets/audio/whistle_3khz.wav")
    out.parent.mkdir(parents=True, exist_ok=True)
    write_wav(out)
