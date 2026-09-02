BaseState = Class{}

function BaseState:init() end

function BaseState:enter(params) end

function BaseState:exit() end

function BaseState:update(dt) end

function BaseState:render() end

function BaseState:keypressed(key) end

function BaseState:mousepressed(x, y, button) end

return BaseState