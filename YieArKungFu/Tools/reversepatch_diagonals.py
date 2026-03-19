#reversepatch_diagonals.py TILESHEER_fcm.chr TILESHEET_preview_ncm.chr --tiles-per-row 16 --start-row 32 --rows 128 --cols 16

#!/usr/bin/env python3
from pathlib import Path
import argparse

GLYPH_BYTES = 64  # 8x8, 1 byte per pixel/index, 8*8=64

def glyph_slice(i: int):
    s = i * GLYPH_BYTES
    return s, s + GLYPH_BYTES

def swap_blocks(data: bytearray, a: int, b: int):
    a_s, a_e = glyph_slice(a)
    b_s, b_e = glyph_slice(b)
    tmp = data[a_s:a_e]
    data[a_s:a_e] = data[b_s:b_e]
    data[b_s:b_e] = tmp

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("input", type=Path)
    ap.add_argument("output", type=Path)
    ap.add_argument("--tiles-per-row", type=int, default=16)
    ap.add_argument("--start-row", type=int, default=32)
    ap.add_argument("--start-col", type=int, default=0)
    ap.add_argument("--rows", type=int, default=128)
    ap.add_argument("--cols", type=int, default=16)
    args = ap.parse_args()

    data = bytearray(args.input.read_bytes())
    if len(data) % GLYPH_BYTES != 0:
        raise RuntimeError("Input size not multiple of 64 bytes")

    tiles_per_row = args.tiles_per_row
    x0, y0 = args.start_col, args.start_row
    w, h = args.cols, args.rows

    # operate on 2x2 quads inside the region
    swaps = 0
    for ty in range(y0, y0 + h, 2):
        for tx in range(x0, x0 + w, 2):
            # quad tile indices in the linear tilesheet
            tl = ty * tiles_per_row + tx
            tr = tl + 1
            bl = tl + tiles_per_row

            # inverse of your patch (same swap)
            swap_blocks(data, tr, bl)
            swaps += 1

    args.output.write_bytes(data)
    print(f"Wrote {args.output}")
    print(f"Swapped TR<->BL in {swaps} quads")

if __name__ == "__main__":
    main()
