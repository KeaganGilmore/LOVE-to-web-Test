-- main.lua

local http = require("socket.http")
local ltn12 = require("ltn12")

-- API URL
local apiUrl = "https://jsonplaceholder.typicode.com/todos/1"

-- Response holder
local response = {}

-- Load audio
local bgMusic
local clickSound

-- Load shader
local shader

-- Timer for periodic API calls
local timer = 0
local interval = 5 -- seconds

-- Player setup
local player = {
    x = 400,
    y = 300,
    speed = 200
}

-- Asynchronous API call function
local function asyncApiCall()
    local co = coroutine.create(function()
        local res, code, headers, status = http.request {
            url = apiUrl,
            sink = ltn12.sink.table(response)
        }
        
        if res == 1 and code == 200 then
            print("API call successful")
        else
            print("API call failed with status: " .. status)
        end
        
        coroutine.yield()
    end)
    
    coroutine.resume(co)
end

function love.load()
    -- Load background music and set it to loop
    bgMusic = love.audio.newSource("sound.mp3", "stream")
    bgMusic:setLooping(true)
    bgMusic:play()
    
    -- Load click sound
    clickSound = love.audio.newSource("happy.flac", "static")
    
    -- Load shader
    shader = love.graphics.newShader[[
        extern number time;
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec4 pixel = Texel(texture, texture_coords);
            return pixel * vec4(sin(time), cos(time), sin(time * 2.0), 1.0);
        }
    ]]
    
    -- Start initial asynchronous API call
    asyncApiCall()
end

function love.update(dt)
    -- Update shader time
    shader:send("time", love.timer.getTime())
    
    -- Update timer
    timer = timer + dt
    if timer >= interval then
        -- Reset timer
        timer = 0
        -- Start asynchronous API call
        asyncApiCall()
    end

    -- Update player position
    if love.keyboard.isDown("up") then
        player.y = player.y - player.speed * dt
    end
    if love.keyboard.isDown("down") then
        player.y = player.y + player.speed * dt
    end
    if love.keyboard.isDown("left") then
        player.x = player.x - player.speed * dt
    end
    if love.keyboard.isDown("right") then
        player.x = player.x + player.speed * dt
    end
end

function love.draw()
    -- Apply shader
    love.graphics.setShader(shader)
    
    -- Draw a rectangle
    love.graphics.rectangle("fill", 100, 100, 200, 200)
    
    -- Reset shader
    love.graphics.setShader()
    
    -- Draw text
    love.graphics.print("LOVE2D Browser Test", 100, 50)
    
    -- Display API response
    love.graphics.print("Response:", 10, 10)
    for i, line in ipairs(response) do
        love.graphics.print(line, 10, 30 + 20 * i)
    end
    
    -- Draw player
    love.graphics.setColor(0, 1, 0) -- Set color to green
    love.graphics.rectangle("fill", player.x, player.y, 50, 50)
    love.graphics.setColor(1, 1, 1) -- Reset color to white
end

function love.keypressed(key)
    -- Restart API call on 'r' key press
    if key == "r" then
        response = {}
        asyncApiCall()
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    -- Play happy.flac on mouse click
    if button == 1 then -- Left mouse button
        clickSound:play()
    end
end
