-- =================================================
-- REDZ HUB STYLE - MOBILE / LOW FPS / DELTA
-- =================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local Stats = game:GetService("Stats")
local player = Players.LocalPlayer

-- ================= VARIABLES ====================
local enabled = false
local safePaused = false
local attackRange = 12
local attackHeight = 3
local attackSpeed = 0.25
local lifeStealHP = 0.6
local lifeStealCooldown = 3
local lastZ = 0
local lagEnabled = false

-- ================= UI ==========================
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "RedzLiteFinal"

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0,360,0,360)
main.Position = UDim2.new(0.5,-180,0.5,-180)
main.BackgroundColor3 = Color3.fromRGB(20,20,20)
Instance.new("UICorner", main).CornerRadius = UDim.new(0,14)

-- Top bar
local top = Instance.new("Frame", main)
top.Size = UDim2.new(1,0,0,40)
top.BackgroundColor3 = Color3.fromRGB(150,0,0)
Instance.new("UICorner", top).CornerRadius = UDim.new(0,14)

local title = Instance.new("TextLabel", top)
title.Size = UDim2.new(1,0,1,0)
title.Text = "REDZ HUB"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.TextScaled = true
title.Font = Enum.Font.GothamBold

-- ================= TOGGLE AUTO FARM ==================
local toggle = Instance.new("TextButton", main)
toggle.Size = UDim2.new(0,200,0,40)
toggle.Position = UDim2.new(0.5,-100,0,60)
toggle.Text = "OFF"
toggle.TextColor3 = Color3.new(1,1,1)
toggle.BackgroundColor3 = Color3.fromRGB(120,0,0)
Instance.new("UICorner", toggle)

toggle.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggle.Text = enabled and "ON" or "OFF"
    toggle.BackgroundColor3 = enabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(120,0,0)
end)

-- ================= SLIDERS ======================
local function createSlider(text,pos,min,max,value,callback)
    local label = Instance.new("TextLabel", main)
    label.Size = UDim2.new(0,300,0,22)
    label.Position = UDim2.new(0.5,-150,0,pos)
    label.Text = text..": "..value
    label.TextColor3 = Color3.new(1,1,1)
    label.BackgroundTransparency = 1

    local slider = Instance.new("TextButton", main)
    slider.Size = UDim2.new(0,300,0,18)
    slider.Position = UDim2.new(0.5,-150,0,pos+22)
    slider.BackgroundColor3 = Color3.fromRGB(80,80,80)
    slider.Text = ""
    Instance.new("UICorner", slider)

    slider.MouseButton1Click:Connect(function()
        value = math.clamp(value+1,min,max)
        label.Text = text..": "..value
        callback(value)
    end)
    return label, slider
end

createSlider("Range",120,6,25,attackRange,function(v) attackRange=v end)
createSlider("Height",165,1,6,attackHeight,function(v) attackHeight=v end)
createSlider("Speed",210,1,5,1,function(v) attackSpeed=0.35-(v*0.03) end)

-- ================= SLIDER Z HP% (chỉ khi Sucane Art) ==================
local zLabel, zSlider = createSlider("Z HP %",255,30,80,lifeStealHP*100,function(v) lifeStealHP=v/100 end)
zLabel.Visible = false
zSlider.Visible = false

-- ================= UI SIZE BUTTON =================
local sizeBtn = Instance.new("TextButton", main)
sizeBtn.Size = UDim2.new(0,140,0,30)
sizeBtn.Position = UDim2.new(0,10,0,10)
sizeBtn.Text = "Size: Medium"
sizeBtn.TextColor3 = Color3.new(1,1,1)
sizeBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
Instance.new("UICorner", sizeBtn)

local sizes = {Small=UDim2.new(0,250,0,250), Medium=UDim2.new(0,360,0,360), Large=UDim2.new(0,480,0,480)}
local currentSize = "Medium"

sizeBtn.MouseButton1Click:Connect(function()
    if currentSize=="Small" then currentSize="Medium"
    elseif currentSize=="Medium" then currentSize="Large"
    else currentSize="Small" end
    main.Size = sizes[currentSize]
    sizeBtn.Text = "Size: "..currentSize
end)

-- ================= MINI BUTTON ==================
local miniBtn = Instance.new("TextButton", player.PlayerGui)
miniBtn.Size = UDim2.new(0,40,0,40)
miniBtn.Position = UDim2.new(0,10,0,100)
miniBtn.Text = "UI"
miniBtn.TextColor3 = Color3.new(1,1,1)
miniBtn.BackgroundColor3 = Color3.fromRGB(150,0,0)
Instance.new("UICorner", miniBtn)

local uiVisible = true
miniBtn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    main.Visible = uiVisible
end)

-- Kéo miniBtn
local draggingMini, dragStartMini, startPosMini
miniBtn.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        draggingMini=true
        dragStartMini=input.Position
        startPosMini=miniBtn.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if draggingMini and input.UserInputType==Enum.UserInputType.MouseMovement then
        local delta=input.Position - dragStartMini
        miniBtn.Position=UDim2.new(startPosMini.X.Scale,startPosMini.X.Offset+delta.X,startPosMini.Y.Scale,startPosMini.Y.Offset+delta.Y)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then draggingMini=false end
end)

-- ================= LAG BUTTON ==================
local lagBtn = Instance.new("TextButton", main)
lagBtn.Size = UDim2.new(0,140,0,30)
lagBtn.Position = UDim2.new(0,10,0,50)
lagBtn.Text = "Lag: OFF"
lagBtn.TextColor3 = Color3.new(1,1,1)
lagBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
Instance.new("UICorner", lagBtn)

lagBtn.MouseButton1Click:Connect(function()
    lagEnabled = not lagEnabled
    lagBtn.Text = "Lag: "..(lagEnabled and "ON" or "OFF")
    lagBtn.BackgroundColor3 = lagEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(80,80,80)

    if lagEnabled then
        local Lighting=game:GetService("Lighting")
        Lighting.GlobalShadows=false
        Lighting.FogEnd=9e9
        for _,v in pairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") then v:Destroy() end
        end
        for _,v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material=Enum.Material.Plastic
                v.CastShadow=false
                v.Reflectance=0
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled=false
            elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1 end
        end
    end
end)

-- ================= UI KÉO ==================
local dragging, dragStart, startPos
top.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true
        dragStart=input.Position
        startPos=main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
        local delta=input.Position - dragStart
        main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)

-- ================= AUTO Z Sucane Art ==================
local function usingSucane()
    local tool=player.Character and player.Character:FindFirstChildOfClass("Tool")
    return tool and tool.Name:lower():find("sucane")
end

task.spawn(function()
    while task.wait(0.2) do
        local using=usingSucane()
        zLabel.Visible = using
        zSlider.Visible = using
        if not enabled or safePaused or not using then continue end
        local hum=player.Character and player.Character:FindFirstChild("Humanoid")
        if hum and hum.Health/hum.MaxHealth <= lifeStealHP then
            if tick()-lastZ>=lifeStealCooldown then
                VIM:SendKeyEvent(true,Enum.KeyCode.Z,false,game)
                task.wait(0.1)
                VIM:SendKeyEvent(false,Enum.KeyCode.Z,false,game)
                lastZ=tick()
            end
        end
    end
end)

-- ================= SAFETY CHECK ==================
local fps,lastFrame=60,tick()
RunService.RenderStepped:Connect(function()
    local now=tick()
    fps=1/math.max(now-lastFrame,0.001)
    lastFrame=now
end)

task.spawn(function()
    while task.wait(0.5) do
        local hum=player.Character and player.Character:FindFirstChild("Humanoid")
        local unsafe = fps<20 or (Stats:FindFirstChild("Network") and Stats.Network:FindFirstChild("ServerStatsItem") and Stats.Network.ServerStatsItem:FindFirstChild("Data Ping") and Stats.Network.ServerStatsItem["Data Ping"]:GetValue()>350) or not hum or (hum and hum.Health<=0)
        safePaused=unsafe
    end
end)
