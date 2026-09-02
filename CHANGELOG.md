# Changelog

All notable changes to the **MineBound: Dual-World Dimension Shift** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [1.0.0] - 2026-09-02 — *The Dual-World Dimension Shift Release*

### Added
- **Dual-World Dimensional System**:
  - Added dual-layer parallel world simulation in `Grid.lua`: **Overworld (Surface Realm)** and **Nether Realm (Void Underworld)**.
  - Dimension Shifting mechanic triggered via `Q`, `Shift`, or stepping onto dimensional `Rift Portals`.
  - Added warp shockwave animations, purple particle bursts, and `shift.wav` sound effect on realm transitions.
- **Topological Inversion & Exploration**:
  - Asymmetrical path layout between Overworld (blocked center, open sides) and Nether Realm (open center, obsidian edges) allowing players to flank enemy defenses and bypass obstacles.
- **Dual-World Economy & Resources**:
  - Overworld resource nodes: **Gold** and **Stone**.
  - Nether Realm resource nodes: **Soul Crystals / Void Essence**.
  - Added UI icon and HUD tracker for **Void Essence**.
- **Nether Anchors & Cross-World Core Shielding**:
  - Added **Player Nether Anchor** and **Enemy Nether Anchor** structures in the Nether Realm.
  - While the Enemy Nether Anchor is intact, the Enemy Nexus in the Overworld is enveloped by a **Dimensional Shield (50% damage reduction)**.
  - Destroying the Nether Anchor shatters the enemy Nexus shield, opening a clear path to victory.
- **Spectral Void Minions**:
  - Implemented Nether Realm creep waves (`minion_void_player`, `minion_void_enemy`) that engage in underworld skirmishes.
- **New Build Mode**:
  - Key `3`: Build **Void Anchors** (costs 30 Void Essence, 20 Gold) which pulse defensive laser attacks against nearby Nether intruders.

---

## [0.2.0] - 2026-09-02

### Added
- Comprehensive `CHANGELOG.md` and initial `README.md`.
- Range string parser support (e.g. `'1-2'`, `'2-3'`) in `lib/anim8.lua`.

### Fixed
- Fixed crash in `TitleState` by defining the `__call` metamethod on `Grid` in `lib/anim8.lua`.

---

## [0.1.0] - 2026-09-02

### Added
- Initial single-world prototype with StateMachine, Hero movement, mining, and minion spawning.
