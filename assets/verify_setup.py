import os
import sys

def verify():
    # Check assets
    assets = [
        "assets/textures/heroes/hero.png",
        "assets/textures/heroes/minion_player.png",
        "assets/textures/heroes/minion_enemy.png",
        "assets/textures/tiles/tileset.png",
        "assets/textures/ui/ui.png",
        "assets/audio/sfx/hit.wav",
        "assets/audio/sfx/mine.wav",
        "assets/audio/sfx/build.wav",
        "assets/audio/sfx/shoot.wav",
        "assets/audio/sfx/core_hit.wav",
        "assets/audio/sfx/victory.wav",
        "assets/audio/sfx/defeat.wav",
        "assets/audio/music/bgm.wav"
    ]
    missing = []
    for a in assets:
        if not os.path.exists(a):
            missing.append(a)
    
    if missing:
        print(f"Missing assets: {missing}")
        return False
    else:
        print("All assets exist!")

    # Check Lua files
    lua_files = [
        "conf.lua",
        "main.lua",
        "lib/class.lua",
        "lib/anim8.lua",
        "lib/push.lua",
        "lib/knife/init.lua",
        "lib/knife/timer.lua",
        "lib/knife/event.lua",
        "src/StateMachine.lua",
        "src/Util.lua",
        "src/world/Tile.lua",
        "src/world/Grid.lua",
        "src/entities/Hero.lua",
        "src/entities/Minion.lua",
        "src/entities/Core.lua",
        "src/states/BaseState.lua",
        "src/states/TitleState.lua",
        "src/states/PlayState.lua",
        "src/states/PauseState.lua",
        "src/states/GameOverState.lua"
    ]

    for lf in lua_files:
        if not os.path.exists(lf):
            print(f"Missing Lua file: {lf}")
            return False
        with open(lf, 'r', encoding='utf-8') as f:
            content = f.read()
            if len(content.strip()) == 0:
                print(f"Empty Lua file: {lf}")
                return False

    print("All Lua files verified and present!")
    return True

if __name__ == "__main__":
    if verify():
        print("VERIFICATION SUCCESSFUL")
    else:
        sys.exit(1)
