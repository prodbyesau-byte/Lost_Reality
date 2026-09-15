# Art pass 01 — verification

Environment: Windows, Godot 4.7.2 stable, NVIDIA RTX 3060 Laptop GPU. Main rendering tests used Vulkan / Forward+. Captures are actual 1280 × 800 game viewports.

## Regression results

| Suite | Passed | Failed |
| --- | ---: | ---: |
| Milestone 1 movement/camera/interaction/scenes/saves | 109 | 0 |
| Milestone 2 progression and migrations | 133 | 0 |
| Art, material, LOD and quality-profile checks | 22 | 0 |
| Separate-process save fixture | 3 | 0 |
| Fresh-process load, including progression | 8 | 0 |
| **Main total** | **275** | **0** |
| Additional OpenGL Compatibility art suite | 22 | 0 |

All original gameplay collision bodies remain: 18 in the Tenement and 11 in the Courtyard. Save format remains v3. Player motion/physics, camera projection/limits, object IDs, interaction reach, SavePoint authorization and progression rules remain intact. No tests write to real player save slots.

Manual visual review covered the Tenement, Courtyard, near/far camera sizes and Performance profile. A floor color-space mismatch was corrected; texture contrast was reduced; stain edges were blended; the differently oriented bench was corrected. A startup input-action check prevents the quality autoload from reading a not-yet-created action.

## Captures

- [Concept target](images/concept-target.png) — generated reference, **not** gameplay.
- [Before the pass](images/before.png).
- [Tenement, standard zoom](images/tenement.png).
- [Courtyard, standard zoom](images/courtyard.png).
- [Near zoom](images/close.png).
- [Far zoom / simplified LODs](images/wide.png).
- [Performance profile](images/performance.png).

## Short viewport measurement

These are whole-frame wall-clock samples, not GPU-only timings. Each view settles before 90 samples, with VSync disabled by the harness. This automated desktop session produced approximately 30 FPS across all three samples; focus/driver/frame pacing may influence that result. It does **not** establish a 60 FPS production budget or semi-open-world performance.

| View | Median frame | p95 frame | Draw calls | Reported primitives |
| --- | ---: | ---: | ---: | ---: |
| Tenement, Atmospheric | 33.30 ms | 33.70 ms | 453 | 38,188 |
| Courtyard, Atmospheric | 33.34 ms | 33.66 ms | 237 | 18,384 |
| Courtyard, Performance | 33.31 ms | 33.79 ms | 198 | 7,604 |

The lower profile reduces reported geometry and draw calls, but this run did not demonstrate a frame-time improvement. Profile a foreground standalone build on target hardware before promising larger-area performance. Raw measurements: [metrics.json](metrics.json).

Run `tests/Run-Tests.ps1 -GodotPath <console executable> -Visual` to repeat the full suite and captures. The Compatibility check is `Godot_console.exe --rendering-method gl_compatibility --path . res://tests/art_review.tscn -- --no-captures`.

## Scope limits

This is an initial playable visual pass built from original procedural meshes and materials. The concept's authored hero detail, final texture painting, complete skeletal animation, baked indirect light, dynamic roofs and large-area streaming are still production work. Creatures are art-direction guidance only; no monsters, combat or other new gameplay systems were implemented.
