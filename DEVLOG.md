
## DevLog - Yie Ar Kung Fu Mega65 port

### 6/04/2026

Implemented energy meter functionality

TODO  

Pending:
Combat damage logic  
Energy depletion updates  
Remaining AI / gameplay routines  
Gameplay routines triggered by combat events

### 3/04/2026

## RRB Pixie Row Pressure Investigation

While rendering the title screen using VIC-IV RRB pixies, intermittent corruption was observed when `RRB_PixiesPerRow` was set to 40.

Symptoms included:

- Horizontal glitches appearing above/below the title logo
- Corruption in rows that contained large numbers of pixies
- Behaviour differing between emulator and real hardware

### Investigation

A histogram-based diagnostic was introduced:

- `RowPeakTable` records the maximum pixies emitted per row
- `RRB_GlobalPeakCount` records the worst row across the frame

Example diagnostic output before optimisation:

RowPeakTable
:000051AC:00000000000000000014282828140000
:000051BC:00000000000000000006060000000000

RRB_GlobalPeakCount = $27 (39 pixies)


This showed that the **YIE AR KUNG FU logo rows were responsible for the peak usage**.

The peak rows required **39 pixies**, which is very close to the observed corruption threshold.

### Root Cause

Sprites that are **not aligned to an 8-pixel Y boundary** require spill rows:

aligned sprite → 4 pixies
misaligned sprite → 8 pixies  


The title logo sprites were misaligned, causing heavy spill usage across several rows.

### Fix

Two changes were implemented:

1. Conditional spill emission

if(sprite_y & 7) == 0
emit only main rows (4 pixies)
else
emit full spill rows (8 pixies)  

if(sprite_y & 7) == 0
emit only main rows (4 pixies)
else
emit full spill rows (8 pixies)  


2. Shift the title logo **1 pixel vertically**

This placed the sprites on an **8-pixel boundary**, eliminating spill rows and reducing pressure.

### Result

Row usage dropped dramatically:

Before: 14 28 28 28 14  
After: 14 14 14 14  

Global peak: 40 pixies → 20 pixies

This represents roughly a **50% reduction in RRB pressure**.

### Current Status

The title screen is now stable even with:
RRB_PixiesPerRow = 37

### 27/03/2026

### Playfield Attribute Translation Fix

- Completed debugging of the playfield attribute decoding in `loc_879e`.
- Determined that the **MAME source comments for sprite flip bits are incorrect**.
- Verified correct behaviour through direct memory testing.

<img width="696" height="553" alt="{89A63EFC-02FE-4809-8E80-7A27E1D715E3}" src="https://github.com/user-attachments/assets/28fb145d-d5a5-4f8a-ac2c-c215ad698e8e" />

Actual arcade behaviour:

```
bit 6 = Flip Y
bit 7 = Flip X
```

MAME documentation incorrectly states the opposite.

### Hardware Verification

Memory test performed using:

```
b@58de
```

Observed behaviour:

| Value | Result |
|------|------|
| `00` | normal |
| `40` | vertically flipped |
| `80` | horizontally flipped |

Conclusion: **hardware behaviour confirms bit6=Y and bit7=X**.

---

### MEGA65 Attribute Conversion

MEGA65 colour RAM uses a different flip-bit layout.

Arcade:

```
bit6 = Y
bit7 = X
```

MEGA65:

```
bit6 = X
bit7 = Y
```

Implemented conversion inside `loc_879e`:

```asm
lda tmp
and #$40
asl
sta tmp2

lda tmp
and #$80
lsr
ora tmp2
```

This swaps the bits before writing to colour RAM.

---

### Tile Page Bit Handling

Arcade attribute bit `0x10` contains the tile page MSB.

MEGA65 screen attribute expects this as **bit0**.

Implemented conversion:

```asm
and #$10
lsr
lsr
lsr
lsr
```

Result:

```
0x10 → 0x01
```

Combined with row mask:

```asm
ora #$08
```

---

### Colour RAM Pointer Fix

Stabilised colour RAM writes using a fixed high-bank pointer.

Pointer behaviour:

```
COLPTR2 / COLPTR3 = constant
COLPTR0 / COLPTR1 = calculated per tile
```

Offset calculation:

```asm
sec
lda X_L
sbc #<SCREEN_BASE
sta COLPTR0

lda X_H
sbc #>SCREEN_BASE
sta COLPTR1
```

Resolved earlier crashes caused by unstable pointer values.

---

### Rendering Loop Cleanup

Optimised `loc_879e`.

- simplified attribute extraction


---

### Visual Verification

Confirmed correct rendering of:

- background tiles
- tile flipping

Playfield now renders correctly with proper flipping behaviour.

---

### Known Issues / To Do

- `KO` text is a few pixels too far to the right, still needs to be addressed.
- Continue validating playfield draw behaviour across attract screens.
- Confirm no additional attribute bits are used by other playfield routines.

---

### 26/03/2026

### Playfield Draw Routine Bring-Up (`loc_8782` / `loc_879e`)

- Began implementing the arcade playfield draw routine used in attract mode.
- Ported core tile copy logic:

```asm
lda ,u
sta ,x
```

- Implemented attribute table lookup using:

```asm
U + $02E0
```

This table supplies:

- tile page / MSB bit
- flip bits

---

### Screen / Colour RAM Split Handling

Arcade stores tile and attribute together.

MEGA65 requires separate writes:

```
screen RAM  → tile index
colour RAM  → flip attributes
screen attr → row mask + tile page bit
```

Implemented split write path:

```
tile → screen RAM
flip bits → colour RAM
page bit → screen attribute
```

---

### First Rendering Attempt

Initial results:

- tiles appeared in the correct position
- page selection worked
- flip behaviour incorrect

This led to investigation of the sprite attribute bits.

---

### Lessons Learned

- Emulator comments cannot always be trusted.
- Hardware behaviour must be verified when behaviour appears inconsistent.
- Attribute translation between arcade hardware and MEGA65 requires explicit bit remapping.

---

### Next Target

Continue refining the **playfield draw path** and integrate it with the existing rendering pipeline.

Focus areas:

- ensure row mask handling is consistent
- confirm tile page logic for all tilesets
- continue validating attract-mode rendering behaviour.


### 25/03/2026

## Attract playfield draw progress

- Corrected `loc_8782` column start logic.
- Fixed destination column sequencing using proper tile-byte arcade addresses:
  - `PlayfieldColumnPtrs = ArcadeToMegaTextByte($59C1 + (i * 2))`
- Confirmed playfield now draws in the correct screen position and shape.
- Remaining issues are now limited to per-tile attribute decoding:
  - tile MSB / page selection
  - X/Y flip bits
  - MEGA65 row mask merge
- Geometry/pathing bug appears solved.

<img width="586" height="504" alt="{9E16D210-6C8A-4D17-8A36-C6403967A348}" src="https://github.com/user-attachments/assets/aff29943-6916-42bf-bf81-36c5836e4399" />


- ## Known Issues / To Do
  
- `KO` text is still a few pixels too far to the right.
  - It should be directly under the `3` in `38`.
  - Likely not a script-anchor issue anymore.
  - More likely caused by fine horizontal placement via `gotoX_pos (lo)` or related RRB tail positioning.
  - Need to verify whether a low-byte `gotoX` adjustment is introducing a small horizontal shift.

### 24/03/2026

### Porting Progress Notes
✔ Attract / High‑Score Text & HUD Path (via sub_86f6)
- Finished attract/high‑score text and HUD bring‑up path.
- Fixed command‑queue consumer state corruption:
- loc_807c was reusing byte_dc / byte_dd as scratch.
- Moved temporary queue‑pointer scratch to safe bytes.
- Fixed queue command generation in loc_8710 / loc_80a2:
- 03 00 was incorrectly emitted as BF 00.
- Root cause: loc_80a2 writes byte_f3:byte_f2, so both must be set before calling.
- Corrected queue/pointer initialization around $02D8 equivalents:
- Confirmed MEGA65 requires little‑endian storage.
- Fixed $8300 pointer setup → intended state:
  CE 82 / C8 82 / 00 83 / 00 83
- Verified the DC/DD overwrite happened later in loc_807c, not during init.
- Fixed overlap bug:
- Y_H was mapped to $C1, corrupting byte_c1.
- Moved Y_L / Y_H to safe scratch space.
✔ loc_8994 Behavior Restored
- Arcade: C1 = 02 → EOR #04 → 06
- Port now matches this exactly.  

### Attract Enemy‑Name Routine
- Finished enemy‑name attract routine.
- Fixed pointer table declarations to use proper .word end-label pointers.
- Fixed backward string rendering by preserving A across pointer movement.
- Corrected destination stepping to visible‑cell spacing.
- Confirmed attract now shows NUNCHA correctly.
- Confirmed enemy‑name selector comes from copied state data ($5461 → $5431), not RNG.
RAM Offset Fix
- Incorrect write: WORK_RAM1 + $461
- Corrected: WORK_RAM2 + $31 (for original $5461)  


### Score / High‑Score Text Generation
- Completed player score / high‑score text generation:
- Player 1 score: $58C3
- Player 1 hi‑score: $58DB
- Player 2 score path via sub_88BF
- Verified P2 score prints correctly when branch is forced.
Score/Name Formatting Pipeline Fixes
Affected routines:
- sub_88c5
- sub_890f
- sub_891f
- sub_8922
Fixes:
- Corrected MEGA65 cell stepping to 2‑byte visible cells.
- Fixed negative offset handling in sub_8922.
- Fixed name‑copy loop to step through low bytes only.
Result: High‑score ranking screen now renders correctly and matches arcade layout.  

### Text‑Script Handling
- Verified earlier fixes in sub_87cf remain correct.
- Byte order unchanged — MEGA65 adaptation was already correct.  


### KO Text Placement Fix
Replaced old direct formula with proper arcade→MEGA text address translator:
- Added row‑aware VRAM translation helper.
- Accounted for:
- Arcade [attr][tile] vs MEGA65 [tile][attr]
- Row‑specific hidden RRB/pixie prefix bytes
- Confirmed correct alignment for:
- 1UP, HI SCORE, 38400, KO, NUNCHA, OOLONG, score circles, P2 score path.
- Added safe ArcadeToMegaTextByte() handling for higher rows to avoid prefix‑table OOB.  

### Player 1 Energy Bar Initialization
- Determined routine only writes flipped attribute bytes, not full bar cells.
- Corrected translated start position so it no longer overwrites pixie prototype bytes.
- Preserved required row‑mask bit → final attribute = $88.
- Verified resulting memory pattern:
10 88 repeated for visible bar cells.

### Corrected Earlier Wrong Assumptions
- ldd #$800F uses $80 as data and $0F as count.
- Queue pointer values like C8 82 can be valid depending on queue progress.
- Real issue was malformed queue contents and pointer clobbering, not queue base.

### Next Major Step
loc_8782 — Draw Playfield (Right → Left) for Attract Mode
This is the next routine to debug/port.

### Remaining Issues
- Visible glitching appears to come from the playfield draw path, not HUD/text routines.

### Next Target
- loc_8782 — “Draws the playfield / From right to left

