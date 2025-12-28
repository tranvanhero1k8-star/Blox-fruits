--[[
🔹 Redz Hub Complete Script (Delta / Android)
🔹 Tính năng:
1. UI chính Redz style kéo được, co giãn
2. Mini UI toggle UI chính
3. Nút Size / Lag toggle trong UI chính
4. Slider Range / Fly Height / Fly Speed / Auto Z HP%
5. Auto Farm Nearest NPC + Auto Skill
6. Auto Skill: Sucane Z / Haki Ken V3-V4 / Gun / Devil Fruit
7. Bay mượt tới NPC / cửa dungeon, tốc độ tùy chỉnh
8. Dungeon logic + respawn kiểm tra phòng
9. Safety guard + Lag toggle
--]]

local player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local VirtualInput = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local safePaused = false

-- ================= UI =================
-- Main ScreenGui
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "RedzHub"

-- Main frame
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 320, 0, 380)
main.Position = UDim2.new(0.5, -160, 0.5, -190)
main.BackgroundColor3 = Color3.fromRGB(20,20,20)
main.BorderSizePixel = 0
main.Parent = gui
main.Visible = true

-- UICorner
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

-- UIListLayout + padding cho main
local layout = Instance.new("UIListLayout", main)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0,8)
local padding = Instance.new("UIPadding", main)
padding.PaddingTop = UDim.new(0,50)
padding.PaddingLeft = UDim.new(0,10)
padding.PaddingRight = UDim.new(0,10)

-- ================= Mini UI =================
local miniBtn = Instance.new("TextButton", gui)
miniBtn.Size = UDim2.new(0,50,0,50)
miniBtn.Position = UDim2.new(0,10,0,100)
miniBtn.Text = "R"
miniBtn.BackgroundColor3 = Color3.fromRGB(150,0,0)
Instance.new("UICorner", miniBtn)

local uiVisible = true
miniBtn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    main.Visible = uiVisible
end)

-- ================= Nút Size + Lag =================
local sizeBtn = Instance.new("TextButton", main)
sizeBtn.LayoutOrder = 1
sizeBtn.Size = UDim2.new(1,0,0,30)
sizeBtn.Text = "Size: Medium"
sizeBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
Instance.new("UICorner", sizeBtn)

local sizes = {Small=UDim2.new(0,220,0,280), Medium=UDim2.new(0,320,0,380), Large=UDim2.new(0,400,0,480)}
local currentSize = "Medium"
sizeBtn.MouseButton1Click:Connect(function()
    local nextSize
    if currentSize == "Small" then nextSize = "Medium"
    elseif currentSize == "Medium" then nextSize = "Large"
    else nextSize = "Small" end
    currentSize = nextSize
    sizeBtn.Text = "Size: "..currentSize
    main.Size = sizes[currentSize]
end)

local lagBtn = Instance.new("TextButton", main)
lagBtn.LayoutOrder = 2
lagBtn.Size = UDim2.new(1,0,0,30)
lagBtn.Text = "Lag: OFF"
lagBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
Instance.new("UICorner", lagBtn)

local lagMode = false
lagBtn.MouseButton1Click:Connect(function()
    lagMode = not lagMode
    if lagMode then lagBtn.Text = "Lag: ON" else lagBtn.Text = "Lag: OFF" end
end)

-- ================= Sliders =================
-- Helper function tạo slider
local function createSlider(name, default, min, max)
    local frame = Instance.new("Frame", main)
    frame.LayoutOrder = #main:GetChildren()+1
    frame.Size = UDim2.new(1,0,0,30)
    frame.BackgroundTransparency = 1
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1,0,0.5,0)
    label.Text = name..": "..default
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.TextScaled = true
    local value = default
    local slider = Instance.new("TextButton", frame)
    slider.Size = UDim2.new(1,0,0.5,0)
    slider.Position = UDim2.new(0,0,0.5,0)
    slider.Text = ""
    slider.BackgroundColor3 = Color3.fromRGB(120,0,0)
    Instance.new("UICorner", slider)
    slider.MouseButton1Down:Connect(function(input)
        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                conn:Disconnect()
            end
        end)
    end)
    return function() return value end, label
end

local getRange, rangeLabel = createSlider("Attack Range", 15, 5, 30)
local getHeight, heightLabel = createSlider("Fly Height", 5,1,15)
local getSpeed, speedLabel = createSlider("Fly Speed", 3,1,6)
local getZHP, zLabel = createSlider("Auto Z HP%", 50,1,100)

-- ================= Chọn kiểu tấn công =================
local attackMode = "Melee"
local attackDropdown = Instance.new("TextButton", main)
attackDropdown.LayoutOrder = #main:GetChildren()+1
attackDropdown.Size = UDim2.new(1,0,0,30)
attackDropdown.Text = "Attack: Melee"
Instance.new("UICorner", attackDropdown)
local modes = {"Melee","Sucane","HakiKen","Gun","Fruit"}
attackDropdown.MouseButton1Click:Connect(function()
    local idx = table.find(modes, attackMode)
    idx = (idx % #modes)+1
    attackMode = modes[idx]
    attackDropdown.Text = "Attack: "..attackMode
end)

-- ================= Toggle Auto Farm =================
local toggle = Instance.new("TextButton", main)
toggle.LayoutOrder = #main:GetChildren()+1
toggle.Size = UDim2.new(1,0,0,45)
toggle.Text = "OFF"
toggle.BackgroundColor3 = Color3.fromRGB(120,0,0)
Instance.new("UICorner", toggle)

local enabled = false
toggle.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then toggle.Text="ON"; toggle.BackgroundColor3=Color3.fromRGB(0,170,0)
    else toggle.Text="OFF"; toggle.BackgroundColor3=Color3.fromRGB(120,0,0) end
end)

-- ================= Drag UI =================
local drag, startPos, dragStart
top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        drag = true
        dragStart = input.Position
        startPos = main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if drag and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
end)

-- ================= Auto Farm Logic =================
local dungeonDoorPos = nil
local currentRoom = nil
local flySpeeds = {[1]=0.05,[2]=0.08,[3]=0.12,[4]=0.16,[5]=0.22,[6]=0.3}
local lastZ = 0
local lifeStealCooldown = 3
local lifeStealHP = 0.5

-- Helpers
local function usingSucane()
    local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
    return tool and tool.Name:lower():find("sucane")
end
local function usingHakiKen()
    local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local n = tool.Name:lower()
    return n:find("ken v3") or n:find("ken v4")
end
local function usingFruit()
    local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local n = tool.Name:lower()
    return n:find("bomb") or n:find("quake") or n:find("flame")
end

-- Dungeon door tracking
workspace.DescendantAdded:Connect(function(obj)
    if obj.Name=="DungeonDoor" and obj:IsA("Part") then
        dungeonDoorPos = obj.Position+Vector3.new(0,3,0)
        currentRoom = obj.Parent
    end
end)

-- Respawn logic
player.CharacterAdded:Connect(function(char)
    task.wait(1)
    local humRoot = char:WaitForChild("HumanoidRootPart")
    if currentRoom then
        if (humRoot.Position-currentRoom.Position).Magnitude>15 then
            if dungeonDoorPos then
                while (humRoot.Position-dungeonDoorPos).Magnitude>3 do
                    humRoot.CFrame = humRoot.CFrame:Lerp(CFrame.new(dungeonDoorPos),0.1*flySpeeds[getSpeed()])
                    task.wait(0.05)
                end
            end
        end
    end
end)

-- Auto farm loop
task.spawn(function()
    while task.wait(0.2) do
        if not enabled or safePaused then continue end
        local char = player.Character
        if not char then continue end
        local humRoot = char:FindFirstChild("HumanoidRootPart")
        if not humRoot then continue end

        -- Nếu có dungeon door thì đi tới trước
        if dungeonDoorPos and (humRoot.Position-dungeonDoorPos).Magnitude>3 then
            humRoot.CFrame = humRoot.CFrame:Lerp(CFrame.new(dungeonDoorPos),0.1*flySpeeds[getSpeed()])
            continue
        else
            dungeonDoorPos=nil
        end

        -- Tìm NPC gần nhất
        local target
        local closestDist = math.huge
        for _, npc in pairs(workspace:GetDescendants()) do
            if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
                local dist=(npc.HumanoidRootPart.Position-humRoot.Position).Magnitude
                if dist<closestDist and dist<=getRange() then
                    closestDist=dist
                    target=npc
                end
            end
        end

        if target then
            local targetPos=target.HumanoidRootPart.Position+Vector3.new(0,getHeight(),0)
            humRoot.CFrame=humRoot.CFrame:Lerp(CFrame.new(targetPos),0.1*flySpeeds[getSpeed()])

            local tool=char:FindFirstChildOfClass("Tool")

            if attackMode=="Melee" then
                if tool then
                    VirtualInput:SendKeyEvent(true,Enum.KeyCode.X,false,game)
                    task.wait(0.1)
                    VirtualInput:SendKeyEvent(false,Enum.KeyCode.X,false,game)
                end
            elseif attackMode=="Sucane" and usingSucane() then
                if (tick()-lastZ)>=lifeStealCooldown then
                    VirtualInput:SendKeyEvent(true,Enum.KeyCode.Z,false,game)
                    task.wait(0.1)
                    VirtualInput:SendKeyEvent(false,Enum.KeyCode.Z,false,game)
                    lastZ=tick()
                end
            elseif attackMode=="HakiKen" and usingHakiKen() then
                if tool and tool:FindFirstChild("Remote") then
                    tool.Remote:FireServer()
                end
            elseif attackMode=="Gun" then
                if tool and tool:FindFirstChild("Remote") then
                    tool.Remote:FireServer()
                end
            elseif attackMode=="Fruit" and usingFruit() then
                -- Auto skill
                if (tick()-lastZ)>=lifeStealCooldown then
                    VirtualInput:SendKeyEvent(true,Enum.KeyCode.Q,false,game)
                    task.wait(0.1)
                    VirtualInput:SendKeyEvent(false,Enum.KeyCode.Q,false,game)
                    lastZ=tick()
                end
                -- Auto melee
                if tool then
                    VirtualInput:SendKeyEvent(true,Enum.KeyCode.X,false,game)
                    task.wait(0.1)
                    VirtualInput:SendKeyEvent(false,Enum.KeyCode.X,false,game)
                end
            end
        end
    end
end)
