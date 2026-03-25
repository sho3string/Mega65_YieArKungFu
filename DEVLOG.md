
## DevLog - Yie Ar Kung Fu Mega65 port

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

