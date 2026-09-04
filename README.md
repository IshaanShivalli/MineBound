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

- **Dimension Shifting (`Q` / `Shift` / Rift Gates):** Instantly warp between the Surface and Nether Realms with a ripple effect and warp sound. **Limited to 4 shift charges per match!**
- **Topological Inversion:** Solid stone obstacles blocking a path in the Overworld may be completely open in the Nether Realm. Players can dive into the Nether Realm, sprint past defensive fortifications, and re-emerge behind enemy lines.
- **Cross-Dimensional Building & Economy:**
  - Harvest **Gold & Stone** on the surface to construct rapid-fire **Laser Turrets**, **Fortified Walls**, and **Pet Sheds**.
  - Harvest **Void Essence** in the Nether Realm to build **Nether Anchors** that empower allied forces.
- **Pets & Companions:**
  - Unlock the **Pet Shed** by destroying 2 enemy turrets and achieving a solo enemy hero kill.
  - Train pets in the shed; pets slow down enemy turrets and apply poison damage to player targets.
  - Note: Player pets do not work in the Nether, but opponents spawn with pets active in both realms!
- **Shield Shatter & Base Retaliation:**
  - Shift into the Nether Realm to destroy the **Enemy Nether Anchor**.
  - Once the Anchor shatters, the shield on the enemy Surface Nexus collapses. Beware: attacking an unshielded base triggers base retaliation damage against attacking heroes and pets!

---

## 🕹️ Controls

| Action | Keyboard / Mouse |
| :--- | :--- |
| **Move Hero** | `W`, `A`, `S`, `D` or `Arrow Keys` |
| **Attack / Melee Slash** | `J` or `Left Click` |
| **Mine / Build Action** | `Space`, `K`, or `Right Click` |
| **Dimension Shift (Surface ↔ Nether)** | `Q`, `Left Shift`, `Right Shift`, or `Middle Click` (Max 4 per match) |
| **Dash Ability** | `E` (4s cooldown) |
| **Ultimate Ability** | `R` (14s cooldown) |
| **Select Build Mode** | `1` (Wall) / `2` (Turret) / `3` (Void Anchor) / `4` (Healer) / `5` (Pet Shed) |
| **Open Tech Shop** | `B` |
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
   python assets/generate_assets.py
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
│   ├── textures/
│   │   ├── heroes/        # Hero spritesheet, standard & void minion animations
│   │   ├── tiles/         # Dual-realm tileset (Overworld + Nether Void floor/ores/anchors/rifts)
│   │   └── ui/            # UI icons (Health, Gold, Stone, Void Essence, Sword, Pickaxe)
│   ├── export_gguf.py     # Standalone GGUF model binary exporter
│   ├── generate_assets.py # Procedural pixel art and audio generator
│   └── verify_setup.py    # Environment validator
├── lib/
│   ├── anim8.lua          # Sprite animation and grid frame slicing
│   ├── class.lua          # OOP class inheritance library
│   ├── knife/             # Timer & event utilities
│   └── push.lua           # Virtual resolution handling (640x360 rendered to 1280x720)
├── notebook/
│   ├── MineBound_AI_Training.ipynb # Dual-world strategic AI training notebook
│   └── Pet_AI_Training.ipynb       # Pet behavior & RL decision model notebook
├── src/
│   ├── entities/
│   │   ├── Boss.lua       # Void Golem neutral boss in Nether (spawns every 2 wars)
│   │   ├── Core.lua       # Overworld Nexus structures, Nether shield & retaliation logic
│   │   ├── EnemyAI.lua    # Strategic AI controller for enemy builds, minions, and economy
│   │   ├── EnemyHero.lua  # AI-controlled enemy champion
│   │   ├── Hero.lua       # Player entity (movement, combat, capped realm shifting, mining, building)
│   │   ├── Minion.lua     # AI creeps (Overworld soldiers & Nether spectral creeps)
│   │   └── Pet.lua        # Companion pet entity (turret slowing, poison DOT, realm rules)
│   ├── states/
│   │   ├── BaseState.lua  # Base state template
│   │   ├── CutsceneState.lua # Story intro animated moving cutscenes
│   │   ├── TitleState.lua # Main title menu screen & animated preview
│   │   ├── PlayState.lua  # Dual-world gameplay loop, HUD, shop, warp FX, parallel updates
│   │   ├── PauseState.lua # Pause overlay
│   │   └── GameOverState.lua # Victory/Defeat end screen
│   ├── world/
│   │   ├── Grid.lua       # Dual-layer dimension grid manager, mining, random resources & anchor queries
│   │   └── Tile.lua       # Dual-world tile definitions, turrets, anchors, healing chambers, pet shed
│   ├── StateMachine.lua   # Finite state machine manager
│   └── Util.lua           # Texture and quad helper utilities
├── conf.lua               # LÖVE window configuration & dimensions
├── main.lua               # Game initialization, asset loader, and main hooks
├── CHANGELOG.md           # Version release notes and change history
└── README.md              # Project overview and documentation
```