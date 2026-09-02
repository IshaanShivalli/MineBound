import os
import math
import struct
import wave
from PIL import Image, ImageDraw

def ensure_dirs():
    dirs = [
        "assets/textures/heroes",
        "assets/textures/tiles",
        "assets/textures/ui",
        "assets/audio/sfx",
        "assets/audio/music"
    ]
    for d in dirs:
        os.makedirs(d, exist_ok=True)

def generate_hero_texture():
    # 24x24 frames, 4 frames: Idle, Walk 1, Walk 2, Attack
    img = Image.new("RGBA", (24 * 4, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Palette
    skin = (235, 185, 140, 255)
    armor_blue = (40, 90, 210, 255)
    armor_dark = (20, 45, 120, 255)
    gold = (245, 200, 50, 255)
    steel = (200, 215, 230, 255)
    steel_dark = (130, 145, 160, 255)
    shadow = (0, 0, 0, 80)

    # Helper to draw hero base
    def draw_base_hero(fx, leg_offset_left=0, leg_offset_right=0, sword_pos=0):
        # Shadow
        draw.ellipse([fx + 4, 20, fx + 20, 23], fill=shadow)
        
        # Legs
        draw.rectangle([fx + 7, 16 + leg_offset_left, fx + 10, 21 + leg_offset_left], fill=armor_dark)
        draw.rectangle([fx + 13, 16 + leg_offset_right, fx + 16, 21 + leg_offset_right], fill=armor_dark)
        
        # Body / Armor
        draw.rectangle([fx + 6, 8, fx + 17, 16], fill=armor_blue)
        draw.rectangle([fx + 9, 9, fx + 14, 15], fill=gold) # Chest crest
        
        # Head / Helmet
        draw.rectangle([fx + 7, 2, fx + 16, 8], fill=armor_dark)
        draw.rectangle([fx + 8, 4, fx + 15, 7], fill=skin) # Face
        draw.point((fx + 10, 5), fill=(20, 20, 20, 255)) # Eye L
        draw.point((fx + 13, 5), fill=(20, 20, 20, 255)) # Eye R
        draw.rectangle([fx + 6, 1, fx + 17, 3], fill=gold) # Helmet crown
        
        # Shield (left arm)
        draw.rectangle([fx + 4, 9, fx + 6, 15], fill=gold)
        draw.point((fx + 5, 12), fill=armor_blue)
        
        # Sword (right arm)
        if sword_pos == 0: # Idle
            draw.rectangle([fx + 17, 9, fx + 19, 14], fill=steel_dark)
            draw.line([fx + 18, 5, fx + 18, 11], fill=steel)
            draw.point((fx + 18, 4), fill=gold)
        elif sword_pos == 1: # Walking
            draw.rectangle([fx + 17, 10, fx + 19, 15], fill=steel_dark)
            draw.line([fx + 18, 6, fx + 18, 12], fill=steel)
        elif sword_pos == 2: # Attack slash
            draw.line([fx + 17, 10, fx + 23, 6], fill=steel, width=2)
            draw.point((fx + 23, 5), fill=gold)
            draw.arc([fx + 12, 1, fx + 23, 16], start=-45, end=90, fill=(255, 255, 255, 200))

    # Frame 0: Idle
    draw_base_hero(0, 0, 0, 0)
    # Frame 1: Walk 1
    draw_base_hero(24, -1, 1, 1)
    # Frame 2: Walk 2
    draw_base_hero(48, 1, -1, 1)
    # Frame 3: Attack
    draw_base_hero(72, 0, 0, 2)

    img.save("assets/textures/heroes/hero.png")

def generate_enemy_champion_texture():
    # 24x24 frames, 4 frames: Idle, Walk 1, Walk 2, Attack (Crimson / Obsidian Armored AI Champion)
    img = Image.new("RGBA", (24 * 4, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    skin = (210, 160, 130, 255)
    armor_crimson = (180, 25, 45, 255)
    armor_dark = (50, 10, 20, 255)
    purple_glow = (210, 50, 230, 255)
    steel_dark = (60, 60, 75, 255)
    shadow = (0, 0, 0, 80)

    def draw_base_champion(fx, leg_offset_left=0, leg_offset_right=0, sword_pos=0):
        draw.ellipse([fx + 4, 20, fx + 20, 23], fill=shadow)
        draw.rectangle([fx + 7, 16 + leg_offset_left, fx + 10, 21 + leg_offset_left], fill=armor_dark)
        draw.rectangle([fx + 13, 16 + leg_offset_right, fx + 16, 21 + leg_offset_right], fill=armor_dark)
        draw.rectangle([fx + 6, 8, fx + 17, 16], fill=armor_crimson)
        draw.rectangle([fx + 9, 9, fx + 14, 15], fill=purple_glow)
        draw.rectangle([fx + 7, 2, fx + 16, 8], fill=armor_dark)
        draw.rectangle([fx + 8, 4, fx + 15, 7], fill=skin)
        draw.point((fx + 10, 5), fill=(255, 30, 30, 255))
        draw.point((fx + 13, 5), fill=(255, 30, 30, 255))
        draw.rectangle([fx + 6, 1, fx + 17, 3], fill=purple_glow) # Horns/Crown
        draw.rectangle([fx + 4, 9, fx + 6, 15], fill=armor_crimson)
        draw.point((fx + 5, 12), fill=purple_glow)
        
        if sword_pos == 0:
            draw.rectangle([fx + 17, 9, fx + 19, 14], fill=steel_dark)
            draw.line([fx + 18, 5, fx + 18, 11], fill=purple_glow)
        elif sword_pos == 1:
            draw.rectangle([fx + 17, 10, fx + 19, 15], fill=steel_dark)
            draw.line([fx + 18, 6, fx + 18, 12], fill=purple_glow)
        elif sword_pos == 2:
            draw.line([fx + 17, 10, fx + 23, 6], fill=(255, 80, 120, 255), width=2)
            draw.arc([fx + 12, 1, fx + 23, 16], start=-45, end=90, fill=(255, 60, 180, 200))

    draw_base_champion(0, 0, 0, 0)
    draw_base_champion(24, -1, 1, 1)
    draw_base_champion(48, 1, -1, 1)
    draw_base_champion(72, 0, 0, 2)
    img.save("assets/textures/heroes/enemy_champion.png")

def generate_boss_texture():
    # 48x48 frames, 2 frames: Idle, Attack (The Ancient Void Golem)
    img = Image.new("RGBA", (48 * 2, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    for f in range(2):
        fx = f * 48
        draw.ellipse([fx + 6, 40, fx + 42, 46], fill=(0, 0, 0, 90))
        # Body / Torso
        draw.rectangle([fx + 10, 14, fx + 38, 38], fill=(30, 15, 45, 255), outline=(130, 40, 220, 255), width=2)
        # Core Eye
        draw.ellipse([fx + 18, 20, fx + 30, 32], fill=(220, 60, 255, 255), outline=(255, 200, 255, 255))
        draw.ellipse([fx + 22, 24, fx + 26, 28], fill=(255, 255, 255, 255))
        # Shoulder Armor
        draw.polygon([(fx + 4, 12), (fx + 12, 6), (fx + 14, 22)], fill=(70, 25, 100, 255))
        draw.polygon([(fx + 44, 12), (fx + 36, 6), (fx + 34, 22)], fill=(70, 25, 100, 255))
        # Fists / Arms
        arm_y = 20 if f == 0 else 12
        draw.rectangle([fx + 2, arm_y, fx + 10, arm_y + 18], fill=(50, 20, 75, 255), outline=(160, 50, 255, 255))
        draw.rectangle([fx + 38, arm_y, fx + 46, arm_y + 18], fill=(50, 20, 75, 255), outline=(160, 50, 255, 255))
        # Legs
        draw.rectangle([fx + 12, 36, fx + 20, 43], fill=(20, 10, 30, 255))
        draw.rectangle([fx + 28, 36, fx + 36, 43], fill=(20, 10, 30, 255))

    img.save("assets/textures/heroes/boss_golem.png")

def generate_minion_textures():
    for team, color, dark_color, fname in [
        ("player", (60, 130, 240, 255), (30, 70, 150, 255), "assets/textures/heroes/minion_player.png"),
        ("enemy", (230, 60, 60, 255), (140, 25, 25, 255), "assets/textures/heroes/minion_enemy.png"),
        ("void_player", (170, 70, 250, 255), (90, 20, 160, 255), "assets/textures/heroes/minion_void_player.png"),
        ("void_enemy", (240, 80, 180, 255), (150, 20, 90, 255), "assets/textures/heroes/minion_void_enemy.png")
    ]:
        # 16x16 frames, 2 frames: Walk 1, Walk 2
        img = Image.new("RGBA", (16 * 2, 16), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        for f in range(2):
            fx = f * 16
            # Shadow
            draw.ellipse([fx + 3, 13, fx + 13, 15], fill=(0, 0, 0, 70))
            
            # Legs
            if f == 0:
                draw.rectangle([fx + 5, 11, fx + 7, 14], fill=dark_color)
                draw.rectangle([fx + 9, 10, fx + 11, 13], fill=dark_color)
            else:
                draw.rectangle([fx + 5, 10, fx + 7, 13], fill=dark_color)
                draw.rectangle([fx + 9, 11, fx + 11, 14], fill=dark_color)
                
            # Body
            draw.rectangle([fx + 4, 4, fx + 12, 11], fill=color)
            draw.rectangle([fx + 5, 3, fx + 11, 5], fill=dark_color) # Helmet
            # Eyes
            eye_col = (255, 255, 255, 255) if "void" not in team else (100, 255, 230, 255)
            draw.point((fx + 6, 7), fill=eye_col)
            draw.point((fx + 9, 7), fill=eye_col)
            # Spear / Wand
            draw.line([fx + 12, 2, fx + 12, 13], fill=(180, 190, 200, 255))
            draw.point((fx + 12, 1), fill=(240, 210, 60, 255) if "void" not in team else (200, 100, 255, 255))
            
        img.save(fname)

def generate_tileset():
    # 15 tiles of 32x32:
    # 0: Grass Floor (Overworld)
    # 1: Stone Wall (Overworld)
    # 2: Gold Ore (Overworld)
    # 3: Crystal Ore (Overworld)
    # 4: Player Turret (Overworld)
    # 5: Enemy Turret (Overworld)
    # 6: Player Core (Overworld)
    # 7: Enemy Core (Overworld)
    # 8: Void Floor (Nether)
    # 9: Void Stone / Obsidian Wall (Nether)
    # 10: Void Essence / Soul Crystal (Nether)
    # 11: Rift Portal (Dimensional Shift Gate)
    # 12: Player Nether Anchor / Siphon
    # 13: Enemy Nether Anchor / Siphon
    # 14: Healing Chamber Sanctuary
    img = Image.new("RGBA", (32 * 15, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Grass / Arena Floor (Overworld)
    fx = 0 * 32
    draw.rectangle([fx, 0, fx + 31, 31], fill=(45, 52, 64, 255))
    draw.rectangle([fx + 1, 1, fx + 30, 30], fill=(53, 62, 77, 255))
    draw.point((fx + 8, 8), fill=(70, 82, 102, 255))
    draw.point((fx + 24, 22), fill=(70, 82, 102, 255))
    draw.point((fx + 12, 24), fill=(38, 44, 56, 255))
    draw.rectangle([fx, 0, fx + 31, 31], outline=(38, 44, 56, 120))

    # 2. Stone Wall Block (Overworld)
    fx = 1 * 32
    draw.rectangle([fx, 0, fx + 31, 31], fill=(110, 115, 128, 255))
    draw.rectangle([fx + 2, 2, fx + 29, 29], fill=(130, 136, 150, 255))
    draw.line([fx, 15, fx + 31, 15], fill=(80, 85, 95, 255), width=2)
    draw.line([fx + 15, 0, fx + 15, 15], fill=(80, 85, 95, 255), width=2)
    draw.line([fx + 8, 16, fx + 8, 31], fill=(80, 85, 95, 255), width=2)
    draw.line([fx + 24, 16, fx + 24, 31], fill=(80, 85, 95, 255), width=2)
    draw.rectangle([fx, 0, fx + 31, 31], outline=(60, 65, 75, 255))

    # 3. Gold Ore
    fx = 2 * 32
    draw.rectangle([fx, 0, fx + 31, 31], fill=(70, 75, 85, 255))
    draw.rectangle([fx + 2, 2, fx + 29, 29], fill=(90, 95, 105, 255))
    gold_c = (255, 215, 0, 255)
    gold_l = (255, 240, 120, 255)
    draw.polygon([(fx + 8, 12), (fx + 14, 6), (fx + 18, 14), (fx + 12, 18)], fill=gold_c)
    draw.polygon([(fx + 16, 20), (fx + 22, 14), (fx + 26, 22), (fx + 20, 26)], fill=gold_c)
    draw.polygon([(fx + 8, 12), (fx + 14, 6), (fx + 14, 10)], fill=gold_l)
    draw.polygon([(fx + 16, 20), (fx + 22, 14), (fx + 22, 18)], fill=gold_l)
    draw.rectangle([fx, 0, fx + 31, 31], outline=(50, 55, 65, 255))

    # 4. Crystal Ore (Mana / Rare)
    fx = 3 * 32
    draw.rectangle([fx, 0, fx + 31, 31], fill=(65, 70, 85, 255))
    draw.rectangle([fx + 2, 2, fx + 29, 29], fill=(80, 85, 105, 255))
    cyan_c = (40, 220, 240, 255)
    cyan_l = (180, 250, 255, 255)
    draw.polygon([(fx + 14, 4), (fx + 20, 12), (fx + 16, 26), (fx + 10, 16)], fill=cyan_c)
    draw.polygon([(fx + 14, 4), (fx + 16, 12), (fx + 10, 16)], fill=cyan_l)
    draw.rectangle([fx, 0, fx + 31, 31], outline=(50, 55, 70, 255))

    # 5. Player Turret
    fx = 4 * 32
    draw.rectangle([fx, 0, fx + 31, 31], fill=(53, 62, 77, 255))
    draw.ellipse([fx + 4, 4, fx + 27, 27], fill=(80, 85, 95, 255), outline=(40, 90, 210, 255), width=2)
    draw.ellipse([fx + 9, 9, fx + 22, 22], fill=(40, 90, 210, 255))
    draw.rectangle([fx + 14, 2, fx + 17, 12], fill=(220, 230, 240, 255))

    # 6. Enemy Turret
    fx = 5 * 32
    draw.rectangle([fx, 0, fx + 31, 31], fill=(53, 62, 77, 255))
    draw.ellipse([fx + 4, 4, fx + 27, 27], fill=(80, 85, 95, 255), outline=(220, 50, 50, 255), width=2)
    draw.ellipse([fx + 9, 9, fx + 22, 22], fill=(220, 50, 50, 255))
    draw.rectangle([fx + 14, 2, fx + 17, 12], fill=(220, 230, 240, 255))

    # 7. Player Core (Nexus)
    fx = 6 * 32
    draw.rectangle([fx, 0, fx + 31, 31], fill=(35, 45, 65, 255))
    draw.rectangle([fx + 2, 2, fx + 29, 29], fill=(50, 70, 110, 255))
    draw.polygon([(fx + 16, 4), (fx + 27, 16), (fx + 16, 27), (fx + 5, 16)], fill=(60, 140, 255, 255), outline=(180, 220, 255, 255), width=2)
    draw.polygon([(fx + 16, 8), (fx + 23, 16), (fx + 16, 23), (fx + 9, 16)], fill=(220, 245, 255, 255))

    # 8. Enemy Core (Nexus)
    fx = 7 * 32
    draw.rectangle([fx, 0, fx + 31, 31], fill=(65, 35, 35, 255))
    draw.rectangle([fx + 2, 2, fx + 29, 29], fill=(110, 50, 50, 255))
    draw.polygon([(fx + 16, 4), (fx + 27, 16), (fx + 16, 27), (fx + 5, 16)], fill=(255, 60, 60, 255), outline=(255, 180, 180, 255), width=2)
    draw.polygon([(fx + 16, 8), (fx + 23, 16), (fx + 16, 23), (fx + 9, 16)], fill=(255, 230, 230, 255))

    # 9. Void Floor (Nether Realm)
    fx = 8 * 32
    draw.rectangle([fx, 0, fx + 31, 31], fill=(25, 15, 35, 255))
    draw.rectangle([fx + 1, 1, fx + 30, 30], fill=(35, 20, 50, 255))
    draw.point((fx + 6, 6), fill=(75, 35, 105, 255))
    draw.point((fx + 20, 18), fill=(75, 35, 105, 255))
    draw.line([fx + 10, 20, fx + 16, 26], fill=(55, 25, 80, 255))
    draw.rectangle([fx, 0, fx + 31, 31], outline=(18, 10, 26, 180))

    # 10. Void Stone / Obsidian Wall (Nether Realm)
    fx = 9 * 32
    draw.rectangle([fx, 0, fx + 31, 31], fill=(45, 20, 65, 255))
    draw.rectangle([fx + 2, 2, fx + 29, 29], fill=(60, 30, 85, 255))
    draw.line([fx, 15, fx + 31, 15], fill=(30, 12, 45, 255), width=2)
    draw.line([fx + 15, 0, fx + 15, 15], fill=(30, 12, 45, 255), width=2)
    draw.line([fx + 8, 16, fx + 8, 31], fill=(30, 12, 45, 255), width=2)
    draw.line([fx + 24, 16, fx + 24, 31], fill=(30, 12, 45, 255), width=2)
    draw.point((fx + 12, 8), fill=(180, 70, 250, 255))
    draw.point((fx + 20, 24), fill=(180, 70, 250, 255))
    draw.rectangle([fx, 0, fx + 31, 31], outline=(20, 8, 32, 255))

    # 11. Soul Crystal / Void Essence Ore (Nether Realm)
    fx = 10 * 32
    draw.rectangle([fx, 0, fx + 31, 31], fill=(35, 20, 50, 255))
    draw.rectangle([fx + 2, 2, fx + 29, 29], fill=(48, 25, 70, 255))
    purple_c = (190, 70, 255, 255)
    purple_l = (235, 170, 255, 255)
    draw.polygon([(fx + 14, 3), (fx + 22, 12), (fx + 17, 27), (fx + 9, 17)], fill=purple_c)
    draw.polygon([(fx + 14, 3), (fx + 17, 12), (fx + 9, 17)], fill=purple_l)
    draw.polygon([(fx + 20, 18), (fx + 26, 14), (fx + 28, 22), (fx + 22, 26)], fill=purple_c)
    draw.rectangle([fx, 0, fx + 31, 31], outline=(25, 12, 38, 255))

    # 12. Rift Portal (Dimensional Shift Gate)
    fx = 11 * 32
    draw.rectangle([fx, 0, fx + 31, 31], fill=(20, 15, 30, 255))
    draw.ellipse([fx + 3, 3, fx + 28, 28], fill=(60, 20, 100, 255), outline=(130, 240, 255, 255), width=2)
    draw.ellipse([fx + 7, 7, fx + 24, 24], fill=(160, 50, 240, 255))
    draw.ellipse([fx + 11, 11, fx + 20, 20], fill=(220, 250, 255, 255))

    # 13. Player Nether Anchor
    fx = 12 * 32
    draw.rectangle([fx, 0, fx + 31, 31], fill=(25, 35, 60, 255))
    draw.rectangle([fx + 2, 2, fx + 29, 29], fill=(35, 55, 95, 255))
    draw.polygon([(fx + 16, 2), (fx + 28, 16), (fx + 16, 30), (fx + 4, 16)], fill=(50, 180, 255, 255), outline=(150, 230, 255, 255), width=2)
    draw.ellipse([fx + 11, 11, fx + 21, 21], fill=(240, 250, 255, 255))

    # 14. Enemy Nether Anchor
    fx = 13 * 32
    draw.rectangle([fx, 0, fx + 31, 31], fill=(55, 20, 45, 255))
    draw.rectangle([fx + 2, 2, fx + 29, 29], fill=(85, 25, 65, 255))
    draw.polygon([(fx + 16, 2), (fx + 28, 16), (fx + 16, 30), (fx + 4, 16)], fill=(240, 60, 160, 255), outline=(255, 170, 220, 255), width=2)
    draw.ellipse([fx + 11, 11, fx + 21, 21], fill=(255, 230, 245, 255))

    # 15. Healing Chamber (Green / Golden Sanctuary with Cross and Aura)
    fx = 14 * 32
    draw.rectangle([fx, 0, fx + 31, 31], fill=(20, 50, 35, 255))
    draw.rectangle([fx + 2, 2, fx + 29, 29], fill=(30, 80, 55, 255))
    draw.ellipse([fx + 4, 4, fx + 27, 27], fill=(40, 120, 75, 255), outline=(100, 255, 180, 255), width=2)
    # Bright medical / healing cross
    draw.rectangle([fx + 13, 8, fx + 18, 23], fill=(255, 255, 255, 255))
    draw.rectangle([fx + 8, 13, fx + 23, 18], fill=(255, 255, 255, 255))
    draw.rectangle([fx + 14, 9, fx + 17, 22], fill=(60, 240, 120, 255))
    draw.rectangle([fx + 9, 14, fx + 22, 17], fill=(60, 240, 120, 255))

    img.save("assets/textures/tiles/tileset.png")

def generate_ui_texture():
    # 6 icons 16x16:
    # 0: Heart, 1: Gold Coin, 2: Stone, 3: Void Essence, 4: Sword/Attack, 5: Pickaxe/Build
    img = Image.new("RGBA", (16 * 6, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 0. Heart
    fx = 0
    draw.polygon([(fx + 2, 5), (fx + 5, 2), (fx + 8, 5), (fx + 11, 2), (fx + 14, 5), (fx + 8, 14)], fill=(230, 40, 50, 255))
    draw.point((fx + 4, 4), fill=(255, 180, 180, 255))

    # 1. Gold Coin
    fx = 16
    draw.ellipse([fx + 2, 2, fx + 13, 13], fill=(255, 200, 30, 255), outline=(190, 140, 10, 255))
    draw.point((fx + 6, 5), fill=(255, 245, 160, 255))
    draw.text((fx + 5, 3), "$", fill=(160, 110, 0, 255))

    # 2. Stone
    fx = 32
    draw.polygon([(fx + 4, 3), (fx + 12, 3), (fx + 14, 8), (fx + 11, 13), (fx + 3, 11)], fill=(150, 155, 165, 255), outline=(90, 95, 105, 255))
    draw.polygon([(fx + 4, 3), (fx + 8, 3), (fx + 7, 7), (fx + 3, 6)], fill=(190, 195, 205, 255))

    # 3. Void Essence (Purple gem)
    fx = 48
    draw.polygon([(fx + 8, 1), (fx + 14, 7), (fx + 8, 14), (fx + 2, 7)], fill=(190, 60, 255, 255), outline=(120, 20, 180, 255))
    draw.polygon([(fx + 8, 3), (fx + 12, 7), (fx + 8, 11), (fx + 4, 7)], fill=(240, 180, 255, 255))

    # 4. Sword
    fx = 64
    draw.line([fx + 3, 13, fx + 12, 4], fill=(220, 230, 240, 255), width=2)
    draw.line([fx + 2, 10, fx + 6, 14], fill=(240, 190, 40, 255)) # Guard
    draw.point((fx + 1, 15), fill=(160, 110, 20, 255)) # Hilt

    # 5. Pickaxe
    fx = 80
    draw.line([fx + 3, 13, fx + 13, 3], fill=(160, 100, 50, 255), width=2)
    draw.arc([fx + 6, 2, fx + 14, 10], start=180, end=330, fill=(180, 190, 205, 255), width=2)

    img.save("assets/textures/ui/ui.png")

def make_wav(filename, duration, sample_rate=44100, gen_func=None):
    num_samples = int(duration * sample_rate)
    samples = []
    for i in range(num_samples):
        t = i / sample_rate
        val = gen_func(t, i, num_samples)
        val = max(-1.0, min(1.0, val))
        samples.append(int(val * 32767))

    with wave.open(filename, 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(struct.pack(f'<{len(samples)}h', *samples))

def generate_audio():
    # 1. Hit SFX (Punchy noise + downward pitch)
    def hit_gen(t, i, total):
        env = max(0.0, 1.0 - (t / 0.15))
        freq = 350.0 * (1.0 - t / 0.15) + 60.0
        sine = math.sin(2 * math.pi * freq * t)
        noise = (((i * 1103515245 + 12345) & 0x7FFF) / 0x3FFF - 1.0) * 0.3
        return (sine * 0.7 + noise) * env * 0.8
    make_wav("assets/audio/sfx/hit.wav", 0.15, gen_func=hit_gen)

    # 2. Mine SFX (High metallic clink + resonance)
    def mine_gen(t, i, total):
        env = max(0.0, (1.0 - t / 0.2) ** 2)
        sine1 = math.sin(2 * math.pi * 920.0 * t)
        sine2 = math.sin(2 * math.pi * 1840.0 * t) * 0.5
        return (sine1 + sine2) * env * 0.6
    make_wav("assets/audio/sfx/mine.wav", 0.2, gen_func=mine_gen)

    # 3. Build SFX (Ascending blip / thud)
    def build_gen(t, i, total):
        env = max(0.0, 1.0 - t / 0.18)
        freq = 200.0 + 400.0 * (t / 0.18)
        sine = math.sin(2 * math.pi * freq * t)
        return (1.0 if sine > 0 else -1.0) * 0.3 * env
    make_wav("assets/audio/sfx/build.wav", 0.18, gen_func=build_gen)

    # 4. Shoot SFX (Turret laser / pew)
    def shoot_gen(t, i, total):
        env = max(0.0, 1.0 - t / 0.14)
        freq = 800.0 * (1.0 - t / 0.14) ** 2 + 150.0
        return math.sin(2 * math.pi * freq * t) * env * 0.6
    make_wav("assets/audio/sfx/shoot.wav", 0.14, gen_func=shoot_gen)

    # 5. Core Hit SFX (Heavy bass impact + alarm rumble)
    def core_hit_gen(t, i, total):
        env = max(0.0, 1.0 - t / 0.35)
        freq = 90.0 * (1.0 - t / 0.35) + 40.0
        bass = math.sin(2 * math.pi * freq * t)
        noise = (((i * 1664525 + 1013904223) & 0x7FFF) / 0x3FFF - 1.0) * 0.4
        return (bass * 0.8 + noise) * env * 0.9
    make_wav("assets/audio/sfx/core_hit.wav", 0.35, gen_func=core_hit_gen)

    # 6. Dimension Shift SFX (Warp whoosh + high resonance shimmer)
    def shift_gen(t, i, total):
        env = max(0.0, 1.0 - (t / 0.4))
        freq = 220.0 + 580.0 * math.sin(math.pi * (t / 0.4))
        wobble = math.sin(2 * math.pi * 35.0 * t) * 60.0
        sine = math.sin(2 * math.pi * (freq + wobble) * t)
        noise = (((i * 48271) & 0x7FFF) / 0x3FFF - 1.0) * 0.25 * math.sin(math.pi * (t / 0.4))
        return (sine * 0.7 + noise) * env * 0.85
    make_wav("assets/audio/sfx/shift.wav", 0.4, gen_func=shift_gen)

    # 7. Victory SFX
    def victory_gen(t, i, total):
        notes = [261.63, 329.63, 392.00, 523.25, 659.25, 783.99]
        seg = min(int(t / 0.15), len(notes) - 1)
        freq = notes[seg]
        env = max(0.0, 1.0 - (t / 1.0))
        sine = math.sin(2 * math.pi * freq * t)
        return (1.0 if sine > 0 else -1.0) * 0.25 * env
    make_wav("assets/audio/sfx/victory.wav", 1.0, gen_func=victory_gen)

    # 8. Defeat SFX
    def defeat_gen(t, i, total):
        notes = [440.0, 415.30, 392.00, 349.23, 311.13, 261.63]
        seg = min(int(t / 0.18), len(notes) - 1)
        freq = notes[seg]
        env = max(0.0, 1.0 - (t / 1.2))
        sine = math.sin(2 * math.pi * freq * t)
        return (1.0 if sine > 0 else -1.0) * 0.25 * env
    make_wav("assets/audio/sfx/defeat.wav", 1.2, gen_func=defeat_gen)

    # 9. Background Music BGM
    def bgm_gen(t, i, total):
        bpm = 120
        beat = (t * (bpm / 60.0)) % 16
        bass_notes = [110.0, 110.0, 130.81, 146.83, 110.0, 110.0, 164.81, 146.83]
        bass_freq = bass_notes[int(beat / 2) % len(bass_notes)]
        melody_notes = [
            220.0, 0, 261.63, 293.66, 329.63, 293.66, 261.63, 220.0,
            329.63, 392.00, 440.0, 392.00, 329.63, 293.66, 261.63, 220.0
        ]
        mel_freq = melody_notes[int(beat) % len(melody_notes)]
        bass = (1.0 if math.sin(2 * math.pi * bass_freq * t) > 0 else -1.0) * 0.15
        mel = 0.0
        if mel_freq > 0:
            mel_env = max(0.0, 1.0 - (beat % 1.0) * 0.8)
            mel = (1.0 if math.sin(2 * math.pi * mel_freq * t) > 0 else -1.0) * 0.12 * mel_env
        hihat_env = max(0.0, 1.0 - ((beat * 2) % 1.0) * 5.0)
        noise = (((i * 48271) & 0x7FFF) / 0x3FFF - 1.0) * 0.05 * hihat_env
    # 10. Dash SFX (Fast air rush)
    def dash_gen(t, i, total):
        env = max(0.0, 1.0 - (t / 0.18))
        noise = (((i * 1664525 + 1013904223) & 0x7FFF) / 0x3FFF - 1.0) * 0.7
        freq = 600.0 * (1.0 - t / 0.18) + 100.0
        sine = math.sin(2 * math.pi * freq * t)
        return (noise * 0.7 + sine * 0.4) * env
    make_wav("assets/audio/sfx/dash.wav", 0.18, gen_func=dash_gen)

    # 11. Ultimate Shockwave SFX (Thunderous bass blast + resonance)
    def ult_gen(t, i, total):
        env = max(0.0, 1.0 - (t / 0.6))
        freq = 80.0 * (1.0 - t / 0.6) + 35.0
        bass = math.sin(2 * math.pi * freq * t)
        sub = math.sin(2 * math.pi * (freq * 0.5) * t) * 0.8
        noise = (((i * 48271) & 0x7FFF) / 0x3FFF - 1.0) * 0.4
        return (bass + sub + noise) * env * 0.95
    make_wav("assets/audio/sfx/ult.wav", 0.6, gen_func=ult_gen)

    # 12. Tech Shop Upgrade SFX (Chime arpeggio)
    def upgrade_gen(t, i, total):
        notes = [523.25, 659.25, 783.99, 1046.50]
        seg = min(int(t / 0.08), len(notes) - 1)
        freq = notes[seg]
        env = max(0.0, 1.0 - (t / 0.35))
        sine = math.sin(2 * math.pi * freq * t)
        return sine * 0.3 * env
    make_wav("assets/audio/sfx/upgrade.wav", 0.35, gen_func=upgrade_gen)

    # 13. Storm Alert SFX (Rumble & high alert horn)
    def storm_gen(t, i, total):
        env = max(0.0, 1.0 - (t / 0.8))
        freq = 440.0 if (int(t * 8) % 2 == 0) else 554.37
        sine = math.sin(2 * math.pi * freq * t)
        rumble = math.sin(2 * math.pi * 45.0 * t) * 0.6
        return (sine * 0.3 + rumble) * env * 0.8
    make_wav("assets/audio/sfx/storm.wav", 0.8, gen_func=storm_gen)

if __name__ == "__main__":
    ensure_dirs()
    generate_hero_texture()
    generate_enemy_champion_texture()
    generate_boss_texture()
    generate_minion_textures()
    generate_tileset()
    generate_ui_texture()
    generate_audio()
    print("All assets generated successfully!")
