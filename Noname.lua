--==================================================
-- AUTO LOW LAG (CHẠY NGAY KHI LOAD)
--==================================================
task.spawn(function()
    local Lighting = game:GetService("Lighting")
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 1
    for _,v in pairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") then v:Destroy() end
    end
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.Plastic
            v.CastShadow = false
            v.Reflectance = 0
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Enabled = false
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        end
    end
end)

--==================================================
-- BIẾN CHÍNH
--==================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local VIM = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local enabled = false
local safePaused = false

-- Cấu hình
local attackMode = "Melee" -- Melee / Fruit / Sword / Gun
local attackRange = 12
local attackSpeed = 0.25
local attackHeight = 3
local lifeStealHP = 0.6
local lifeStealCooldown = 3
local lastZ = 0

--==================================================
-- UI (REDZ STYLE – GỌN NHẸ)
--==================================================
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "RedzLiteFinal"

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0,360,0,360)
main.Position = UDim2.new(0.5,-180,0.5,-180)
main.BackgroundColor3 = Color3.fromRGB(20,20,20)
Instance.new("UICorner", main).CornerRadius = UDim.new(0,14)

local toggle = Instance.new("TextButton", main)
toggle.Size = UDim2.new(0,200,0,40)
toggle.Position = UDim2.new(0.5,-100,0,15)
toggle.Text = "OFF"
toggle.TextColor3 = Color3.new(1,1,1)
toggle.BackgroundColor3 = Color3.fromRGB(120,0,0)
Instance.new("UICorner", toggle)

toggle.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggle.Text = enabled and "ON" or "OFF"
    toggle.BackgroundColor3 = enabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(120,0,0)
end)

-- Attack mode
local modes = {"Melee","Fruit","Sword","Gun"}
local modeIndex = 1
local modeBtn = Instance.new("TextButton", main)
modeBtn.Size = UDim2.new(0,300,0,35)
modeBtn.Position = UDim2.new(0.5,-150,0,70)
modeBtn.Text = "Mode: Melee"
modeBtn.TextColor3 = Color3.new(1,1,1)
modeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
Instance.new("UICorner", modeBtn)

modeBtn.MouseButton1Click:Connect(function()
    modeIndex = modeIndex % #modes + 1
    attackMode = modes[modeIndex]
    modeBtn.Text = "Mode: "..attackMode
end)

-- Slider đơn giản (nhẹ cho máy yếu)
local function slider(text,y,min,max,val,cb)
    local label = Instance.new("TextLabel", main)
    label.Size = UDim2.new(0,300,0,22)
    label.Position = UDim2.new(0.5,-150,0,y)
    label.Text = text..": "..val
    label.TextColor3 = Color3.new(1,1,1)
    label.BackgroundTransparency = 1

    local btn = Instance.new("TextButton", main)
    btn.Size = UDim2.new(0,300,0,18)
    btn.Position = UDim2.new(0.5,-150,0,y+22)
    btn.BackgroundColor3 = Color3.fromRGB(80,80,80)
    btn.Text = ""
    Instance.new("UICorner", btn)

    btn.MouseButton1Click:Connect(function()
        val = math.clamp(val+1,min,max)
        label.Text = text..": "..val
        cb(val)
    end)
end

slider("Range",120,6,25,attackRange,function(v) attackRange=v end)
slider("Height",165,1,6,attackHeight,function(v) attackHeight=v end)
slider("Speed",210,1,5,1,function(v) attackSpeed=0.35-(v*0.03) end)
slider("Z HP %",255,30,80,60,function(v) lifeStealHP=v/100 end)

--==================================================
-- SAFETY CHECK (TỰ PAUSE KHI KHÔNG AN TOÀN)
--==================================================
local fps,lastFrame = 60,tick()
RunService.RenderStepped:Connect(function()
    local now = tick()
    fps = 1/math.max(now-lastFrame,0.001)
    lastFrame = now
end)

local function getPing()
    local net = Stats:FindFirstChild("Network")
    if not net then return 0 end
    local p = net:FindFirstChild("ServerStatsItem")
    if p and p:FindFirstChild("Data Ping") then
        return p["Data Ping"]:GetValue()
    end
    return 0
end

task.spawn(function()
    while task.wait(0.5) do
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        local unsafe =
            fps < 20 or
            getPing() > 350 or
            not hum or
            hum.Health <= 0
        safePaused = unsafe
    end
end)

--==================================================
-- AUTO Z – SANGUINE ART (CHỈ Z)
--==================================================
local function usingSanguine()
    local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
    return tool and tool.Name:lower():find("sanguine")
end

task.spawn(function()
    while task.wait(0.2) do
        if not enabled or safePaused then continue end
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        if hum and usingSanguine() and hum.Health/hum.MaxHealth <= lifeStealHP then
            if tick()-lastZ >= lifeStealCooldown then
                VIM:SendKeyEvent(true,Enum.KeyCode.Z,false,game)
                task.wait(0.1)
                VIM:SendKeyEvent(false,Enum.KeyCode.Z,false,game)
                lastZ = tick()
            end
        end
    end
end)
