function love.conf(t)
    t.title = "MineBound"
    t.version = "11.5"
    t.console = false

    t.window.width = 1280
    t.window.height = 720
    t.window.vsync = 1
    t.window.resizable = false
    t.window.minwidth = 640
    t.window.minheight = 360

    t.identity = "MineBound"

    t.modules.joystick = false
    t.modules.physics = false
end