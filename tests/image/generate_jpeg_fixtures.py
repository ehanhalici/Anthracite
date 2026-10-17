#!/usr/bin/env python3
"""Regenerate synthetic JPEG regression data; encoders are not needed by CTest."""

import argparse
from pathlib import Path
import shutil
import struct
import subprocess

DIMENSIONS = ((1, 1), (17, 19), (32, 16), (31, 27))
VARIANTS = {
    "444": ["-sample", "1x1,1x1,1x1"],
    "422": ["-sample", "2x1,1x1,1x1"],
    "420": [],
    "440": ["-sample", "1x2,1x1,1x1"],
    "411": ["-sample", "4x1,1x1,1x1"],
    "441": ["-sample", "1x4,1x1,1x1"],
    "gray": ["-grayscale"],
    "gray22": ["-grayscale", "-sample", "2x2"],
    "rgb": ["-rgb"],
    "restart1": ["-restart", "1B"],
    "restart2": ["-restart", "2B"],
    "restart3": ["-restart", "3B"],
    "restart5": ["-restart", "5B"],
    "quality1": ["-quality", "1"],
    "progressive": ["-progressive"],
    "progressive_rgb": ["-progressive", "-rgb"],
    "progressive_gray": ["-progressive", "-grayscale"],
    "progressive_gray22": ["-progressive", "-grayscale", "-sample", "2x2"],
    "progressive_444": ["-progressive", "-sample", "1x1,1x1,1x1"],
    "progressive_422": ["-progressive", "-sample", "2x1,1x1,1x1"],
    "progressive_440": ["-progressive", "-sample", "1x2,1x1,1x1"],
    "progressive_411": ["-progressive", "-sample", "4x1,1x1,1x1"],
    "progressive_441": ["-progressive", "-sample", "1x4,1x1,1x1"],
    "progressive_restart1": ["-progressive", "-restart", "1B"],
    "progressive_restart3": ["-progressive", "-restart", "3B"],
    "progressive_rgb_restart": ["-progressive", "-rgb", "-restart", "1B"],
    "gray22_restart": ["-grayscale", "-sample", "2x2", "-restart", "1B"],
    "quality1_restart": ["-quality", "1", "-restart", "1B"],
}


def pattern_ppm(width, height):
    pixels = bytes(value for y in range(height) for x in range(width)
                   for value in ((x * 27 + y * 13) % 256,
                                 (x * 19 + y * 37) % 256,
                                 (x * 43 + y * 7) % 256))
    return f"P6\n{width} {height}\n255\n".encode() + pixels


def segment(marker, payload):
    return bytes((255, marker)) + struct.pack(">H", len(payload) + 2) + payload


def encode_cmyk_entropy(width, height):
    predictions = [0] * 4
    bits = ""
    for y in range((height + 7) // 8):
        for x in range((width + 7) // 8):
            for channel in range(4):
                sample = (47 + x * 29 + y * 37 + channel * 41) % 256
                dc = (sample - 128) * 8
                difference = dc - predictions[channel]
                predictions[channel] = dc
                category = abs(difference).bit_length()
                amplitude = difference if difference >= 0 else difference + (1 << category) - 1
                bits += f"{category:04b}" + (f"{amplitude:0{category}b}" if category else "") + "0"
    bits += "1" * (-len(bits) % 8)
    entropy = bytes(int(bits[i:i + 8], 2) for i in range(0, len(bits), 8))
    return entropy.replace(b"\xff", b"\xff\0")


def encode_dc_cmyk(width, height):
    """Independent DC-only encoder for Adobe transform 0 (not YCCK).

    Each 8x8 block has a constant sample per channel, a unit quantizer,
    and only an EOB AC symbol. ImageMagick instead emits transform 2.
    """
    ids = b"CMYK"
    adobe = segment(0xEE, b"Adobe\0\x64\0\0\0\0\0")
    quantizer = segment(0xDB, b"\0" + bytes((1,)) * 64)
    components = b"".join(bytes((channel, 0x11, 0)) for channel in ids)
    frame = segment(0xC0, b"\x08" + struct.pack(">HHB", height, width, 4) + components)
    dc_table = b"\0" + bytes((0, 0, 0, 12)) + bytes(12) + bytes(range(12))
    ac_table = b"\x10\x01" + bytes(15) + b"\0"
    tables = segment(0xC4, dc_table + ac_table)
    scan = segment(0xDA, b"\x04" + b"".join(bytes((c, 0)) for c in ids) + b"\0\x3f\0")
    return b"\xff\xd8" + adobe + quantizer + frame + tables + scan + encode_cmyk_entropy(width, height) + b"\xff\xd9"


def encode_variants(args, width, height):
    ppm = pattern_ppm(width, height)
    variants = dict(VARIANTS)
    script = str(Path(__file__).with_name("sequential.scans"))
    variants["multiscan"] = ["-scans", script]
    variants["multiscan_restart"] = ["-scans", script, "-restart", "1B"]
    for name, options in variants.items():
        destination = args.output / f"{width}x{height}_{name}.jpg"
        subprocess.run([args.cjpeg, *options, "-outfile", str(destination)], input=ppm, check=True)
    for name, options in (("ycck", []), ("progressive_ycck", ["-interlace", "Plane"])):
        destination = args.output / f"{width}x{height}_{name}.jpg"
        subprocess.run([args.magick, "ppm:-", "-colorspace", "CMYK", *options, str(destination)], input=ppm, check=True)
    (args.output / f"{width}x{height}_cmyk.jpg").write_bytes(encode_dc_cmyk(width, height))


def changed_byte(data, offset, value):
    result = bytearray(data)
    result[offset] = value
    return bytes(result)


def generate_rejections(output):
    baseline = (output / "17x19_444.jpg").read_bytes()
    progressive = (output / "17x19_progressive.jpg").read_bytes()
    restart = (output / "17x19_restart1.jpg").read_bytes()
    sof = baseline.index(b"\xff\xc0")
    sos = baseline.index(b"\xff\xda")
    scan_end = sos + 2 + struct.unpack_from(">H", baseline, sos + 2)[0]
    progressive_sos = progressive.index(b"\xff\xda")
    progressive_end = progressive_sos + 2 + struct.unpack_from(">H", progressive, progressive_sos + 2)[0]
    rejections = {
        "truncated_sof": baseline[:sof + 8],
        "truncated_sos": baseline[:sos + 8],
        "empty_entropy": baseline[:scan_end] + b"\xff\xd9",
        "missing_eoi": baseline[:-2],
        "zero_horizontal_sampling": changed_byte(baseline, sof + 11, 0x01),
        "zero_vertical_sampling": changed_byte(baseline, sof + 11, 0x10),
        "invalid_sampling_factor": changed_byte(baseline, sof + 11, 0x51),
        "invalid_quantizer": changed_byte(baseline, sof + 12, 4),
        "invalid_dc_selector": changed_byte(baseline, sos + 6, 0x40),
        "invalid_ac_selector": changed_byte(baseline, sos + 6, 0x04),
        "invalid_baseline_spectral_start": changed_byte(baseline, scan_end - 3, 1),
        "invalid_progressive_spectral_end": changed_byte(progressive, progressive_end - 2, 64),
        "invalid_progressive_successive_bits": changed_byte(progressive, progressive_end - 1, 0xE0),
        "missing_restart": restart.replace(b"\xff\xd0", b"\xff\xd9", 1),
    }
    destination = output / "reject"
    destination.mkdir(exist_ok=True)
    for name, data in rejections.items():
        (destination / f"{name}.jpg").write_bytes(data)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cjpeg", default=shutil.which("cjpeg"))
    parser.add_argument("--magick", default=shutil.which("magick"))
    parser.add_argument("--output", type=Path, default=Path(__file__).parents[1] / "fixtures" / "jpeg")
    args = parser.parse_args()
    if not args.cjpeg or not args.magick:
        parser.error("Provide cjpeg and magick on PATH or with --cjpeg / --magick")
    args.output.mkdir(parents=True, exist_ok=True)
    for width, height in DIMENSIONS:
        encode_variants(args, width, height)
    generate_rejections(args.output)


if __name__ == "__main__":
    main()
