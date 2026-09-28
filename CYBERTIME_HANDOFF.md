# CyberTime Godot Port — Handoff

## Locations and source

- **Godot project:** `/Users/josephweiss/cybertime`
- **Original source requested by Joseph:** <https://github.com/jos-w-glitch/Cybertime>
- **Local copy of original source:** `/Users/josephweiss/cybertime/Cybertime-main/`
- **Godot version:** 4.7, GL Compatibility renderer
- **Current local branch:** `cursor/web-deploy-corner-home`
- **Important:** the local Godot repository has no configured Git remote.

## Product direction

CyberTime is a 2D cyberpunk rhythm/timing clicker. Joseph wants an upgraded Godot recreation of the original, **not a redesign**. Preserve the original dark neon-grid visual language, English UI, and only light polish/effects.

Do **not** reintroduce the following unless Joseph explicitly asks:

- Japanese text/UI
- A wholesale glow/neon-art overhaul
- A 3-2-1 announcer countdown
- Day/night modes
- Cursor-skin purchases

Those were tried and later explicitly reverted or removed. The game should begin immediately when the player activates the start orb.

## Current gameplay

- Story stages run for 30 seconds and start with 5 hearts.
- **Blue targets:** left-click / `Z`.
- **Red bombs:** right-click / `X`.
- **Orange targets:** defuse then confirm on desktop; three taps on mobile.
- **Purple targets:** explicitly removed from every current level configuration. Supporting code remains, but current levels should not spawn them.
- **Sliders:** click/tap the moving target anywhere; the earlier gold timing-line requirement was removed.
- A slider fails only after it has entered the play area and later fully leaves it.
- World 2 sliders can move diagonally or vertically; World 1 sliders are horizontal.
- Hits build combo. Score, XP, coins, high scores, cleared stages, mobile mode, backgrounds, and the Infinite high score are saved in `user://cybertime_save.json`.
- A testing cheat deliberately ensures the player starts with at least `999999` coins.

## Player feedback and mobile parity

- Targets and hearts were enlarged for desktop and mobile.
- Missing a target produces one clean red full-screen flash. This replaced an earlier multi-corner effect.
- Mobile mode is a saved main-menu setting:
  - Blue: one tap
  - Red: two taps
  - Orange: three taps
  - Larger hit zones
- Cursor skins were removed to keep desktop and mobile fair. The shop is meant to sell backgrounds only.

## Content structure

Navigation: `Main menu → World select → Level select → Game → Game over`

Infinite mode: `Main menu → Infinite → track/mechanics dropdowns → Game`

### Worlds

- **World 1 — CYBER GRID:** stages 1–12 and the original neon theme.
- **World 2 — HEXCORE:** Arcane-inspired *visual theme only*, stages 13–19, intended as upper/endgame difficulty.
- All worlds and stages are intentionally unlocked for now.
- World 2 loads music from `assets/music/world2/1.mp3` through `7.mp3`, then falls back to World 1 tracks when needed.

Joseph asked for a boss-fight feel. The project has seven World 2 stages, but no dedicated boss-health, phase, or boss-visual system is evident in the current source. Treat true boss gameplay as unfinished work.

### Music rights

Joseph supplied YouTube-ripped Arcane tracks. They were not bundled due to copyright. Only use music files Joseph owns or is licensed to distribute.

## Economy and shop

Defined in `LevelData.SHOP_BACKGROUNDS`:

| Background | Price |
| --- | ---: |
| Cyber Grid | Free |
| Matrix | 350 |
| Sunset | 550 |
| Deep Space | 800 |
| Retro Wave | 1,200 |
| Custom Upload | 10,000 |

Custom background upload accepts PNG, JPG, or WebP; it resizes the selected image to 1280×720 and persists it as `user://custom_background.png`.

## Infinite mode

- Pick a World 1 track and a mechanics preset from dropdowns.
- Presets: Blue Only, Red Bombs, Orange Mix, Sliders, Red Sliders, Full Mix.
- No time limit; difficulty ramps over time.
- Infinite has its own saved high score.
- An earlier initialization crash caused by an empty level was fixed.

## Important code map

- `project.godot` — app settings, autoloads, input mappings.
- `scripts/systems/world_catalog.gd` — world metadata and all story-stage definitions: BPM, timing, probabilities, rewards.
- `scripts/systems/level_data.gd` — shared constants, shop themes, music resolution.
- `scripts/game/game_arena.gd` — run loop, input, scoring, and target progression.
- `scripts/entities/target.gd` — target types, hit zones, slider movement/off-screen failure rule.
- `scripts/systems/save_manager.gd` — persistence, rewards, mobile mode, custom backgrounds, Infinite-coins test cheat.
- `scripts/systems/infinite_catalog.gd` — Infinite setup presets and difficulty ramp.
- `scripts/systems/audio_manager.gd` — menu/level music plus generated hit, defuse, and miss sounds.
- `scenes/ui/` — menu, world select, level select, shop, Infinite select, game over.
- `deploy-site/` — static website wrapper for the Godot HTML5 export.

## Local-only / unpushed work map

This is the reason a fresh GitHub-source checkout will appear to be missing major parts of the current game.

| Local item | Git state | What it contains | What a source checkout is missing |
| --- | --- | --- | --- |
| Godot port source | Committed only in the local repository | 107 files / 3,398 inserted lines: scenes, gameplay, systems, UI, saves, Infinite mode, shop, worlds, and mobile controls | The entire Godot implementation |
| Godot assets | Committed only in the local repository | `assets/`: font, UI artwork, World 1 music, World 2 music slots; about 131 MB currently | Imported game art/audio used by the Godot port |
| Web deployment | Local and ignored by Git | `deploy-site/`: exported HTML5 build, `index.pck`, JS/WASM, Vercel config; about 53 MB | The live-site build and its Vercel configuration |
| Original-source reference copy | Local and ignored by Git | `Cybertime-main/`, a 2.1 MB copy of the original web game | It is not included in the Godot repository |
| Export configuration | Local and ignored by Git | `export_presets.cfg` | Godot web-export preset/configuration |

### Local commit history

The local repository has only these commits and **no `main` branch or remote**:

1. `ff15df6 Add CyberTime Godot game with web deploy and corner HOME.`
   - Initial local commit; adds the full Godot port, its music/assets, scenes, scripts, and project settings.
2. `35aaaa2 Fix corner HOME button visibility on the main menu.`
   - Adds 13 lines to `scripts/ui/main_menu.gd` to force the in-game corner HOME button to stay visible.

Therefore both commits are unpushed by definition. A future agent must add the intended GitHub remote, then decide what should be versioned before pushing. In particular, do **not** blindly publish music unless Joseph has distribution rights.

### Reference-copy caveat

`Cybertime-main/` is not a normal clone: it contains no `.git` directory. It is excluded by `.gitignore` and serves as a local reference copy of `jos-w-glitch/Cybertime`.

It includes the original web-game source and built bundle, but its `music/` directory contains import metadata rather than the actual MP3s. The local Godot asset folder is where the playable music files were placed. This explains why the GitHub/reference copy can look incomplete compared with the Godot project.

## Website / Vercel history

A prior agent reported the game live at <https://www.joseph-weiss.com/cybertime/>.

The HTML5 deployment compressed/truncated music to stay below Vercel’s 100 MB file limit; the reported `.pck` was 15 MB. The web version was changed to preserve a 16:9 canvas, use a dark clear color, and force English/LTR behavior.

There should be a small, in-game **HOME** button in the top-left corner. An earlier HTML overlay HOME button outside the canvas was removed and should remain removed.

## Current risks and first checks

1. The current working tree has two tracked music files deleted:
   - `assets/music/5.mp3`
   - `assets/music/menu.mp3`

   Restore or intentionally replace them before considering the local build healthy.

2. Local commits are not on GitHub because the Godot repo has no remote configured.

3. Current branch commits:
   - `ff15df6 Add CyberTime Godot game with web deploy and corner HOME.`
   - `35aaaa2 Fix corner HOME button visibility on the main menu.`

4. Before adding features, run the game and verify menu music, stage 5 music, mobile input, slider behavior, Infinite mode, save/load behavior, HTML5 web export, and the in-game HOME button.
