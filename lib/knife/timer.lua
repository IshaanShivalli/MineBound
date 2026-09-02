--
-- knife.timer
--
local timer = {}

local tasks = {}

local function removeTask(i)
    tasks[i] = tasks[#tasks]
    tasks[#tasks] = nil
end

function timer.after(duration, fn)
    local task = {
        duration = duration,
        time = 0,
        fn = fn,
        update = function(self, dt)
            self.time = self.time + dt
            if self.time >= self.duration then
                self.fn()
                return true
            end
            return false
        end
    }
    table.insert(tasks, task)
    return task
end

function timer.every(interval, fn, limit)
    local count = 0
    local task = {
        interval = interval,
        time = 0,
        fn = fn,
        limit = limit,
        update = function(self, dt)
            self.time = self.time + dt
            while self.time >= self.interval do
                self.time = self.time - self.interval
                count = count + 1
                self.fn()
                if self.limit and count >= self.limit then
                    return true
                end
            end
            return false
        end
    }
    table.insert(tasks, task)
    return task
end

function timer.during(duration, fn, after)
    local task = {
        duration = duration,
        time = 0,
        fn = fn,
        after = after,
        update = function(self, dt)
            self.time = self.time + dt
            if self.time < self.duration then
                self.fn(dt)
                return false
            else
                self.fn(dt)
                if self.after then self.after() end
                return true
            end
        end
    }
    table.insert(tasks, task)
    return task
end

function timer.tween(duration, def)
    local time = 0
    local subjects = {}
    for target, props in pairs(def) do
        for k, v in pairs(props) do
            table.insert(subjects, {
                target = target,
                key = k,
                from = target[k],
                to = v
            })
        end
    end

    local task = {
        duration = duration,
        time = 0,
        update = function(self, dt)
            self.time = self.time + dt
            local t = math.min(self.time / self.duration, 1)
            for _, s in ipairs(subjects) do
                s.target[s.key] = s.from + (s.to - s.from) * t
            end
            return t >= 1
        end
    }
    table.insert(tasks, task)
    return task
end

function timer.cancel(handle)
    for i = #tasks, 1, -1 do
        if tasks[i] == handle then
            removeTask(i)
            return true
        end
    end
    return false
end

function timer.clear()
    tasks = {}
end

function timer.update(dt)
    for i = #tasks, 1, -1 do
        if tasks[i]:update(dt) then
            removeTask(i)
        end
    end
end

return timer
