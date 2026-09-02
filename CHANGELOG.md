# Changelog

All notable changes to the **MineBound** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [0.2.0] - 2026-09-02

### Added
- Comprehensive `CHANGELOG.md` to track project versions and updates.
- Expanded `README.md` with complete gameplay breakdown, control scheme mapping, run instructions, and folder architecture.
- Added range-string parser support (e.g., `'1-2'`, `'2-3'`) to `Grid:getFrames` in `lib/anim8.lua`.

### Fixed
- **TitleState runtime crash**: Added missing `__call` metamethod onto `Grid` in `lib/anim8.lua` so grid objects can be invoked directly as functions (`g(...)`) for frame slicing.

---

## [0.1.0] - 2026-09-02

### Added
- **Core Engine & Architecture**:
  - Initialized LÖVE 11.5 project configuration (`conf.lua`) with $1280 \times 720$ window and vsync.
  - Virtual resolution scaling ($640 \times 360$) via `push.lua`.
  - Finite State Machine (`StateMachine.lua`) supporting `TitleState`, `PlayState`, `PauseState`, and `GameOverState`.
- **World & Tile Grid**:
  - 2D grid arena generation (`Grid.lua`, `Tile.lua`) with grass, stone deposits, gold nodes, walls, and defense turrets.
  - Mining and building mechanics for defensive fortification.
- **Entities & Combat**:
  - Controllable `Hero` with 4-directional movement, melee attack swing, resource inventories, and build modes.
  - Automated `Minion` lane creeps with aggro targeting, pathing, and attack loops.
  - Player and Enemy `Core` structures that act as win/loss objective anchors and minion wave spawners.
- **Visuals & Audio FX**:
  - Top HUD overlay with health bars, resource counters (Gold/Stone), active build selection, and wave timers.
  - Dynamic visual particle effects: floating damage/resource text, spark particles, slash arcs, and turret laser beams.
  - Sound effects for swings, hits, mining, construction, explosions, and UI clicks.
