-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-- Constants
local NOTIFICATION_COOLDOWN = 1.5 -- Minimum time between notifications (in seconds)
local TARGET_CHECK_INTERVAL = 0.1 -- Target check interval (in seconds)
local DEFAULT_CONFIG = {
    Active = false, -- do not change this
    Prediction = 0.145, -- Target movement prediction value (higher = more anticipation)
    TargetPart = "Head", -- Body part that aimlock will target. Can also be "Head", "UpperTorso", "LowerTorso", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot", "Neck", "LeftShoulder", "RightShoulder", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand"
    Smoothness = 0.5, -- Camera movement smoothness (0 = instant, 1 = very smooth)
    MaxRadius = 300, -- Maximum distance to find targets
    MinimumDistance = 10, -- Minimum distance to activate aimlock, recommended to keep at 10
    DeactivationSensitivity = 0.5 -- Sensitivity to deactivate aimlock, recommended to keep at 0.5
}

-- State
local State = {
    LastNotification = 0,
    LastTargetCheck = 0,
    LockedTarget = nil,
    ControlPressed = false,
    LastMousePosition = Vector2.new(0, 0)
}

-- Cache
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- Utility Functions
local function SendNotification(active)
    local currentTime = tick()
    if currentTime - State.LastNotification >= NOTIFICATION_COOLDOWN then
        StarterGui:SetCore("SendNotification", {
            Title = "Autoaimlock - Moonlight EXC",
            Text = active and "Activated" or "Deactivated",
            Duration = 1
        })
        State.LastNotification = currentTime
    end
end

local function IsTargetValid(player)
    if not player or not player.Character then return false end
    
    local character = player.Character
    local humanoid = character:FindFirstChild("Humanoid")
    local targetPart = character:FindFirstChild(DEFAULT_CONFIG.TargetPart)
    
    return targetPart 
        and humanoid 
        and humanoid.Health > 0
end

local function CalculateDistance(position)
    local viewportPosition = Camera:WorldToViewportPoint(position)
    return (Vector2.new(viewportPosition.X, viewportPosition.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
end

local function FindNearestPlayer()
    if State.LockedTarget and IsTargetValid(State.LockedTarget) then
        return State.LockedTarget
    end
    
    local shortestDistance = DEFAULT_CONFIG.MaxRadius
    local target = nil
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsTargetValid(player) then
            local targetPart = player.Character[DEFAULT_CONFIG.TargetPart]
            local distance = CalculateDistance(targetPart.Position)
            
            if distance >= DEFAULT_CONFIG.MinimumDistance and distance < shortestDistance then
                shortestDistance = distance
                target = player
            end
        end
    end
    
    return target
end

local function UpdateAimLock()
    if not DEFAULT_CONFIG.Active or not State.LockedTarget then return end
    
    if not IsTargetValid(State.LockedTarget) then
        DEFAULT_CONFIG.Active = false
        State.LockedTarget = nil
        return
    end
    
    local targetPart = State.LockedTarget.Character[DEFAULT_CONFIG.TargetPart]
    local prediction = targetPart.Velocity * DEFAULT_CONFIG.Prediction
    local targetPosition = targetPart.Position + prediction
    local newCFrame = CFrame.lookAt(Camera.CFrame.Position, targetPosition)
    
    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, DEFAULT_CONFIG.Smoothness)
end

-- Input Handling
-- To change the aimlock key, change "Enum.KeyCode.LeftControl" to the desired key
-- Example: Enum.KeyCode.E to use the E key
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.E then
        State.ControlPressed = true
        DEFAULT_CONFIG.Active = not DEFAULT_CONFIG.Active
        
        if DEFAULT_CONFIG.Active then
            State.LockedTarget = FindNearestPlayer()
        else
            State.LockedTarget = nil
        end
        
        SendNotification(DEFAULT_CONFIG.Active)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftControl then 
        State.ControlPressed = false
    end
end)

-- Main Loop
RunService.RenderStepped:Connect(function()
    State.LastMousePosition = Vector2.new(Mouse.X, Mouse.Y)
    UpdateAimLock()
end)
