*=* "VideoRamHelper.asm"

// Per-row hidden prefix bytes before visible text starts.
// 0 for normal rows, 32 for rows with pixie/RRB header in front.
.var RowPrefixBytes = List().add(
    $00,$00,$00,$00,$00,$00,$10,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00
)

.function ArcadeToMegaTextByte(addr) {
    .var off   = addr - ARCADE_VRAM_BASE
    .var row   = off >> 6
    .var col   = off & $3f
    .var cell  = col >> 1
    .var lane  = col & 1    // 0=arcade attr, 1=arcade tile
    .var base  = SCREEN_BASE + (row * ROW_STRIDE) + RowPrefixBytes.get(row) + (cell * 2)
    .return base + (lane == 1 ? 0 : 1)
}