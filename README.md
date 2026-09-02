# MineBound: Dual-World Dimension Shift

A 2D top-down hybrid game combining MOBA-style hero combat, real-time tile-grid building, and **connected Dual-World dimension-shifting gameplay**. Built in Lua with [LÖVE 11.5](https://love2d.org).

---

## 🌌 The Dual-World Concept

In **MineBound**, the battlefield spans across two interconnected, parallel dimensions existing at the exact same physical coordinates:

1. **The Overworld (Surface Realm)**:
   - The primary lane where the massive **Player Nexus** and **Enemy Nexus** stand.
   - Resource-rich with **Gold** and **Stone** deposits.
   - Guarded by kinetic walls, turret batteries, and standard soldier minion waves.

2. **The Nether Realm (Void Underworld)**:
   - A dark, ethereal mirror realm filled with **Soul Crystals / Void Essence** and impenetrable obsidian barriers.
   - Houses the mystical **Nether Anchors**: as long as an enemy's Nether Anchor is alive, their main Surface Nexus is protected by a **Dimensional Energy Shield (taking 50% reduced damage)**.
   - Spawns lethal **Spectral Void Creeps** that fight in the underworld.

---

## 🔁 Cross-World Interactivity & Strategy

- **Dimension Shifting (`Q` / `Shift` / Rift Gates):** Instantly warp between the Surface and Nether Realms with a ripple effect and warp sound.
- **Topological Inversion:** Solid stone obstacles blocking a path in the Overworld may be completely open in the Nether Realm. Players can dive into the Nether Realm, sprint past defensive fortifications, and re-emerge behind enemy lines.
- **Cross-Dimensional Building & Economy:**
  - Harvest **Gold & Stone** on the surface to construct rapid-fire **Laser Turrets** and **Fortified Walls**.
  - Harvest **Void Essence** in the Nether Realm to build **Nether Anchors** that empower allied forces.
- **Shield Shatter Win Condition:**
  - Shift into the Nether Realm to destroy the **Enemy Nether Anchor**.
  - Once the Anchor shatters, the shield on the enemy Surface Nexus collapses, leaving it vulnerable to direct siege and victory!

---

## 🕹️ Controls

| Action | Keyboard / Mouse |
| :--- | :--- |
| **Move Hero** | `W`, `A`, `S`, `D` or `Arrow Keys` |
| **Attack / Melee Slash** | `J` or `Left Click` |
| **Mine / Build Action** | `Space`, `K`, or `Right Click` |
| **Dimension Shift (Surface ↔ Nether)** | `Q`, `Left Shift`, `Right Shift`, or `Middle Click` |
| **Select Build Mode** | `1` (Wall: 5 Stone) / `2` (Turret: 25G, 10S) / `3` (Void Anchor: 30 Void Essence, 20G) |
| **Pause Game** | `Escape` or `P` |
| **Menu Confirm / Start** | `Enter` / `Return` / `Space` |

---

## 📦 Requirements & Running

### Requirements
- **[LÖVE 11.5+](https://love2d.org)**
- **Python 3.x with Pillow** (for asset generation scripts)

### Running the Game

1. **Via Command Line (PowerShell / Terminal):**
   ```powershell
   # Run directly with LOVE:
   & "C:\Program Files\LOVE\love.exe" .

   # (Optional) Re-generate assets / audio SFX:
   python generate_assets.py
   ```

2. **Via Drag & Drop:**
   - Drag and drop the root `final` folder onto the `love.exe` application icon.

---

## 📂 Project Architecture

```plaintext
MineBound/
├── assets/
│   ├── audio/
│   │   ├── music/         # Background battle soundtrack
│   │   └── sfx/           # Hit, mine, build, shoot, core_hit, shift, victory, defeat
│   └── textures/
│       ├── heroes/        # Hero spritesheet, standard & void minion animations
│       ├── tiles/         # Dual-realm tileset (Overworld + Nether Void floor/ores/anchors/rifts)
│       └── ui/            # UI icons (Health, Gold, Stone, Void Essence, Sword, Pickaxe)
├── lib/
│   ├── anim8.lua          # Sprite animation and grid frame slicing
│   ├── class.lua          # OOP class inheritance library
│   ├── knife/             # Timer & event utilities
│   └── push.lua           # Virtual resolution handling (640x360 rendered to 1280x720)
├── src/
│   ├── entities/
│   │   ├── Core.lua       # Overworld Nexus structures, Nether shield logic, and wave spawners
│   │   ├── Hero.lua       # Player entity (movement, combat, realm shifting, mining, building)
│   │   └── Minion.lua     # AI creeps (Overworld soldiers & Nether spectral creeps)
│   ├── states/
│   │   ├── BaseState.lua  # Base state template
│   │   ├── TitleState.lua # Main title menu screen & animated preview
│   │   ├── PlayState.lua  # Dual-world gameplay loop, HUD, warp FX, parallel updates
│   │   ├── PauseState.lua # Pause overlay
│   │   └── GameOverState.lua # Victory/Defeat end screen
│   ├── world/
│   │   ├── Grid.lua       # Dual-layer dimension grid manager, mining & anchor queries
│   │   └── Tile.lua       # Dual-world tile definitions, turrets, anchors, portals
│   ├── StateMachine.lua   # Finite state machine manager
│   └── Util.lua           # Texture and quad helper utilities
├── conf.lua               # LÖVE window configuration & dimensions
├── generate_assets.py     # Procedural pixel art and procedural audio generator
├── main.lua               # Game initialization, asset loader, and main hooks
├── CHANGELOG.md           # Version release notes and change history
└── README.md              # Project overview and documentation
```