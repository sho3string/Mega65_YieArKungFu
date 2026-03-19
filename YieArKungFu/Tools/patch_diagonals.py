#patch_diagonals.py input.chr output.chr \
#  --tiles-per-row 16 \
#  --start-row 32 \
#  --sprite-cols 8 \
#  --sprite-rows 64


from pathlib import Path
import argparse

GLYPH_BYTES = 64  # 8x8 tile

def swap_diagonal_per_sprite(data, tiles_per_row,
                             start_row, sprite_rows, sprite_cols):

    def glyph_slice(i):
        s = i * GLYPH_BYTES
        return s, s + GLYPH_BYTES

    base_tile = start_row * tiles_per_row

    for sy in range(sprite_rows):
        for sx in range(sprite_cols):

            # top-left tile of this sprite
            tile_x = sx * 2
            tile_y = sy * 2

            tl = base_tile + (tile_y * tiles_per_row) + tile_x
            tr = tl + 1
            bl = tl + tiles_per_row
            br = bl + 1

            tr_s, tr_e = glyph_slice(tr)
            bl_s, bl_e = glyph_slice(bl)

            tmp = data[tr_s:tr_e]
            data[tr_s:tr_e] = data[bl_s:bl_e]
            data[bl_s:bl_e] = tmp

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("output")
    parser.add_argument("--tiles-per-row", type=int, default=16)
    parser.add_argument("--start-row", type=int, default=32)
    parser.add_argument("--sprite-rows", type=int, required=True)
    parser.add_argument("--sprite-cols", type=int, required=True)

    args = parser.parse_args()

    data = bytearray(Path(args.input).read_bytes())

    swap_diagonal_per_sprite(
        data,
        args.tiles_per_row,
        args.start_row,
        args.sprite_rows,
        args.sprite_cols
    )

    Path(args.output).write_bytes(data)

    print("Sprite-aware diagonal patch complete.")

if __name__ == "__main__":
    main()
