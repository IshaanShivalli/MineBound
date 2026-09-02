# MineBound

A fast-paced 2D top-down hybrid game combining MOBA-style hero combat with real-time tile-grid building, mining, and lane warfare. Built in Lua with [LÖVE 11.5](https://love2d.org).

---

## 🎮 Gameplay Overview

In **MineBound**, players take control of a hero to defend their ancient core while attempting to destroy the enemy core located across the arena:
- **Mine & Gather:** Harvest Gold nodes and Stone deposits scattered across the battlefield.
- **Build Defenses:** Place defensive Walls to stall creeps and build automated Laser Turrets that target enemy units.
- **Lane Combat:** Push with automated minion waves, engage in melee combat with enemy creeps, and eliminate hostile structures.
- **Win Condition:** Destroy the enemy Core structure ($0$ HP) to achieve victory before your own core falls.

---

## 🕹️ Controls

| Action | Keyboard / Mouse |
| :--- | :--- |
| **Move Hero** | `W`, `A`, `S`, `D` or `Arrow Keys` |
| **Attack** | `J` or `Left Click` |
| **Mine / Build Action** | `Space`, `K`, or `Right Click` |
| **Select Build Type** | `1` (Wall: 5 Stone) / `2` (Turret: 25 Gold, 10 Stone) |
| **Pause Game** | `Escape` |
| **Menu Confirm / Start** | `Enter` / `Return` / `Space` |

---

## 📦 Requirements & Running

### Requirements
- **[LÖVE 11.5+](https://love2d.org)**

### Running the Game

1. **Via Command Line (PowerShell / Terminal):**
   ```powershell
   # If 'love' is added to your PATH:
   love .

   # Or run directly via executable path (e.g., on Windows):
   & "C:\Program Files\LOVE\love.exe" .
   ```

2. **Via Drag & Drop:**
   - Drag and drop the root `MineBound` folder onto the `love.exe` application icon.

---

## 📂 Project Architecture

```plaintext
MineBound/
├── assets/
│   ├── audio/
│   │   ├── music/         # Background music tracks
│   │   └── sfx/           # Hit, mine, build, and explosion sound effects
│   └── textures/
│       ├── heroes/        # Hero spritesheets & animations
│       ├── tiles/         # Arena tiles (grass, stone, gold, wall, turret)
│       └── ui/            # UI icons & HUD elements
├── lib/
│   ├── anim8.lua          # Sprite animation and grid frame management
│   ├── class.lua          # OOP class inheritance library
│   ├── knife/             # Timer & event utilities
│   └── push.lua           # Virtual resolution handling (640x360 rendered to 1280x720)
├── src/
│   ├── entities/
│   │   ├── Core.lua       # Base structures and minion wave spawners
│   │   ├── Hero.lua       # Player entity (movement, combat, mining, building)
│   │   └── Minion.lua     # AI creeps (pathing, aggro, combat)
│   ├── states/
│   │   ├── BaseState.lua  # Base state template
│   │   ├── TitleState.lua # Main title menu screen & preview animation
│   │   ├── PlayState.lua  # Main gameplay loop, collision, HUD, particle FX
│   │   ├── PauseState.lua # Pause overlay
│   │   └── GameOverState.lua # Victory/Defeat end screen
│   ├── world/
│   │   ├── Grid.lua       # 2D arena grid manager and collision queries
│   │   └── Tile.lua       # Tile definitions (passable/solid, resource nodes, health)
│   ├── StateMachine.lua   # Finite state machine manager
│   └── Util.lua           # Texture and quad helper utilities
├── conf.lua               # LÖVE window configuration & dimensions
├── main.lua               # Game initialization, asset loader, and main hooks
├── CHANGELOG.md           # Version release notes and change history
└── README.md              # Project overview and documentation
```