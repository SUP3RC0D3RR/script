local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- GUI Setup
local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
screenGui.Name = "TeleportGui"
screenGui.ResetOnSpawn = false

-- Main Frame Outline (gradient)
local outlineParent = Instance.new("Folder", screenGui)
outlineParent.Name = "OutlineParent"

local mainOutline = Instance.new("Frame")
mainOutline.Size = UDim2.new(0, 312, 0, 362) -- 6px bigger than frame
mainOutline.Position = UDim2.new(0.5, -156, 0.5, -181)
mainOutline.AnchorPoint = Vector2.new(0,0)
mainOutline.BackgroundTransparency = 0
mainOutline.Parent = outlineParent
local outlineCorner = Instance.new("UICorner", mainOutline)
outlineCorner.CornerRadius = UDim.new(0, 18)

local mainGradient = Instance.new("UIGradient")
mainGradient.Rotation = 45
mainGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
}
mainGradient.Parent = mainOutline

-- Animate main outline gradient
coroutine.wrap(function()
    while mainOutline.Parent do
        for angle = 45, 405, 2 do
            mainGradient.Rotation = angle
            wait(0.02)
        end
    end
end)()

-- Main Frame (black background, rounded)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 350)
frame.Position = UDim2.new(0.5, -150, 0.5, -175)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Parent = screenGui
local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 12)

-- Top bar (draggable area)
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.BackgroundTransparency = 1
topBar.Parent = frame

-- Title Label
local titleBar = Instance.new("TextLabel")
titleBar.Size = UDim2.new(1, -40, 0, 30)
titleBar.Position = UDim2.new(0, 10, 0, 7)
titleBar.BackgroundTransparency = 1
titleBar.Text = "Teleport GUI V2"
titleBar.Font = Enum.Font.SourceSansBold
titleBar.TextSize = 20
titleBar.TextColor3 = Color3.fromRGB(255, 100, 100)
titleBar.TextXAlignment = Enum.TextXAlignment.Left
titleBar.Parent = topBar

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 24, 0, 24)
closeButton.Position = UDim2.new(1, -30, 0, 7)
closeButton.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 16
closeButton.Parent = topBar
closeButton.Active = false
local closeCorner = Instance.new("UICorner", closeButton)
closeCorner.CornerRadius = UDim.new(0, 6)

-- Dragging logic with block on close
local dragging, dragStart, startPos
local blockDragging = false

topBar.InputBegan:Connect(function(input)
    if blockDragging then return end -- don't start dragging if blocked
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        mainOutline.Position = frame.Position - UDim2.new(0, 6, 0, 6)
    end
end)

-- Search Bar
local searchBar = Instance.new("TextBox")
searchBar.Size = UDim2.new(1, -20, 0, 30)
searchBar.Position = UDim2.new(0, 10, 0, 45)
searchBar.PlaceholderText = "Search players..."
searchBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
searchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBar.Font = Enum.Font.SourceSans
searchBar.TextSize = 16
searchBar.ClearTextOnFocus = false
searchBar.Parent = frame
local searchCorner = Instance.new("UICorner", searchBar)
searchCorner.CornerRadius = UDim.new(0, 6)

-- Scrollable player list container
local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -20, 1, -100)
content.Position = UDim2.new(0, 10, 0, 80)
content.BackgroundTransparency = 1
content.ScrollBarThickness = 6
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = content

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
end)

-- Player buttons storage
local playerButtons = {}

-- Tweened teleport function (super fast)
local function teleportTo(player)
    local char = LocalPlayer.Character
    local target = player.Character
    if char and target and target:FindFirstChild("HumanoidRootPart") then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local targetCFrame = target.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
            tween:Play()
        end
    end
end

-- Create a teleport button for each player (DisplayName and username)
local function createTeleportButton(player)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 30)
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    button.Text = player.DisplayName .. " (" .. player.Name .. ")"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSans
    button.TextSize = 16
    button.Parent = content
    local btnCorner = Instance.new("UICorner", button)
    btnCorner.CornerRadius = UDim.new(0, 6)

    playerButtons[player.Name:lower()] = button

    -- Button animation on hover & click
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1, 10, 0, 35)}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 30)}):Play()
    end)
    button.MouseButton1Click:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 5, 0, 32)}):Play()
        wait(0.1)
        TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 30)}):Play()
        teleportTo(player)
    end)
end

-- Fill initial buttons (except local player)
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createTeleportButton(player)
    end
end

-- Update buttons when player joins or leaves
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        createTeleportButton(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    local btn = playerButtons[player.Name:lower()]
    if btn then
        btn:Destroy()
        playerButtons[player.Name:lower()] = nil
    end
end)

-- Filter player buttons on search
searchBar:GetPropertyChangedSignal("Text"):Connect(function()
    local searchText = searchBar.Text:lower()
    for name, button in pairs(playerButtons) do
        if name:find(searchText) then
            button.Visible = true
        else
            button.Visible = false
        end
    end
end)

-- Reopen GUI container and button (hidden initially)
local reopenContainer = Instance.new("Frame")
reopenContainer.Size = UDim2.new(0, 112, 0, 42)
reopenContainer.Position = UDim2.new(0, 10, 1, -40)
reopenContainer.BackgroundTransparency = 1
reopenContainer.Parent = screenGui
reopenContainer.Visible = false -- hide by default

-- Gradient outline for reopen button (inside container)
local reopenButtonOutline = Instance.new("Frame")
reopenButtonOutline.Size = UDim2.new(1, 0, 1, 0) -- fill container
reopenButtonOutline.Position = UDim2.new(0, 0, 0, 0)
reopenButtonOutline.BackgroundTransparency = 0
reopenButtonOutline.Parent = reopenContainer
local reopenOutlineCorner = Instance.new("UICorner", reopenButtonOutline)
reopenOutlineCorner.CornerRadius = UDim.new(0, 10)

local reopenGradient = Instance.new("UIGradient")
reopenGradient.Rotation = 45
reopenGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
}
reopenGradient.Parent = reopenButtonOutline

-- Animate reopen outline gradient
coroutine.wrap(function()
    while reopenButtonOutline.Parent do
        for angle = 45, 405, 2 do
            reopenGradient.Rotation = angle
            wait(0.02)
        end
    end
end)()

-- Reopen Button (inside container)
local reopenButton = Instance.new("TextButton")
reopenButton.Size = UDim2.new(1, -12, 1, -12) -- smaller to show outline border
reopenButton.Position = UDim2.new(0, 6, 0, 6)
reopenButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
reopenButton.Text = "Open GUI"
reopenButton.TextColor3 = Color3.fromRGB(255, 100, 100)
reopenButton.Font = Enum.Font.SourceSansBold
reopenButton.TextSize = 16
reopenButton.Parent = reopenContainer
local reopenCorner = Instance.new("UICorner", reopenButton)
reopenCorner.CornerRadius = UDim.new(0, 8)

-- Close and reopen button logic with drag block fix
closeButton.MouseButton1Click:Connect(function()
    blockDragging = true
    dragging = false
    frame.Visible = false
    mainOutline.Visible = false
    reopenContainer.Visible = true
    wait(0.2)
    blockDragging = false
end)

reopenButton.MouseButton1Click:Connect(function()
    frame.Visible = true
    mainOutline.Visible = true
    reopenContainer.Visible = false
end)
