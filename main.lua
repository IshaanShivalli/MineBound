push = require 'lib.push'
anim8 = require 'lib.anim8'
Class = require 'lib.class'
Timer = require 'lib.knife.timer'
Event = require 'lib.knife.event'

require 'src.Util'
require 'src.StateMachine'

local BaseState = require 'src.states.BaseState'
local TitleState = require 'src.states.TitleState'
local PlayState = require 'src.states.PlayState'
local PauseState = require 'src.states.PauseState'
local GameOverState = require 'src.states.GameOverState'

local VIRTUAL_WIDTH = 640
local VIRTUAL_HEIGHT = 360

local WINDOW_WIDTH = 1280
local WINDOW_HEIGHT = 720

gTextures = {}
gFrames = {}
gSounds = {}
gFonts = {}

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    math.randomseed(os.time())

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        vsync = true,
        fullscreen = false,
        resizable = false,
        title = 'MineBound',
    })

    -- Load Fonts
    gFonts = {
        ['small'] = love.graphics.newFont(8),
        ['medium'] = love.graphics.newFont(14),
        ['large'] = love.graphics.newFont(24),
        ['title'] = love.graphics.newFont(32),
    }

    -- Load Textures
    gTextures = {
        ['hero'] = love.graphics.newImage('assets/textures/heroes/hero.png'),
        ['minion_player'] = love.graphics.newImage('assets/textures/heroes/minion_player.png'),
        ['minion_enemy'] = love.graphics.newImage('assets/textures/heroes/minion_enemy.png'),
        ['minion_void_player'] = love.graphics.newImage('assets/textures/heroes/minion_void_player.png'),
        ['minion_void_enemy'] = love.graphics.newImage('assets/textures/heroes/minion_void_enemy.png'),
        ['tileset'] = love.graphics.newImage('assets/textures/tiles/tileset.png'),
        ['ui'] = love.graphics.newImage('assets/textures/ui/ui.png'),
    }

    -- Generate Quads
    gFrames = {
        ['hero'] = GenerateQuads(gTextures['hero'], 24, 24),
        ['minion_player'] = GenerateQuads(gTextures['minion_player'], 16, 16),
        ['minion_enemy'] = GenerateQuads(gTextures['minion_enemy'], 16, 16),
        ['minion_void_player'] = GenerateQuads(gTextures['minion_void_player'], 16, 16),
        ['minion_void_enemy'] = GenerateQuads(gTextures['minion_void_enemy'], 16, 16),
        ['tiles'] = GenerateQuads(gTextures['tileset'], 32, 32),
        ['ui'] = GenerateQuads(gTextures['ui'], 16, 16),
    }

    -- Load Audio
    gSounds = {
        ['hit'] = love.audio.newSource('assets/audio/sfx/hit.wav', 'static'),
        ['mine'] = love.audio.newSource('assets/audio/sfx/mine.wav', 'static'),
        ['build'] = love.audio.newSource('assets/audio/sfx/build.wav', 'static'),
        ['shoot'] = love.audio.newSource('assets/audio/sfx/shoot.wav', 'static'),
        ['shift'] = love.audio.newSource('assets/audio/sfx/shift.wav', 'static'),
        ['core_hit'] = love.audio.newSource('assets/audio/sfx/core_hit.wav', 'static'),
        ['victory'] = love.audio.newSource('assets/audio/sfx/victory.wav', 'static'),
        ['defeat'] = love.audio.newSource('assets/audio/sfx/defeat.wav', 'static'),
        ['bgm'] = love.audio.newSource('assets/audio/music/bgm.wav', 'stream'),
    }

    gSounds['bgm']:setLooping(true)
    gSounds['bgm']:setVolume(0.4)
    gSounds['bgm']:play()

    gStateMachine = StateMachine {
        ['title'] = function() return TitleState() end,
        ['play'] = function() return PlayState() end,
        ['pause'] = function() return PauseState() end,
        ['gameover'] = function() return GameOverState() end,
    }

    gStateMachine:change('title')
end

function love.update(dt)
    Timer.update(dt)
    gStateMachine:update(dt)
end

function love.draw()
    push:apply('start')
    gStateMachine:render()
    push:apply('end')
end

function love.keypressed(key)
    if gStateMachine.current.keypressed then
        gStateMachine.current:keypressed(key)
    end
end

function love.mousepressed(x, y, button)
    local gameX, gameY = push:toGame(x, y)
    if gameX and gStateMachine.current.mousepressed then
        gStateMachine.current:mousepressed(gameX, gameY, button)
    end
end