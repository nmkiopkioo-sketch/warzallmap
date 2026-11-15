-- [PROSCRIPT HUB - UNIVERSAL ALL-MAP EDITION (PC & MOBILE)]
-- 1. Universal Map Compatibility: Supports all Roblox maps automatically (including custom character rigs, survival maps, and standard games).
-- 2. Font & Glyph Fix: Removed unsupported Unicode/Emoji symbols that render as "[ ]" (tofu boxes) in certain maps and mobile devices.
-- 3. Guaranteed Cross-Map WalkSpeed & HighJump: Uses RenderPriority.Character+5 override, CFrame delta translation, and multi-frame vertical jump lift.
-- 4. Universal 2D ESP & 31-Highlight-Safe Chams Pool: Tracks Players, NPCs/Zombies, Dropped Items, Vehicles, and Map Objects with zero FPS lag.

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

-- Resolve External/Topmost GUI Container (gethui -> CoreGui -> PlayerGui)
local function GetExternalGuiParent()
    local successHui, hui = pcall(function()
        if gethui then return gethui() end
        return nil
    end)
    if successHui and hui then return hui end

    local successCore, coreRef = pcall(function()
        local test = Instance.new("Folder")
        test.Parent = CoreGui
        test:Destroy()
        return CoreGui
    end)
    if successCore and coreRef then return coreRef end

    return PlayerGui
end

-- Cleanup previous UI instances, RenderStep bindings, and connections
local function CleanupExistingUI()
    pcall(function()
        RunService:UnbindFromRenderStep("ProScriptMovementOverride")
    end)
    if _G.ProScriptConnections then
        for _, conn in ipairs(_G.ProScriptConnections) do
            pcall(function() conn:Disconnect() end)
        end
    end
    _G.ProScriptConnections = {}

    local containers = {PlayerGui}
    pcall(function() if gethui then table.insert(containers, gethui()) end end)
    pcall(function() table.insert(containers, CoreGui) end)

    for _, parentObj in ipairs(containers) do
        pcall(function()
            if parentObj and parentObj:FindFirstChild("ProScriptHub") then
                parentObj.ProScriptHub:Destroy()
            end
        end)
    end

    if Lighting:FindFirstChild("ProScriptBlur") then
        Lighting.ProScriptBlur:Destroy()
    end
end

CleanupExistingUI()

local Connections = _G.ProScriptConnections
local function TrackConnection(conn)
    table.insert(Connections, conn)
    return conn
end

local TargetGuiParent = GetExternalGuiParent()

-- Runtime Configuration State
local Config = {
    -- Universal ESP & Customization
    ESPMaster = false,
    ESPTeamCheck = false,
    ESPUseTeamColor = false,
    ESPRainbow = false,
    ESPColor = Color3.fromRGB(62, 235, 130),
    ESPBox = true,
    ESPBoxStyle = "กรอบเต็ม", -- "กรอบเต็ม" or "กรอบมุม"
    ESPBoxFill = false,
    ESPThickness = 2,
    ESPTracer = false,
    ESPTracerOrigin = "ล่างจอ", -- "ล่างจอ" or "กลางจอ"
    ESPNameDist = true,
    ESPWeapon = true,
    ESPHealth = true,
    ESPHeadDot = false,
    ESPChams = false,
    ESPItems = false,
    ESPZombies = false,
    ESPExtras = false,
    ESPMaxDist = 2000,

    -- Universal Movement
    SpeedBoost = false,
    WalkSpeed = 38,
    SpeedMethod = "ผสม (แนะนำ)", -- "ผสม (แนะนำ)" or "วาร์ปสเต็ป (ทะลุล็อค)"
    FastSlide = false,
    SlideSpeed = 68,
    FastCar = false,
    CarSpeed = 125,
    HighJump = false,
    JumpPower = 85,
    InfiniteJump = false,
    FlyMode = false,
    FlySpeed = 52,
    Noclip = false,

    -- Cosmetics & Performance
    FullBright = false,
    UnlockSkins = false,
    NeonWeapon = false,
    CharacterAura = false,
    ReduceEffects = false,
    LowGraphics = false,
    FPSBoost = false,

    -- Settings & UI
    AntiBan = true,
    AntiAFK = true,
    UIBlur = false,
    UITransparency = 0.04,
    LightSoftTheme = false,
    UIFontScale = 100
}

-- Eye-Friendly Modern Dark-Emerald Theme Palette
local Theme = {
    Background = Color3.fromRGB(13, 18, 15),
    Sidebar = Color3.fromRGB(17, 24, 20),
    ColumnBg = Color3.fromRGB(20, 29, 24),
    CardBg = Color3.fromRGB(26, 38, 31),
    CardHover = Color3.fromRGB(32, 47, 38),
    CardStroke = Color3.fromRGB(40, 64, 49),
    AccentLight = Color3.fromRGB(72, 232, 134),
    AccentDark = Color3.fromRGB(38, 194, 98),
    Stroke = Color3.fromRGB(48, 86, 62),
    TextPrimary = Color3.fromRGB(242, 252, 245),
    TextSecondary = Color3.fromRGB(168, 202, 178),
    DangerBg = Color3.fromRGB(64, 22, 28),
    DangerHover = Color3.fromRGB(220, 48, 60),
    DangerStroke = Color3.fromRGB(235, 75, 85),
    DangerIcon = Color3.fromRGB(255, 105, 115)
}

-- Preset Color Swatches for Universal ESP
local ESPColorPresets = {
    {Name = "เขียว", Color = Color3.fromRGB(62, 235, 130)},
    {Name = "เหลือง", Color = Color3.fromRGB(255, 215, 65)},
    {Name = "แดง", Color = Color3.fromRGB(255, 70, 80)},
    {Name = "ฟ้า", Color = Color3.fromRGB(55, 195, 255)},
    {Name = "ม่วง", Color = Color3.fromRGB(185, 105, 255)},
    {Name = "ชมพู", Color = Color3.fromRGB(255, 105, 195)},
    {Name = "ส้ม", Color = Color3.fromRGB(255, 145, 50)},
    {Name = "ขาว", Color = Color3.fromRGB(255, 255, 255)}
}

-- Typography Configuration
local Typography = {
    FontHeading = Enum.Font.GothamBlack,
    FontBold = Enum.Font.GothamBold,
    FontMedium = Enum.Font.GothamMedium,
    TitleSize = 17,
    SubTitleSize = 12,
    SectionHeader = 15,
    TabText = 14,
    ItemTitle = 14,
    ItemDesc = 12,
    ControlText = 12,
    ProfileTitle = 13,
    ProfileSub = 11
}

-- Tween Helpers
local SmoothInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local FastInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function Tween(instance, info, properties)
    local tween = TweenService:Create(instance, info, properties)
    tween:Play()
    return tween
end

-- Optional Background Blur Effect
local BlurEffect = Instance.new("BlurEffect")
BlurEffect.Name = "ProScriptBlur"
BlurEffect.Size = 12
BlurEffect.Enabled = Config.UIBlur
BlurEffect.Parent = Lighting

-- External Topmost ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ProScriptHub"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999999
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
    end
end)

ScreenGui.Parent = TargetGuiParent

-- Logo Configuration
local DefaultLogo = "rbxassetid://10723414902"
local LogoUrl = "https://i.postimg.cc/BQHJQMyH/loko-kemm-ng-P-re-xng-por-Hub-(1).png"

-- Zero-Latency Dragging Utility for PC and Mobile
local function MakeDraggable(handle, targetFrame, onTapCallback)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
    local movedDistance = 0

    TrackConnection(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position
            movedDistance = 0

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if dragging then
                        dragging = false
                        if onTapCallback and movedDistance < 10 then
                            onTapCallback()
                        end
                    end
                end
            end)
        end
    end))

    TrackConnection(handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            movedDistance = delta.Magnitude
            targetFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end))
end

-- Dynamic Transparency & Font Scaling Registries
local TransparentFrames = {
    Main = {},
    Sub = {},
    Cards = {}
}

local RegisteredTexts = {}
local function RegisterText(label, baseSize)
    label.TextSize = baseSize
    table.insert(RegisteredTexts, {Instance = label, BaseSize = baseSize})
end

local function ApplyFontScale(scalePercent)
    Config.UIFontScale = scalePercent
    local multiplier = scalePercent / 100
    for _, item in ipairs(RegisteredTexts) do
        if item.Instance and item.Instance.Parent then
            item.Instance.TextSize = math.clamp(math.floor(item.BaseSize * multiplier + 0.5), 10, 26)
        end
    end
end

local function ApplyTransparency(val)
    Config.UITransparency = val
    local subTrans = math.clamp(val * 0.85, 0, 0.88)
    local cardTrans = math.clamp(val * 0.65, 0, 0.82)
    for _, frame in ipairs(TransparentFrames.Main) do
        frame.BackgroundTransparency = val
    end
    for _, frame in ipairs(TransparentFrames.Sub) do
        frame.BackgroundTransparency = subTrans
    end
    for _, frame in ipairs(TransparentFrames.Cards) do
        frame.BackgroundTransparency = cardTrans
    end
end

-- Floating Toggle Button (Upper-Left-Center, Topmost ZIndex = 200)
local DefaultOpenBtnPos = UDim2.new(0.28, 0, 0.08, 0)

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Parent = ScreenGui
OpenButton.AnchorPoint = Vector2.new(0.5, 0.5)
OpenButton.BackgroundColor3 = Theme.Background
OpenButton.BackgroundTransparency = 0.04
OpenButton.Position = DefaultOpenBtnPos
OpenButton.Size = UDim2.new(0, 56, 0, 56)
OpenButton.AutoButtonColor = false
OpenButton.Text = ""
OpenButton.ZIndex = 200

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(1, 0)
OpenCorner.Parent = OpenButton

local OpenStroke = Instance.new("UIStroke")
OpenStroke.Color = Theme.AccentLight
OpenStroke.Thickness = 2.2
OpenStroke.Transparency = 0.08
OpenStroke.Parent = OpenButton

local OpenLogo = Instance.new("ImageLabel")
OpenLogo.Parent = OpenButton
OpenLogo.BackgroundTransparency = 1
OpenLogo.Position = UDim2.new(0, 3, 0, 3)
OpenLogo.Size = UDim2.new(1, -6, 1, -6)
OpenLogo.Image = DefaultLogo
OpenLogo.ScaleType = Enum.ScaleType.Fit
OpenLogo.ZIndex = 201

local OpenLogoCorner = Instance.new("UICorner")
OpenLogoCorner.CornerRadius = UDim.new(1, 0)
OpenLogoCorner.Parent = OpenLogo

local OpenStatusDot = Instance.new("Frame")
OpenStatusDot.Parent = OpenButton
OpenStatusDot.BackgroundColor3 = Theme.AccentLight
OpenStatusDot.Position = UDim2.new(1, -14, 1, -14)
OpenStatusDot.Size = UDim2.new(0, 12, 0, 12)
OpenStatusDot.ZIndex = 202

local OpenDotCorner = Instance.new("UICorner")
OpenDotCorner.CornerRadius = UDim.new(1, 0)
OpenDotCorner.Parent = OpenStatusDot

local OpenDotStroke = Instance.new("UIStroke")
OpenDotStroke.Color = Theme.Background
OpenDotStroke.Thickness = 2
OpenDotStroke.Parent = OpenStatusDot

-- Main Window Frame
local DefaultW, DefaultH = 740, 455
local MinW, MinH = 560, 340
local MaxW, MaxH = 960, 600

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BackgroundTransparency = Config.UITransparency
MainFrame.BorderSizePixel = 0
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, DefaultW, 0, DefaultH)
MainFrame.ClipsDescendants = true
MainFrame.Visible = true
MainFrame.Active = true
MainFrame.ZIndex = 100
table.insert(TransparentFrames.Main, MainFrame)

-- Responsive Cross-Platform UIScale
local MainScale = Instance.new("UIScale")
MainScale.Parent = MainFrame

local function GetResponsiveBaseScale()
    local vp = Camera and Camera.ViewportSize or Vector2.new(1280, 720)
    if vp.Y < 430 then
        return math.clamp(vp.Y / 490, 0.76, 1)
    elseif vp.Y < 540 then
        return math.clamp(vp.Y / 515, 0.85, 1)
    end
    return 1
end

local BaseScale = GetResponsiveBaseScale()
MainScale.Scale = BaseScale

TrackConnection(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    BaseScale = GetResponsiveBaseScale()
    if MainFrame.Visible then
        MainScale.Scale = BaseScale
    end
end))

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.Stroke
MainStroke.Thickness = 1.8
MainStroke.Transparency = 0.15
MainStroke.Parent = MainFrame

-- Window Visibility Controller
local isWindowOpen = true
local isMinimized = false

local function SetWindowVisible(state)
    isWindowOpen = state
    BaseScale = GetResponsiveBaseScale()
    if state then
        MainFrame.Visible = true
        MainScale.Scale = BaseScale * 0.92
        Tween(MainScale, SmoothInfo, {Scale = BaseScale})
        Tween(OpenButton, FastInfo, {Size = UDim2.new(0, 56, 0, 56)})
        Tween(OpenStatusDot, FastInfo, {BackgroundColor3 = Theme.AccentLight})
        if Config.UIBlur and not isMinimized then
            BlurEffect.Enabled = true
            Tween(BlurEffect, SmoothInfo, {Size = 12})
        end
    else
        Tween(MainScale, FastInfo, {Scale = BaseScale * 0.92})
        Tween(OpenButton, FastInfo, {Size = UDim2.new(0, 50, 0, 50)})
        Tween(OpenStatusDot, FastInfo, {BackgroundColor3 = Theme.DangerHover})
        if Config.UIBlur then
            Tween(BlurEffect, FastInfo, {Size = 0})
            task.delay(0.14, function()
                if not isWindowOpen then
                    BlurEffect.Enabled = false
                end
            end)
        end
        task.delay(0.13, function()
            if not isWindowOpen then
                MainFrame.Visible = false
            end
        end)
    end
end

MakeDraggable(OpenButton, OpenButton, function()
    SetWindowVisible(not isWindowOpen)
end)

-- Top Header Bar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Theme.Sidebar
TopBar.BackgroundTransparency = Config.UITransparency * 0.85
TopBar.BorderSizePixel = 0
TopBar.Size = UDim2.new(1, 0, 0, 56)
TopBar.Active = true
table.insert(TransparentFrames.Sub, TopBar)

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 14)
TopCorner.Parent = TopBar

local TopFix = Instance.new("Frame")
TopFix.Parent = TopBar
TopFix.BackgroundColor3 = Theme.Sidebar
TopFix.BackgroundTransparency = Config.UITransparency * 0.85
TopFix.BorderSizePixel = 0
TopFix.Position = UDim2.new(0, 0, 1, -14)
TopFix.Size = UDim2.new(1, 0, 0, 14)
table.insert(TransparentFrames.Sub, TopFix)

local TopDivider = Instance.new("Frame")
TopDivider.Parent = TopBar
TopDivider.BackgroundColor3 = Theme.Stroke
TopDivider.BackgroundTransparency = 0.55
TopDivider.BorderSizePixel = 0
TopDivider.Position = UDim2.new(0, 0, 1, -1)
TopDivider.Size = UDim2.new(1, 0, 0, 1)

MakeDraggable(TopBar, MainFrame)

-- Header Logo
local HeaderLogo = Instance.new("ImageLabel")
HeaderLogo.Parent = TopBar
HeaderLogo.BackgroundColor3 = Theme.CardBg
HeaderLogo.Position = UDim2.new(0, 14, 0.5, -19)
HeaderLogo.Size = UDim2.new(0, 38, 0, 38)
HeaderLogo.Image = DefaultLogo

local HeaderLogoCorner = Instance.new("UICorner")
HeaderLogoCorner.CornerRadius = UDim.new(1, 0)
HeaderLogoCorner.Parent = HeaderLogo

local HeaderLogoStroke = Instance.new("UIStroke")
HeaderLogoStroke.Color = Theme.AccentLight
HeaderLogoStroke.Thickness = 1.5
HeaderLogoStroke.Parent = HeaderLogo

-- Asynchronous Custom Logo Loader
task.spawn(function()
    pcall(function()
        local getAsset = getcustomasset or getsynasset
        if getAsset and writefile and isfile then
            local fileName = "ProScript_Logo_V3.png"
            if not isfile(fileName) then
                writefile(fileName, game:HttpGet(LogoUrl))
            end
            local customId = getAsset(fileName)
            if customId then
                OpenLogo.Image = customId
                HeaderLogo.Image = customId
            end
        end
    end)
end)

-- Header Title & Clickable Credit Subtitle (Clean Text Without Special Brackets)
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = TopBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 62, 0, 8)
TitleLabel.Size = UDim2.new(1, -165, 0, 22)
TitleLabel.Font = Typography.FontHeading
TitleLabel.Text = "เรื่องโปร Hub | ProScript"
TitleLabel.TextColor3 = Theme.TextPrimary
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
RegisterText(TitleLabel, Typography.TitleSize)

local CreditButton = Instance.new("TextButton")
CreditButton.Parent = TopBar
CreditButton.BackgroundTransparency = 1
CreditButton.Position = UDim2.new(0, 62, 0, 30)
CreditButton.Size = UDim2.new(1, -165, 0, 18)
CreditButton.Font = Typography.FontMedium
CreditButton.Text = "ช่องนี้เรื่องโปร | ดิสคอร์ด: https://discord.gg/gZpkSgmR8"
CreditButton.TextColor3 = Theme.AccentLight
CreditButton.TextXAlignment = Enum.TextXAlignment.Left
RegisterText(CreditButton, Typography.SubTitleSize)

CreditButton.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then
            setclipboard("https://discord.gg/gZpkSgmR8")
            CreditButton.Text = "คัดลอกลิงก์ดิสคอร์ดเรียบร้อยแล้ว!"
            task.wait(1.5)
            CreditButton.Text = "ช่องนี้เรื่องโปร | ดิสคอร์ด: https://discord.gg/gZpkSgmR8"
        end
    end)
end)

-- Vector Collapse/Minimize Tab Button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Parent = TopBar
MinimizeButton.BackgroundColor3 = Theme.CardBg
MinimizeButton.BackgroundTransparency = 0.1
MinimizeButton.Position = UDim2.new(1, -92, 0.5, -17)
MinimizeButton.Size = UDim2.new(0, 34, 0, 34)
MinimizeButton.AutoButtonColor = false
MinimizeButton.Text = ""

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 9)
MinCorner.Parent = MinimizeButton

local MinStroke = Instance.new("UIStroke")
MinStroke.Color = Theme.Stroke
MinStroke.Thickness = 1.2
MinStroke.Transparency = 0.25
MinStroke.Parent = MinimizeButton

local MinBarH = Instance.new("Frame")
MinBarH.Name = "MinBarH"
MinBarH.Parent = MinimizeButton
MinBarH.AnchorPoint = Vector2.new(0.5, 0.5)
MinBarH.BackgroundColor3 = Theme.TextPrimary
MinBarH.BorderSizePixel = 0
MinBarH.Position = UDim2.new(0.5, 0, 0.5, 0)
MinBarH.Size = UDim2.new(0, 14, 0, 2.5)

local MinBarHCorner = Instance.new("UICorner")
MinBarHCorner.CornerRadius = UDim.new(1, 0)
MinBarHCorner.Parent = MinBarH

local MinBarV = Instance.new("Frame")
MinBarV.Name = "MinBarV"
MinBarV.Parent = MinimizeButton
MinBarV.AnchorPoint = Vector2.new(0.5, 0.5)
MinBarV.BackgroundColor3 = Theme.TextPrimary
MinBarV.BorderSizePixel = 0
MinBarV.Position = UDim2.new(0.5, 0, 0.5, 0)
MinBarV.Size = UDim2.new(0, 2.5, 0, 0)
MinBarV.Visible = false

local MinBarVCorner = Instance.new("UICorner")
MinBarVCorner.CornerRadius = UDim.new(1, 0)
MinBarVCorner.Parent = MinBarV

MinimizeButton.MouseEnter:Connect(function()
    Tween(MinimizeButton, FastInfo, {BackgroundColor3 = Theme.AccentDark})
    Tween(MinBarH, FastInfo, {BackgroundColor3 = Theme.Background})
    Tween(MinBarV, FastInfo, {BackgroundColor3 = Theme.Background})
end)
MinimizeButton.MouseLeave:Connect(function()
    Tween(MinimizeButton, FastInfo, {BackgroundColor3 = Theme.CardBg})
    Tween(MinBarH, FastInfo, {BackgroundColor3 = Theme.TextPrimary})
    Tween(MinBarV, FastInfo, {BackgroundColor3 = Theme.TextPrimary})
end)

-- Vector Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = TopBar
CloseButton.BackgroundColor3 = Theme.DangerBg
CloseButton.BackgroundTransparency = 0.08
CloseButton.Position = UDim2.new(1, -48, 0.5, -17)
CloseButton.Size = UDim2.new(0, 34, 0, 34)
CloseButton.AutoButtonColor = false
CloseButton.Text = ""

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 9)
CloseCorner.Parent = CloseButton

local CloseStroke = Instance.new("UIStroke")
CloseStroke.Color = Theme.DangerStroke
CloseStroke.Thickness = 1.3
CloseStroke.Transparency = 0.15
CloseStroke.Parent = CloseButton

local XLine1 = Instance.new("Frame")
XLine1.Name = "XLine1"
XLine1.Parent = CloseButton
XLine1.AnchorPoint = Vector2.new(0.5, 0.5)
XLine1.BackgroundColor3 = Theme.DangerIcon
XLine1.BorderSizePixel = 0
XLine1.Position = UDim2.new(0.5, 0, 0.5, 0)
XLine1.Size = UDim2.new(0, 16, 0, 2.5)
XLine1.Rotation = 45

local XLine1Corner = Instance.new("UICorner")
XLine1Corner.CornerRadius = UDim.new(1, 0)
XLine1Corner.Parent = XLine1

local XLine2 = Instance.new("Frame")
XLine2.Name = "XLine2"
XLine2.Parent = CloseButton
XLine2.AnchorPoint = Vector2.new(0.5, 0.5)
XLine2.BackgroundColor3 = Theme.DangerIcon
XLine2.BorderSizePixel = 0
XLine2.Position = UDim2.new(0.5, 0, 0.5, 0)
XLine2.Size = UDim2.new(0, 16, 0, 2.5)
XLine2.Rotation = -45

local XLine2Corner = Instance.new("UICorner")
XLine2Corner.CornerRadius = UDim.new(1, 0)
XLine2Corner.Parent = XLine2

CloseButton.MouseEnter:Connect(function()
    Tween(CloseButton, FastInfo, {BackgroundColor3 = Theme.DangerHover})
    Tween(XLine1, FastInfo, {BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
    Tween(XLine2, FastInfo, {BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
end)
CloseButton.MouseLeave:Connect(function()
    Tween(CloseButton, FastInfo, {BackgroundColor3 = Theme.DangerBg})
    Tween(XLine1, FastInfo, {BackgroundColor3 = Theme.DangerIcon})
    Tween(XLine2, FastInfo, {BackgroundColor3 = Theme.DangerIcon})
end)

-- Body Container
local BodyFrame = Instance.new("Frame")
BodyFrame.Name = "BodyFrame"
BodyFrame.Parent = MainFrame
BodyFrame.BackgroundTransparency = 1
BodyFrame.Position = UDim2.new(0, 0, 0, 56)
BodyFrame.Size = UDim2.new(1, 0, 1, -56)

-- Bottom-Right Corner Vector Resize Handle
local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Name = "ResizeHandle"
ResizeHandle.Parent = MainFrame
ResizeHandle.BackgroundTransparency = 1
ResizeHandle.Position = UDim2.new(1, -24, 1, -24)
ResizeHandle.Size = UDim2.new(0, 24, 0, 24)
ResizeHandle.AutoButtonColor = false
ResizeHandle.Text = ""
ResizeHandle.ZIndex = 115

local ResizeGrip1 = Instance.new("Frame")
ResizeGrip1.Parent = ResizeHandle
ResizeGrip1.AnchorPoint = Vector2.new(0.5, 0.5)
ResizeGrip1.BackgroundColor3 = Theme.AccentLight
ResizeGrip1.BorderSizePixel = 0
ResizeGrip1.Position = UDim2.new(0.6, 0, 0.6, 0)
ResizeGrip1.Rotation = -45
ResizeGrip1.Size = UDim2.new(0, 12, 0, 2)

local ResizeGrip2 = Instance.new("Frame")
ResizeGrip2.Parent = ResizeHandle
ResizeGrip2.AnchorPoint = Vector2.new(0.5, 0.5)
ResizeGrip2.BackgroundColor3 = Theme.AccentLight
ResizeGrip2.BorderSizePixel = 0
ResizeGrip2.Position = UDim2.new(0.75, 0, 0.75, 0)
ResizeGrip2.Rotation = -45
ResizeGrip2.Size = UDim2.new(0, 6, 0, 2)

-- Minimize & Close Logic
local savedSize = UDim2.new(0, DefaultW, 0, DefaultH)

MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        savedSize = MainFrame.Size
        BodyFrame.Visible = false
        ResizeHandle.Visible = false
        TopDivider.Visible = false
        TopFix.Visible = false
        MinBarV.Visible = true
        Tween(MinBarV, FastInfo, {Size = UDim2.new(0, 2.5, 0, 14)})
        Tween(MainFrame, SmoothInfo, {Size = UDim2.new(0, savedSize.X.Offset, 0, 56)})
        if Config.UIBlur then
            Tween(BlurEffect, FastInfo, {Size = 0})
        end
    else
        Tween(MinBarV, FastInfo, {Size = UDim2.new(0, 2.5, 0, 0)})
        task.delay(0.12, function()
            if not isMinimized then MinBarV.Visible = false end
        end)
        TopDivider.Visible = true
        TopFix.Visible = true
        Tween(MainFrame, SmoothInfo, {Size = savedSize})
        if Config.UIBlur then
            BlurEffect.Enabled = true
            Tween(BlurEffect, SmoothInfo, {Size = 12})
        end
        task.delay(0.12, function()
            if not isMinimized then
                BodyFrame.Visible = true
                ResizeHandle.Visible = true
            end
        end)
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    Tween(CloseButton, FastInfo, {BackgroundColor3 = Theme.DangerHover})
    task.delay(0.15, function()
        Tween(CloseButton, FastInfo, {BackgroundColor3 = Theme.DangerBg})
    end)
    SetWindowVisible(false)
end)

-- Sidebar Navigation
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Parent = BodyFrame
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BackgroundTransparency = Config.UITransparency * 0.85
Sidebar.BorderSizePixel = 0
Sidebar.Position = UDim2.new(0, 10, 0, 10)
Sidebar.Size = UDim2.new(0, 176, 1, -20)
table.insert(TransparentFrames.Sub, Sidebar)

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 11)
SidebarCorner.Parent = Sidebar

local SidebarStroke = Instance.new("UIStroke")
SidebarStroke.Color = Theme.Stroke
SidebarStroke.Thickness = 1.1
SidebarStroke.Transparency = 0.3
SidebarStroke.Parent = Sidebar

local SidebarScroll = Instance.new("ScrollingFrame")
SidebarScroll.Parent = Sidebar
SidebarScroll.Active = true
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.BorderSizePixel = 0
SidebarScroll.Position = UDim2.new(0, 8, 0, 8)
SidebarScroll.Size = UDim2.new(1, -16, 1, -68)
SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 240)
SidebarScroll.ScrollBarThickness = 2
SidebarScroll.ScrollBarImageColor3 = Theme.AccentLight

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Parent = SidebarScroll
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 6)

TrackConnection(SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, SidebarLayout.AbsoluteContentSize.Y + 12)
end))

-- Bottom Player Profile Card
local ProfileFrame = Instance.new("Frame")
ProfileFrame.Parent = Sidebar
ProfileFrame.BackgroundColor3 = Theme.CardBg
ProfileFrame.BackgroundTransparency = Config.UITransparency * 0.65
ProfileFrame.Position = UDim2.new(0, 8, 1, -54)
ProfileFrame.Size = UDim2.new(1, -16, 0, 46)
table.insert(TransparentFrames.Cards, ProfileFrame)

local ProfileCorner = Instance.new("UICorner")
ProfileCorner.CornerRadius = UDim.new(0, 9)
ProfileCorner.Parent = ProfileFrame

local ProfileStroke = Instance.new("UIStroke")
ProfileStroke.Color = Theme.CardStroke
ProfileStroke.Thickness = 1
ProfileStroke.Transparency = 0.35
ProfileStroke.Parent = ProfileFrame

local AvatarIcon = Instance.new("ImageLabel")
AvatarIcon.Parent = ProfileFrame
AvatarIcon.BackgroundColor3 = Theme.Background
AvatarIcon.Position = UDim2.new(0, 7, 0.5, -16)
AvatarIcon.Size = UDim2.new(0, 32, 0, 32)
AvatarIcon.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150"

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(1, 0)
AvatarCorner.Parent = AvatarIcon

local ProfileName = Instance.new("TextLabel")
ProfileName.Parent = ProfileFrame
ProfileName.BackgroundTransparency = 1
ProfileName.Position = UDim2.new(0, 46, 0, 6)
ProfileName.Size = UDim2.new(1, -52, 0, 17)
ProfileName.Font = Typography.FontBold
ProfileName.Text = string.sub(LocalPlayer.Name, 1, 5) .. "***"
ProfileName.TextColor3 = Theme.TextPrimary
ProfileName.TextXAlignment = Enum.TextXAlignment.Left
RegisterText(ProfileName, Typography.ProfileTitle)

local ProfileStatus = Instance.new("TextLabel")
ProfileStatus.Parent = ProfileFrame
ProfileStatus.BackgroundTransparency = 1
ProfileStatus.Position = UDim2.new(0, 46, 0, 23)
ProfileStatus.Size = UDim2.new(1, -52, 0, 16)
ProfileStatus.Font = Typography.FontMedium
ProfileStatus.Text = "สถานะ: พร้อมใช้งานทุกแมพ"
ProfileStatus.TextColor3 = Theme.AccentLight
ProfileStatus.TextXAlignment = Enum.TextXAlignment.Left
RegisterText(ProfileStatus, Typography.ProfileSub)

-- Pages Holder (Dual-Column Layout)
local PagesHolder = Instance.new("Frame")
PagesHolder.Name = "PagesHolder"
PagesHolder.Parent = BodyFrame
PagesHolder.BackgroundTransparency = 1
PagesHolder.Position = UDim2.new(0, 196, 0, 10)
PagesHolder.Size = UDim2.new(1, -206, 1, -20)

local AllTabs = {}

local function CreateCategoryTab(tabName, orderIndex, leftHeaderTitle, rightHeaderTitle)
    local TabButton = Instance.new("TextButton")
    TabButton.Name = tabName .. "Tab"
    TabButton.Parent = SidebarScroll
    TabButton.BackgroundColor3 = Theme.CardBg
    TabButton.BackgroundTransparency = Config.UITransparency * 0.65
    TabButton.BorderSizePixel = 0
    TabButton.Size = UDim2.new(1, 0, 0, 42)
    TabButton.AutoButtonColor = false
    TabButton.Text = ""
    TabButton.LayoutOrder = orderIndex
    table.insert(TransparentFrames.Cards, TabButton)

    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 8)
    TabCorner.Parent = TabButton

    local IndicatorPill = Instance.new("Frame")
    IndicatorPill.Parent = TabButton
    IndicatorPill.AnchorPoint = Vector2.new(0, 0.5)
    IndicatorPill.BackgroundColor3 = Theme.TextSecondary
    IndicatorPill.Position = UDim2.new(0, 10, 0.5, 0)
    IndicatorPill.Size = UDim2.new(0, 4, 0, 14)

    local PillCorner = Instance.new("UICorner")
    PillCorner.CornerRadius = UDim.new(1, 0)
    PillCorner.Parent = IndicatorPill

    local TabLabel = Instance.new("TextLabel")
    TabLabel.Parent = TabButton
    TabLabel.BackgroundTransparency = 1
    TabLabel.Position = UDim2.new(0, 22, 0, 0)
    TabLabel.Size = UDim2.new(1, -28, 1, 0)
    TabLabel.Font = Typography.FontBold
    TabLabel.Text = tabName
    TabLabel.TextColor3 = Theme.TextSecondary
    TabLabel.TextXAlignment = Enum.TextXAlignment.Left
    RegisterText(TabLabel, Typography.TabText)

    local PageFrame = Instance.new("Frame")
    PageFrame.Name = tabName .. "Page"
    PageFrame.Parent = PagesHolder
    PageFrame.BackgroundTransparency = 1
    PageFrame.Size = UDim2.new(1, 0, 1, 0)
    PageFrame.Visible = false

    local function BuildColumn(headerText, posScale, sizeScale)
        local ColBox = Instance.new("Frame")
        ColBox.Parent = PageFrame
        ColBox.BackgroundColor3 = Theme.ColumnBg
        ColBox.BackgroundTransparency = Config.UITransparency * 0.85
        ColBox.Position = posScale
        ColBox.Size = sizeScale
        table.insert(TransparentFrames.Sub, ColBox)

        local ColCorner = Instance.new("UICorner")
        ColCorner.CornerRadius = UDim.new(0, 11)
        ColCorner.Parent = ColBox

        local ColStroke = Instance.new("UIStroke")
        ColStroke.Color = Theme.Stroke
        ColStroke.Thickness = 1.1
        ColStroke.Transparency = 0.3
        ColStroke.Parent = ColBox

        local HeaderLbl = Instance.new("TextLabel")
        HeaderLbl.Parent = ColBox
        HeaderLbl.BackgroundTransparency = 1
        HeaderLbl.Position = UDim2.new(0, 14, 0, 9)
        HeaderLbl.Size = UDim2.new(1, -28, 0, 22)
        HeaderLbl.Font = Typography.FontHeading
        HeaderLbl.Text = headerText
        HeaderLbl.TextColor3 = Theme.AccentLight
        HeaderLbl.TextXAlignment = Enum.TextXAlignment.Left
        RegisterText(HeaderLbl, Typography.SectionHeader)

        local HeaderLine = Instance.new("Frame")
        HeaderLine.Parent = ColBox
        HeaderLine.BackgroundColor3 = Theme.Stroke
        HeaderLine.BackgroundTransparency = 0.55
        HeaderLine.BorderSizePixel = 0
        HeaderLine.Position = UDim2.new(0, 12, 0, 34)
        HeaderLine.Size = UDim2.new(1, -24, 0, 1)

        local Scroll = Instance.new("ScrollingFrame")
        Scroll.Parent = ColBox
        Scroll.Active = true
        Scroll.BackgroundTransparency = 1
        Scroll.BorderSizePixel = 0
        Scroll.Position = UDim2.new(0, 8, 0, 40)
        Scroll.Size = UDim2.new(1, -16, 1, -48)
        Scroll.CanvasSize = UDim2.new(0, 0, 0, 340)
        Scroll.ScrollBarThickness = 2
        Scroll.ScrollBarImageColor3 = Theme.AccentLight

        local List = Instance.new("UIListLayout")
        List.Parent = Scroll
        List.SortOrder = Enum.SortOrder.LayoutOrder
        List.Padding = UDim.new(0, 7)

        TrackConnection(List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Scroll.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 14)
        end))

        return Scroll
    end

    local LeftColumn = BuildColumn(leftHeaderTitle, UDim2.new(0, 0, 0, 0), UDim2.new(0.5, -5, 1, 0))
    local RightColumn = BuildColumn(rightHeaderTitle, UDim2.new(0.5, 5, 0, 0), UDim2.new(0.5, -5, 1, 0))

    local tabEntry = {
        Button = TabButton,
        Label = TabLabel,
        Pill = IndicatorPill,
        Page = PageFrame,
        Left = LeftColumn,
        Right = RightColumn
    }
    table.insert(AllTabs, tabEntry)

    TabButton.MouseButton1Click:Connect(function()
        for _, item in ipairs(AllTabs) do
            item.Page.Visible = false
            Tween(item.Button, FastInfo, {BackgroundColor3 = Theme.CardBg})
            Tween(item.Label, FastInfo, {TextColor3 = Theme.TextSecondary})
            Tween(item.Pill, FastInfo, {
                BackgroundColor3 = Theme.TextSecondary,
                Size = UDim2.new(0, 4, 0, 14)
            })
        end
        PageFrame.Visible = true
        PageFrame.Position = UDim2.new(0, 0, 0, 5)
        Tween(PageFrame, SmoothInfo, {Position = UDim2.new(0, 0, 0, 0)})
        Tween(TabButton, FastInfo, {BackgroundColor3 = Theme.AccentDark})
        Tween(TabLabel, FastInfo, {TextColor3 = Theme.Background})
        Tween(IndicatorPill, FastInfo, {
            BackgroundColor3 = Theme.Background,
            Size = UDim2.new(0, 4, 0, 22)
        })
    end)

    return tabEntry
end

-- UI Component: Clean Toggle Card
local function CreateToggle(parentScroll, titleText, descText, defaultState, callback)
    local Card = Instance.new("Frame")
    Card.Parent = parentScroll
    Card.BackgroundColor3 = Theme.CardBg
    Card.BackgroundTransparency = Config.UITransparency * 0.65
    Card.Size = UDim2.new(1, 0, 0, 64)
    table.insert(TransparentFrames.Cards, Card)

    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 8)
    CardCorner.Parent = Card

    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = Theme.CardStroke
    CardStroke.Thickness = 1
    CardStroke.Transparency = 0.4
    CardStroke.Parent = Card

    local Title = Instance.new("TextLabel")
    Title.Parent = Card
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 12, 0, 6)
    Title.Size = UDim2.new(1, -66, 0, 20)
    Title.Font = Typography.FontBold
    Title.Text = titleText
    Title.TextColor3 = Theme.TextPrimary
    Title.TextXAlignment = Enum.TextXAlignment.Left
    RegisterText(Title, Typography.ItemTitle)

    local Desc = Instance.new("TextLabel")
    Desc.Parent = Card
    Desc.BackgroundTransparency = 1
    Desc.Position = UDim2.new(0, 12, 0, 27)
    Desc.Size = UDim2.new(1, -66, 0, 32)
    Desc.Font = Typography.FontMedium
    Desc.Text = descText
    Desc.TextColor3 = Theme.TextSecondary
    Desc.TextWrapped = true
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.TextYAlignment = Enum.TextYAlignment.Top
    RegisterText(Desc, Typography.ItemDesc)

    local SwitchBtn = Instance.new("TextButton")
    SwitchBtn.Parent = Card
    SwitchBtn.BackgroundColor3 = defaultState and Theme.AccentDark or Theme.Sidebar
    SwitchBtn.Position = UDim2.new(1, -50, 0.5, -11)
    SwitchBtn.Size = UDim2.new(0, 40, 0, 22)
    SwitchBtn.AutoButtonColor = false
    SwitchBtn.Text = ""

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = SwitchBtn

    local SwitchStroke = Instance.new("UIStroke")
    SwitchStroke.Color = defaultState and Theme.AccentLight or Theme.Stroke
    SwitchStroke.Thickness = 1
    SwitchStroke.Transparency = 0.35
    SwitchStroke.Parent = SwitchBtn

    local Circle = Instance.new("Frame")
    Circle.Parent = SwitchBtn
    Circle.BackgroundColor3 = defaultState and Theme.Background or Theme.TextSecondary
    Circle.Position = defaultState and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    Circle.Size = UDim2.new(0, 18, 0, 18)

    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle

    local toggled = defaultState or false
    SwitchBtn.MouseButton1Click:Connect(function()
        toggled = not toggled
        local targetPos = toggled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        local targetBg = toggled and Theme.AccentDark or Theme.Sidebar
        local targetCircle = toggled and Theme.Background or Theme.TextSecondary
        local targetStroke = toggled and Theme.AccentLight or Theme.Stroke

        Tween(SwitchBtn, FastInfo, {BackgroundColor3 = targetBg})
        Tween(SwitchStroke, FastInfo, {Color = targetStroke})
        Tween(Circle, FastInfo, {Position = targetPos, BackgroundColor3 = targetCircle})

        if callback then
            callback(toggled)
        end
    end)
end

-- UI Component: Direct Smooth Slider Card
local function CreateSlider(parentScroll, titleText, minVal, maxVal, defaultVal, callback)
    local Card = Instance.new("Frame")
    Card.Parent = parentScroll
    Card.BackgroundColor3 = Theme.CardBg
    Card.BackgroundTransparency = Config.UITransparency * 0.65
    Card.Size = UDim2.new(1, 0, 0, 58)
    table.insert(TransparentFrames.Cards, Card)

    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 8)
    CardCorner.Parent = Card

    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = Theme.CardStroke
    CardStroke.Thickness = 1
    CardStroke.Transparency = 0.4
    CardStroke.Parent = Card

    local Title = Instance.new("TextLabel")
    Title.Parent = Card
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 12, 0, 7)
    Title.Size = UDim2.new(0.68, 0, 0, 20)
    Title.Font = Typography.FontBold
    Title.Text = titleText
    Title.TextColor3 = Theme.TextPrimary
    Title.TextXAlignment = Enum.TextXAlignment.Left
    RegisterText(Title, Typography.ItemTitle)

    local ValueLbl = Instance.new("TextLabel")
    ValueLbl.Parent = Card
    ValueLbl.BackgroundTransparency = 1
    ValueLbl.Position = UDim2.new(0.68, 0, 0, 7)
    ValueLbl.Size = UDim2.new(0.32, -12, 0, 20)
    ValueLbl.Font = Typography.FontHeading
    ValueLbl.Text = tostring(defaultVal)
    ValueLbl.TextColor3 = Theme.AccentLight
    ValueLbl.TextXAlignment = Enum.TextXAlignment.Right
    RegisterText(ValueLbl, Typography.ItemTitle)

    local SliderBtn = Instance.new("TextButton")
    SliderBtn.Parent = Card
    SliderBtn.BackgroundColor3 = Theme.Sidebar
    SliderBtn.Position = UDim2.new(0, 12, 0, 36)
    SliderBtn.Size = UDim2.new(1, -24, 0, 8)
    SliderBtn.AutoButtonColor = false
    SliderBtn.Text = ""

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = SliderBtn

    local startPercent = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)

    local Fill = Instance.new("Frame")
    Fill.Parent = SliderBtn
    Fill.BackgroundColor3 = Theme.AccentDark
    Fill.Size = UDim2.new(startPercent, 0, 1, 0)

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill

    local Knob = Instance.new("Frame")
    Knob.Parent = SliderBtn
    Knob.BackgroundColor3 = Theme.AccentLight
    Knob.Position = UDim2.new(startPercent, -7, 0.5, -7)
    Knob.Size = UDim2.new(0, 14, 0, 14)

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob

    local isSliding = false
    local function UpdateFromInput(input)
        local barPos = SliderBtn.AbsolutePosition.X
        local barSize = SliderBtn.AbsoluteSize.X
        if barSize <= 0 then return end
        local ratio = math.clamp((input.Position.X - barPos) / barSize, 0, 1)
        local currentVal = math.floor(minVal + (maxVal - minVal) * ratio + 0.5)
        ValueLbl.Text = tostring(currentVal)
        Fill.Size = UDim2.new(ratio, 0, 1, 0)
        Knob.Position = UDim2.new(ratio, -7, 0.5, -7)
        if callback then
            callback(currentVal)
        end
    end

    TrackConnection(SliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSliding = true
            parentScroll.ScrollingEnabled = false
            UpdateFromInput(input)
        end
    end))

    TrackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if isSliding then
                isSliding = false
                parentScroll.ScrollingEnabled = true
            end
        end
    end))

    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if isSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateFromInput(input)
        end
    end))
end

-- UI Component: Dual Option Selector
local function CreateSelector(parentScroll, titleText, optionA, optionB, callback)
    local Card = Instance.new("Frame")
    Card.Parent = parentScroll
    Card.BackgroundColor3 = Theme.CardBg
    Card.BackgroundTransparency = Config.UITransparency * 0.65
    Card.Size = UDim2.new(1, 0, 0, 64)
    table.insert(TransparentFrames.Cards, Card)

    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 8)
    CardCorner.Parent = Card

    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = Theme.CardStroke
    CardStroke.Thickness = 1
    CardStroke.Transparency = 0.4
    CardStroke.Parent = Card

    local Title = Instance.new("TextLabel")
    Title.Parent = Card
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 12, 0, 6)
    Title.Size = UDim2.new(1, -24, 0, 20)
    Title.Font = Typography.FontBold
    Title.Text = titleText
    Title.TextColor3 = Theme.TextPrimary
    Title.TextXAlignment = Enum.TextXAlignment.Left
    RegisterText(Title, Typography.ItemTitle)

    local Holder = Instance.new("Frame")
    Holder.Parent = Card
    Holder.BackgroundColor3 = Theme.Sidebar
    Holder.Position = UDim2.new(0, 12, 0, 30)
    Holder.Size = UDim2.new(1, -24, 0, 26)

    local HolderCorner = Instance.new("UICorner")
    HolderCorner.CornerRadius = UDim.new(0, 6)
    HolderCorner.Parent = Holder

    local BtnA = Instance.new("TextButton")
    BtnA.Parent = Holder
    BtnA.BackgroundColor3 = Theme.AccentDark
    BtnA.Size = UDim2.new(0.5, 0, 1, 0)
    BtnA.AutoButtonColor = false
    BtnA.Font = Typography.FontBold
    BtnA.Text = optionA
    BtnA.TextColor3 = Theme.Background
    RegisterText(BtnA, Typography.ControlText)

    local CornerA = Instance.new("UICorner")
    CornerA.CornerRadius = UDim.new(0, 6)
    CornerA.Parent = BtnA

    local BtnB = Instance.new("TextButton")
    BtnB.Parent = Holder
    BtnB.BackgroundColor3 = Theme.Sidebar
    BtnB.Position = UDim2.new(0.5, 0, 0, 0)
    BtnB.Size = UDim2.new(0.5, 0, 1, 0)
    BtnB.AutoButtonColor = false
    BtnB.Font = Typography.FontBold
    BtnB.Text = optionB
    BtnB.TextColor3 = Theme.TextSecondary
    RegisterText(BtnB, Typography.ControlText)

    local CornerB = Instance.new("UICorner")
    CornerB.CornerRadius = UDim.new(0, 6)
    CornerB.Parent = BtnB

    BtnA.MouseButton1Click:Connect(function()
        Tween(BtnA, FastInfo, {BackgroundColor3 = Theme.AccentDark, TextColor3 = Theme.Background})
        Tween(BtnB, FastInfo, {BackgroundColor3 = Theme.Sidebar, TextColor3 = Theme.TextSecondary})
        if callback then callback(optionA) end
    end)

    BtnB.MouseButton1Click:Connect(function()
        Tween(BtnB, FastInfo, {BackgroundColor3 = Theme.AccentDark, TextColor3 = Theme.Background})
        Tween(BtnA, FastInfo, {BackgroundColor3 = Theme.Sidebar, TextColor3 = Theme.TextSecondary})
        if callback then callback(optionB) end
    end)
end

-- UI Component: Color Swatch Palette Selector
local function CreateColorPalette(parentScroll, titleText, presets, callback)
    local Card = Instance.new("Frame")
    Card.Parent = parentScroll
    Card.BackgroundColor3 = Theme.CardBg
    Card.BackgroundTransparency = Config.UITransparency * 0.65
    Card.Size = UDim2.new(1, 0, 0, 68)
    table.insert(TransparentFrames.Cards, Card)

    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 8)
    CardCorner.Parent = Card

    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = Theme.CardStroke
    CardStroke.Thickness = 1
    CardStroke.Transparency = 0.4
    CardStroke.Parent = Card

    local Title = Instance.new("TextLabel")
    Title.Parent = Card
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 12, 0, 6)
    Title.Size = UDim2.new(0.65, 0, 0, 20)
    Title.Font = Typography.FontBold
    Title.Text = titleText
    Title.TextColor3 = Theme.TextPrimary
    Title.TextXAlignment = Enum.TextXAlignment.Left
    RegisterText(Title, Typography.ItemTitle)

    local SelectedLbl = Instance.new("TextLabel")
    SelectedLbl.Parent = Card
    SelectedLbl.BackgroundTransparency = 1
    SelectedLbl.Position = UDim2.new(0.65, 0, 0, 6)
    SelectedLbl.Size = UDim2.new(0.35, -12, 0, 20)
    SelectedLbl.Font = Typography.FontBold
    SelectedLbl.Text = presets[1].Name
    SelectedLbl.TextColor3 = presets[1].Color
    SelectedLbl.TextXAlignment = Enum.TextXAlignment.Right
    RegisterText(SelectedLbl, Typography.ControlText)

    local SwatchRow = Instance.new("Frame")
    SwatchRow.Parent = Card
    SwatchRow.BackgroundTransparency = 1
    SwatchRow.Position = UDim2.new(0, 12, 0, 32)
    SwatchRow.Size = UDim2.new(1, -24, 0, 26)

    local SwatchLayout = Instance.new("UIListLayout")
    SwatchLayout.Parent = SwatchRow
    SwatchLayout.FillDirection = Enum.FillDirection.Horizontal
    SwatchLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    SwatchLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    SwatchLayout.Padding = UDim.new(0, 6)

    local SwatchStrokes = {}

    for idx, preset in ipairs(presets) do
        local SwatchBtn = Instance.new("TextButton")
        SwatchBtn.Parent = SwatchRow
        SwatchBtn.BackgroundColor3 = preset.Color
        SwatchBtn.Size = UDim2.new(0, 22, 0, 22)
        SwatchBtn.AutoButtonColor = false
        SwatchBtn.Text = ""

        local SwatchCorner = Instance.new("UICorner")
        SwatchCorner.CornerRadius = UDim.new(1, 0)
        SwatchCorner.Parent = SwatchBtn

        local SwatchStroke = Instance.new("UIStroke")
        SwatchStroke.Color = Color3.fromRGB(255, 255, 255)
        SwatchStroke.Thickness = (idx == 1) and 2.2 or 0
        SwatchStroke.Parent = SwatchBtn
        table.insert(SwatchStrokes, SwatchStroke)

        SwatchBtn.MouseButton1Click:Connect(function()
            for _, st in ipairs(SwatchStrokes) do
                st.Thickness = 0
            end
            SwatchStroke.Thickness = 2.2
            SelectedLbl.Text = preset.Name
            SelectedLbl.TextColor3 = preset.Color
            if callback then
                callback(preset.Color)
            end
        end)
    end
end

-- UI Component: Action Button Card
local function CreateButton(parentScroll, titleText, btnLabel, callback)
    local Card = Instance.new("Frame")
    Card.Parent = parentScroll
    Card.BackgroundColor3 = Theme.CardBg
    Card.BackgroundTransparency = Config.UITransparency * 0.65
    Card.Size = UDim2.new(1, 0, 0, 48)
    table.insert(TransparentFrames.Cards, Card)

    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 8)
    CardCorner.Parent = Card

    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = Theme.CardStroke
    CardStroke.Thickness = 1
    CardStroke.Transparency = 0.4
    CardStroke.Parent = Card

    local Title = Instance.new("TextLabel")
    Title.Parent = Card
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.Size = UDim2.new(0.56, 0, 1, 0)
    Title.Font = Typography.FontBold
    Title.Text = titleText
    Title.TextColor3 = Theme.TextPrimary
    Title.TextXAlignment = Enum.TextXAlignment.Left
    RegisterText(Title, Typography.ItemTitle)

    local ActBtn = Instance.new("TextButton")
    ActBtn.Parent = Card
    ActBtn.BackgroundColor3 = Theme.AccentDark
    ActBtn.Position = UDim2.new(0.58, 0, 0.5, -14)
    ActBtn.Size = UDim2.new(0.42, -12, 0, 28)
    ActBtn.AutoButtonColor = false
    ActBtn.Font = Typography.FontBold
    ActBtn.Text = btnLabel
    ActBtn.TextColor3 = Theme.Background
    RegisterText(ActBtn, Typography.ControlText)

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = ActBtn

    ActBtn.MouseButton1Click:Connect(function()
        Tween(ActBtn, FastInfo, {BackgroundColor3 = Theme.AccentLight})
        task.delay(0.14, function()
            Tween(ActBtn, FastInfo, {BackgroundColor3 = Theme.AccentDark})
        end)
        if callback then callback(ActBtn) end
    end)
end

-- Forward Declarations for Movement & Cosmetic Helpers
local SyncCharacterMovement = function() end
local UpdateCharacterAura = function() end
local ApplyNeonWeapon = function() end
local SavedLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows
}

-- Build All 4 Core Category Tabs
local TabEsp = CreateCategoryTab("มองทะลุ (ESP)", 1, "ระบบผู้เล่นและเส้นชี้ (ทุกแมพ)", "ปรับแต่งสีและข้อมูลเสริม")
local TabMove = CreateCategoryTab("การเคลื่อนไหว", 2, "ระบบวิ่งไว สไลด์ และขับรถ", "ระบบกระโดดสูง ทะลุกำแพง และบิน")
local TabSkin = CreateCategoryTab("คอสเมติก & FPS", 3, "สกิน แสงสว่าง และเอฟเฟกต์", "ลดแลคและบูสต์เฟรมเรต")
local TabSetting = CreateCategoryTab("ตั้งค่าเมนู", 4, "ปรับแต่งธีมและระบบป้องกัน", "จัดการหน้าต่างและเครดิต")

-- ==========================================
-- TAB 1: มองทะลุ (UNIVERSAL ESP)
-- ==========================================
CreateToggle(TabEsp.Left, "เปิด/ปิด มองทะลุทั้งหมด (รองรับทุกแมพ)", "สวิตช์หลักสำหรับทำงานระบบมองทะลุทั้งมือถือและคอม", Config.ESPMaster, function(state)
    Config.ESPMaster = state
end)
CreateToggle(TabEsp.Left, "แสดงกรอบผู้เล่น Box ESP (ทุกแมพ)", "ตีกรอบสี่เหลี่ยมรอบตัวผู้เล่นแบบเรียลไทม์", Config.ESPBox, function(state)
    Config.ESPBox = state
end)
CreateSelector(TabEsp.Left, "รูปแบบกรอบ ESP", "กรอบเต็ม", "กรอบมุม", function(opt)
    Config.ESPBoxStyle = opt
end)
CreateToggle(TabEsp.Left, "พื้นหลังโปร่งใสในกรอบ (ทุกแมพ)", "เติมสีพื้นหลังจางๆ ด้านในกรอบสี่เหลี่ยม", Config.ESPBoxFill, function(state)
    Config.ESPBoxFill = state
end)
CreateToggle(TabEsp.Left, "เส้นชี้ตำแหน่ง Tracer (ทุกแมพ)", "ลากเส้นชี้ตำแหน่งจากหน้าจอไปยังผู้เล่น", Config.ESPTracer, function(state)
    Config.ESPTracer = state
end)
CreateSelector(TabEsp.Left, "จุดเริ่มต้นเส้น Tracer", "ล่างจอ", "กลางจอ", function(opt)
    Config.ESPTracerOrigin = opt
end)
CreateToggle(TabEsp.Left, "จุดเล็งศีรษะ Head Dot (ทุกแมพ)", "แสดงวงกลมชี้ตำแหน่งศีรษะของเป้าหมาย", Config.ESPHeadDot, function(state)
    Config.ESPHeadDot = state
end)
CreateToggle(TabEsp.Left, "ไฮไลท์ตัวละคร Chams (ทุกแมพ)", "เรืองแสงตัวละครทะลุกำแพงและสิ่งกีดขวาง", Config.ESPChams, function(state)
    Config.ESPChams = state
end)

CreateColorPalette(TabEsp.Right, "เลือกสี ESP (กรอบ/เส้น/ไฮไลท์)", ESPColorPresets, function(selectedColor)
    Config.ESPColor = selectedColor
    UpdateCharacterAura()
    ApplyNeonWeapon()
end)
CreateToggle(TabEsp.Right, "โหมดสีรุ้ง Rainbow ESP (ทุกแมพ)", "ไล่เฉดสี RGB อัตโนมัติทั้งกรอบ เส้น และไฮไลท์", Config.ESPRainbow, function(state)
    Config.ESPRainbow = state
end)
CreateSlider(TabEsp.Right, "ความหนากรอบและเส้น", 1, 5, Config.ESPThickness, function(val)
    Config.ESPThickness = val
end)
CreateToggle(TabEsp.Right, "แสดงชื่อและระยะห่าง (ทุกแมพ)", "แสดงชื่อผู้เล่นและระยะห่างเหนือศีรษะ", Config.ESPNameDist, function(state)
    Config.ESPNameDist = state
end)
CreateToggle(TabEsp.Right, "แสดงอาวุธที่ถืออยู่ (เฉพาะบางแมพ)", "แสดงชื่อปืนหรือไอเทมในมือของเป้าหมายใต้กรอบ", Config.ESPWeapon, function(state)
    Config.ESPWeapon = state
end)
CreateToggle(TabEsp.Right, "แสดงหลอดเลือดและตัวเลข (ทุกแมพ)", "แสดงแถบพลังชีวิตและเปอร์เซ็นต์เลือดข้างกรอบ", Config.ESPHealth, function(state)
    Config.ESPHealth = state
end)
CreateToggle(TabEsp.Right, "ซ่อนเพื่อนร่วมทีม (เฉพาะแมพมีทีม)", "ไม่แสดง ESP กับผู้เล่นที่อยู่ทีมเดียวกัน", Config.ESPTeamCheck, function(state)
    Config.ESPTeamCheck = state
end)
CreateToggle(TabEsp.Right, "มองซอมบี้ / บอท / มอนสเตอร์ (เฉพาะบางแมพ)", "แสดงกรอบและไฮไลท์ซอมบี้ บอท หรือมอนสเตอร์ในแมพ", Config.ESPZombies, function(state)
    Config.ESPZombies = state
end)
CreateToggle(TabEsp.Right, "มองของดรอป / กล่องไอเทม (เฉพาะบางแมพ)", "แสดงตำแหน่งสิ่งของ อาวุธ และกล่องที่ตกอยู่ตามพื้น", Config.ESPItems, function(state)
    Config.ESPItems = state
end)
CreateToggle(TabEsp.Right, "มองพาหนะ / ร่างสลบ / โล่ (เฉพาะบางแมพ)", "แสดงตำแหน่งรถยนต์ ร่างผู้เล่น และโล่กำบังในแมพ", Config.ESPExtras, function(state)
    Config.ESPExtras = state
end)
CreateSlider(TabEsp.Right, "ระยะมองทะลุสูงสุด (เมตร)", 100, 3000, Config.ESPMaxDist, function(val)
    Config.ESPMaxDist = val
end)

-- ==========================================
-- TAB 2: การเคลื่อนไหว (UNIVERSAL MOVEMENT)
-- ==========================================
CreateToggle(TabMove.Left, "วิ่งไวพิเศษ Speed Boost (รองรับทุกแมพ)", "เพิ่มความเร็วเดินและวิ่ง ทะลุสคริปต์ล็อคความเร็วทุกแมพ", Config.SpeedBoost, function(state)
    Config.SpeedBoost = state
    SyncCharacterMovement()
end)
CreateSlider(TabMove.Left, "ระดับความเร็ววิ่ง", 16, 150, Config.WalkSpeed, function(val)
    Config.WalkSpeed = val
    SyncCharacterMovement()
end)
CreateSelector(TabMove.Left, "โหมดเร่งความเร็ววิ่ง", "ผสม (แนะนำ)", "วาร์ปสเต็ป (ทะลุล็อค)", function(opt)
    Config.SpeedMethod = opt
end)
CreateToggle(TabMove.Left, "สไลด์ไวพิเศษ (เฉพาะบางแมพ)", "เพิ่มความเร็วพุ่งตัวเวลากดย่อหรือสไลด์ (C / Ctrl)", Config.FastSlide, function(state)
    Config.FastSlide = state
end)
CreateSlider(TabMove.Left, "ความเร็วการสไลด์", 30, 180, Config.SlideSpeed, function(val)
    Config.SlideSpeed = val
end)
CreateToggle(TabMove.Left, "ขับรถไวพิเศษ (เฉพาะแมพที่มีรถ)", "เร่งความเร็วและแรงบิดเมื่อนั่งขับรถยนต์หรือพาหนะ", Config.FastCar, function(state)
    Config.FastCar = state
end)
CreateSlider(TabMove.Left, "ความเร็วรถสูงสุด", 50, 300, Config.CarSpeed, function(val)
    Config.CarSpeed = val
end)

CreateToggle(TabMove.Right, "กระโดดสูงพิเศษ High Jump (รองรับทุกแมพ)", "ส่งแรงยกตัวละครต่อเนื่องเมื่อกดกระโดด ทะลุล็อคกระโดดทุกแมพ", Config.HighJump, function(state)
    Config.HighJump = state
    SyncCharacterMovement()
end)
CreateSlider(TabMove.Right, "ระดับความสูงกระโดด", 50, 220, Config.JumpPower, function(val)
    Config.JumpPower = val
    SyncCharacterMovement()
end)
CreateToggle(TabMove.Right, "กระโดดไม่จำกัด Inf Jump (รองรับทุกแมพ)", "กดกระโดดซ้ำกลางอากาศได้ต่อเนื่องทั้งมือถือและคอม", Config.InfiniteJump, function(state)
    Config.InfiniteJump = state
end)
CreateToggle(TabMove.Right, "เดินทะลุกำแพง Noclip (รองรับทุกแมพ)", "เดินทะลุสิ่งกีดขวาง กำแพง และประตูได้ทั้งหมด", Config.Noclip, function(state)
    Config.Noclip = state
    if not state and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and (part.Name == "HumanoidRootPart" or part.Name == "Torso" or part.Name == "UpperTorso" or part.Name == "LowerTorso") then
                part.CanCollide = true
            end
        end
    end
end)
CreateToggle(TabMove.Right, "โหมดบินอิสระ Fly (รองรับทุกแมพ)", "บินกลางอากาศตามทิศทางกล้อง ใช้ได้ทั้งมือถือและคอม", Config.FlyMode, function(state)
    Config.FlyMode = state
end)
CreateSlider(TabMove.Right, "ความเร็วการบิน", 15, 160, Config.FlySpeed, function(val)
    Config.FlySpeed = val
end)

-- ==========================================
-- TAB 3: คอสเมติก & บูสต์ FPS
-- ==========================================
CreateToggle(TabSkin.Left, "มองสว่างกลางคืน FullBright (ทุกแมพ)", "ปรับแสงแมพให้สว่างชัดเจนแม้เป็นเวลากลางคืนหรือในตึกมืด", Config.FullBright, function(state)
    Config.FullBright = state
    if not state then
        pcall(function()
            Lighting.Ambient = SavedLighting.Ambient
            Lighting.OutdoorAmbient = SavedLighting.OutdoorAmbient
            Lighting.Brightness = SavedLighting.Brightness
            Lighting.ClockTime = SavedLighting.ClockTime
            Lighting.FogEnd = SavedLighting.FogEnd
        end)
    end
end)
CreateToggle(TabSkin.Left, "ออร่าเรืองแสงรอบตัว (ทุกแมพ)", "สร้างวงแสงนีออนและประกายรอบตัวละครตามสี ESP", Config.CharacterAura, function(state)
    Config.CharacterAura = state
    UpdateCharacterAura()
end)
CreateToggle(TabSkin.Left, "อาวุธเรืองแสงนีออน (เฉพาะบางแมพ)", "เปลี่ยนวัสดุอาวุธหรือสิ่งของที่ถือเป็นนีออนตามสี ESP", Config.NeonWeapon, function(state)
    Config.NeonWeapon = state
    ApplyNeonWeapon()
end)
CreateToggle(TabSkin.Left, "ปลดล็อกสกินทั้งหมด (เฉพาะบางแมพ)", "เปิดค่าสกินอาวุธและไอเทมในข้อมูลผู้เล่น", Config.UnlockSkins, function(state)
    Config.UnlockSkins = state
    if state then
        task.spawn(function()
            pcall(function()
                for _, v in ipairs(LocalPlayer:GetDescendants()) do
                    local n = string.lower(v.Name)
                    if v:IsA("BoolValue") and (string.find(n, "skin") or string.find(n, "unlock") or string.find(n, "owned")) then
                        v.Value = true
                    end
                end
            end)
        end)
    end
end)

CreateToggle(TabSkin.Right, "ลดเอฟเฟกต์ ลดแลค (ทุกแมพ)", "ปิดอนุภาค ควัน ไฟ และเอฟเฟกต์ระเบิดในแมพ", Config.ReduceEffects, function(state)
    Config.ReduceEffects = state
    if state then
        task.spawn(function()
            for idx, obj in ipairs(Workspace:GetDescendants()) do
                if (obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Trail")) and obj.Name ~= "ProScriptAuraSpark" then
                    obj.Enabled = false
                end
                if idx % 450 == 0 then task.wait() end
            end
        end)
    end
end)
CreateToggle(TabSkin.Right, "ลดกราฟิกพื้นผิว (ทุกแมพ)", "ปรับวัสดุแมพให้เรียบเนียนและปิดเงาเพื่อลดภาระเครื่อง", Config.LowGraphics, function(state)
    Config.LowGraphics = state
    if state then
        Lighting.GlobalShadows = false
        task.spawn(function()
            for idx, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not (LocalPlayer.Character and obj:IsDescendantOf(LocalPlayer.Character)) then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Reflectance = 0
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = 1
                end
                if idx % 450 == 0 then task.wait() end
            end
        end)
    else
        Lighting.GlobalShadows = SavedLighting.GlobalShadows
    end
end)
CreateToggle(TabSkin.Right, "บูสต์ FPS สูงสุด (ทุกแมพ)", "ปิด PostEffect หมอก และเบลอของเกมเพื่อเพิ่มเฟรมเรตสูงสุด", Config.FPSBoost, function(state)
    Config.FPSBoost = state
    if state then
        Lighting.FogEnd = 9e9
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") and effect.Name ~= "ProScriptBlur" then
                effect.Enabled = false
            end
        end
    end
end)

-- ==========================================
-- TAB 4: ตั้งค่าเมนู (SETTINGS)
-- ==========================================
CreateSlider(TabSetting.Left, "ขนาดตัวอักษร (%)", 90, 125, Config.UIFontScale, function(val)
    ApplyFontScale(val)
end)
CreateSlider(TabSetting.Left, "ความโปร่งใสพื้นหลัง (%)", 0, 80, 4, function(val)
    ApplyTransparency(val / 100)
end)
CreateToggle(TabSetting.Left, "เบลอฉากหลังขณะเปิดเมนู", "เปิดเอฟเฟกต์เบลอภาพพื้นหลังเพื่อความสมูทสบายตา", Config.UIBlur, function(state)
    Config.UIBlur = state
    BlurEffect.Enabled = state and isWindowOpen and not isMinimized
    if BlurEffect.Enabled then
        Tween(BlurEffect, SmoothInfo, {Size = 12})
    end
end)
CreateToggle(TabSetting.Left, "โหมดธีมสีซอฟต์สบายตา", "ปรับสีพื้นหลังเมนูให้สว่างและนุ่มนวลขึ้น", Config.LightSoftTheme, function(state)
    Config.LightSoftTheme = state
    if state then
        Theme.Background = Color3.fromRGB(22, 32, 26)
        Theme.Sidebar = Color3.fromRGB(27, 40, 33)
        Theme.ColumnBg = Color3.fromRGB(31, 46, 37)
        Theme.CardBg = Color3.fromRGB(38, 56, 46)
    else
        Theme.Background = Color3.fromRGB(13, 18, 15)
        Theme.Sidebar = Color3.fromRGB(17, 24, 20)
        Theme.ColumnBg = Color3.fromRGB(20, 29, 24)
        Theme.CardBg = Color3.fromRGB(26, 38, 31)
    end
    Tween(MainFrame, SmoothInfo, {BackgroundColor3 = Theme.Background})
    Tween(OpenButton, SmoothInfo, {BackgroundColor3 = Theme.Background})
    for _, f in ipairs(TransparentFrames.Sub) do
        Tween(f, SmoothInfo, {BackgroundColor3 = Theme.Sidebar})
    end
    for _, c in ipairs(TransparentFrames.Cards) do
        if c ~= AllTabs[1].Button then
            Tween(c, SmoothInfo, {BackgroundColor3 = Theme.CardBg})
        end
    end
end)
CreateToggle(TabSetting.Left, "ระบบกันแบน Anti-Ban (รองรับทุกแมพ)", "บล็อกรีโมทตรวจจับความผิดปกติและป้องกันการโดนเตะอัตโนมัติ", Config.AntiBan, function(state)
    Config.AntiBan = state
end)
CreateToggle(TabSetting.Left, "ป้องกันหลุด Anti-AFK (ทุกแมพ)", "ขยับสถานะจำลองอัตโนมัติไม่ให้โดนเตะออกจากเซิร์ฟเวอร์", Config.AntiAFK, function(state)
    Config.AntiAFK = state
end)

CreateButton(TabSetting.Right, "ช่องยูทูป: ช่องนี้เรื่องโปร", "เรื่องโปร Hub", function() end)
CreateButton(TabSetting.Right, "ดิสคอร์ดกลุ่มพูดคุย", "คัดลอกลิงก์", function(btn)
    pcall(function()
        if setclipboard then
            setclipboard("https://discord.gg/gZpkSgmR8")
            btn.Text = "คัดลอกแล้ว!"
            task.wait(1.5)
            btn.Text = "คัดลอกลิงก์"
        end
    end)
end)
CreateButton(TabSetting.Right, "รีเซ็ตตำแหน่งปุ่มเปิด/ปิด", "ซ้ายบนกลางๆ", function()
    Tween(OpenButton, SmoothInfo, {Position = DefaultOpenBtnPos})
end)
CreateButton(TabSetting.Right, "คืนค่าขนาดหน้าต่าง", "ขนาดมาตรฐาน", function()
    Tween(MainFrame, SmoothInfo, {Size = UDim2.new(0, DefaultW, 0, DefaultH)})
    savedSize = UDim2.new(0, DefaultW, 0, DefaultH)
end)
CreateButton(TabSetting.Right, "ปิดสคริปต์ถาวร", "ลบเมนู", function()
    Config.ESPMaster = false
    Config.SpeedBoost = false
    Config.HighJump = false
    Config.FlyMode = false
    Config.Noclip = false
    Config.CharacterAura = false
    SyncCharacterMovement()
    UpdateCharacterAura()
    pcall(function()
        RunService:UnbindFromRenderStep("ProScriptMovementOverride")
    end)
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Connections)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Highlight") and obj.Name == "ProScriptHL" then
            obj:Destroy()
        end
    end
    if BlurEffect then BlurEffect:Destroy() end
    ScreenGui:Destroy()
end)

-- Activate First Tab by Default
AllTabs[1].Page.Visible = true
AllTabs[1].Button.BackgroundColor3 = Theme.AccentDark
AllTabs[1].Label.TextColor3 = Theme.Background
AllTabs[1].Pill.BackgroundColor3 = Theme.Background
AllTabs[1].Pill.Size = UDim2.new(0, 4, 0, 22)

-- Resize Handle Interaction
local isResizing = false
local resizeInput = nil
local resizeStart = nil
local initialSize = nil

TrackConnection(ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = true
        resizeStart = input.Position
        initialSize = MainFrame.Size

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isResizing = false
            end
        end)
    end
end))

TrackConnection(ResizeHandle.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        resizeInput = input
    end
end))

TrackConnection(UserInputService.InputChanged:Connect(function(input)
    if input == resizeInput and isResizing and not isMinimized then
        local delta = input.Position - resizeStart
        local scaleDiv = MainScale.Scale > 0 and MainScale.Scale or 1
        local newW = math.clamp(initialSize.X.Offset + (delta.X / scaleDiv), MinW, MaxW)
        local newH = math.clamp(initialSize.Y.Offset + (delta.Y / scaleDiv), MinH, MaxH)
        MainFrame.Size = UDim2.new(0, newW, 0, newH)
        savedSize = MainFrame.Size
    end
end))

-- ==========================================
-- UNIVERSAL ANTI-CHEAT REMOTE GUARD & ANTI-AFK
-- ==========================================
local BlockedRemoteNames = {
    ["WarZFespRemote"] = true,
    ["MotionProbe"] = true,
    ["CharacterSyncProbeReport"] = true,
    ["WarZPlayerReport"] = true,
    ["Killcam_Report"] = true
}

pcall(function()
    if hookmetamethod and getnamecallmethod and checkcaller then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() and Config.AntiBan and (method == "FireServer" or method == "InvokeServer") then
                if typeof(self) == "Instance" and BlockedRemoteNames[self.Name] then
                    return nil
                end
            end
            return oldNamecall(self, ...)
        end))
    end
end)

TrackConnection(LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end))

-- ==========================================
-- UNIVERSAL CHARACTER & RIG RESOLVER
-- ==========================================
local HeadPartNames = {"Head", "HeadHB", "FakeHead", "HeadHitbox", "HitboxHead", "HeadPart", "HeadBox", "head"}
local TorsoPartNames = {"HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso", "Hitbox", "Collider", "Body", "Chest", "RootPart"}
local UniversalPlayerFolders = {
    "Characters",
    "Players",
    "Entities",
    "Live",
    "Actors",
    "Bodies",
    "Units",
    "PlayerModels",
    "Ingame",
    "PorZHitboxes",
    "WarZSpatialActors_farm_colorado",
    "RC55_PrivateCandidateDynamics"
}

local function ResolveModelAnatomy(model)
    if not model or not model.Parent then return nil, nil, nil, nil end

    local hum = model:FindFirstChildOfClass("Humanoid")
    local head = nil
    local torso = nil
    local hrp = model:FindFirstChild("HumanoidRootPart")

    for _, name in ipairs(HeadPartNames) do
        local found = model:FindFirstChild(name) or model:FindFirstChild(name, true)
        if found and found:IsA("BasePart") then
            head = found
            break
        end
    end

    for _, name in ipairs(TorsoPartNames) do
        local found = model:FindFirstChild(name) or model:FindFirstChild(name, true)
        if found and found:IsA("BasePart") then
            torso = found
            break
        end
    end

    local root = hrp or torso or head or (model:IsA("Model") and model.PrimaryPart) or model:FindFirstChildWhichIsA("BasePart", true)

    -- Anti-Fake-HRP Check
    local refBody = (torso ~= hrp and torso) or head
    if hrp and refBody and (hrp.Position - refBody.Position).Magnitude > 18 then
        root = refBody
    end

    if not head then head = root end
    if not torso then torso = root end

    return root, head, torso, hum
end

local MyCachedModel, MyCachedRoot, MyCachedHum = nil, nil, nil

local function GetLocalAnatomy()
    local char = LocalPlayer.Character
    if not char or not char.Parent then
        local wsChar = Workspace:FindFirstChild(LocalPlayer.Name)
        if wsChar and wsChar:IsA("Model") then
            char = wsChar
        else
            char = MyCachedModel
        end
    end
    if not char or not char.Parent then
        return nil, nil, nil
    end

    local hum = char:FindFirstChildOfClass("Humanoid") or MyCachedHum
    local root = char:FindFirstChild("HumanoidRootPart")
        or char.PrimaryPart
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
        or char:FindFirstChildWhichIsA("BasePart", true)
        or MyCachedRoot

    MyCachedModel = char
    MyCachedHum = hum
    MyCachedRoot = root
    return char, hum, root
end

-- Calculate Desired Move Direction (Mobile Thumbstick + Humanoid.MoveDirection + PC WASD Fallback)
local function GetActiveMoveDirection(hum)
    if hum and hum.MoveDirection.Magnitude > 0.02 then
        local md = hum.MoveDirection
        local flat = Vector3.new(md.X, 0, md.Z)
        if flat.Magnitude > 0.01 then
            return flat.Unit
        end
        return md.Unit
    end

    if not UserInputService:GetFocusedTextBox() and Camera then
        local fwd = 0
        local right = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then fwd = fwd + 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then fwd = fwd - 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then right = right + 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then right = right - 1 end

        if fwd ~= 0 or right ~= 0 then
            local camLook = Camera.CFrame.LookVector
            local camRight = Camera.CFrame.RightVector
            local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
            local flatRight = Vector3.new(camRight.X, 0, camRight.Z)
            local combined = (flatLook.Magnitude > 0.01 and flatLook.Unit * fwd or Vector3.zero)
                + (flatRight.Magnitude > 0.01 and flatRight.Unit * right or Vector3.zero)
            if combined.Magnitude > 0.01 then
                return combined.Unit
            end
        end
    end

    return Vector3.zero
end

SyncCharacterMovement = function()
    local _, hum, _ = GetLocalAnatomy()
    if not hum then return end
    pcall(function()
        if Config.SpeedBoost then
            hum.WalkSpeed = Config.WalkSpeed
        else
            hum.WalkSpeed = 16
        end
        if Config.HighJump then
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            hum.UseJumpPower = true
            hum.JumpPower = Config.JumpPower
            hum.JumpHeight = math.clamp(Config.JumpPower * 0.16, 7.2, 80)
        else
            hum.JumpPower = 50
            hum.JumpHeight = 7.2
        end
    end)
end

-- ==========================================
-- GUARANTEED MULTI-FRAME HIGH JUMP & INFINITE JUMP ENGINE
-- ==========================================
local ActiveJumpBoostUntil = 0
local ActiveJumpTargetVel = 50
local LastJumpTriggerTick = 0

local function TriggerUniversalJump(isAirJump)
    local _, hum, root = GetLocalAnatomy()
    if not root or not root.Parent then return end

    local now = tick()
    if not isAirJump and (now - LastJumpTriggerTick < 0.18) then return end
    LastJumpTriggerTick = now

    local jumpVel = Config.HighJump and Config.JumpPower or 56
    ActiveJumpTargetVel = jumpVel
    ActiveJumpBoostUntil = now + 0.16

    pcall(function()
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            hum.UseJumpPower = true
            hum.JumpPower = jumpVel
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        local curVel = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(curVel.X, jumpVel, curVel.Z)
        root.CFrame = root.CFrame + Vector3.new(0, 1.25, 0)
    end)
end

-- Trigger 1: Standard JumpRequest (Mobile & PC)
TrackConnection(UserInputService.JumpRequest:Connect(function()
    local _, hum, root = GetLocalAnatomy()
    if not root then return end

    if Config.InfiniteJump then
        TriggerUniversalJump(true)
    elseif Config.HighJump then
        local isGrounded = (not hum)
            or (hum.FloorMaterial ~= Enum.Material.Air)
            or (math.abs(root.AssemblyLinearVelocity.Y) < 6)
        if isGrounded then
            TriggerUniversalJump(false)
        end
    end
end))

-- Trigger 2: Direct PC Spacebar & Slide Key Listener
local isSlideKeyHeld = false

TrackConnection(UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.LeftControl then
        isSlideKeyHeld = true
    end
    if not gp and input.KeyCode == Enum.KeyCode.Space then
        if Config.InfiniteJump then
            TriggerUniversalJump(true)
        elseif Config.HighJump then
            local _, hum, root = GetLocalAnatomy()
            local isGrounded = (not hum)
                or (hum.FloorMaterial ~= Enum.Material.Air)
                or (root and math.abs(root.AssemblyLinearVelocity.Y) < 6)
            if isGrounded then
                TriggerUniversalJump(false)
            end
        end
    end
end))

TrackConnection(UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.LeftControl then
        isSlideKeyHeld = false
    end
end))

-- Trigger 3: Mobile TouchGui JumpButton Hook
local BoundJumpButtons = {}
local function BindMobileJumpButtons()
    pcall(function()
        for _, guiObj in ipairs(PlayerGui:GetDescendants()) do
            if (guiObj:IsA("ImageButton") or guiObj:IsA("TextButton")) and not BoundJumpButtons[guiObj] then
                local n = string.lower(guiObj.Name)
                if n == "jumpbutton" or string.find(n, "jump") then
                    BoundJumpButtons[guiObj] = true
                    TrackConnection(guiObj.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                            if Config.InfiniteJump then
                                TriggerUniversalJump(true)
                            elseif Config.HighJump then
                                TriggerUniversalJump(false)
                            end
                        end
                    end))
                end
            end
        end
    end)
end
task.spawn(BindMobileJumpButtons)

-- ==========================================
-- GUARANTEED CROSS-MAP WALKSPEED, NOCLIP & FLY ENGINE
-- ==========================================
local MoveRayParams = RaycastParams.new()
MoveRayParams.FilterType = Enum.RaycastFilterType.Exclude
MoveRayParams.IgnoreWater = true

RunService:BindToRenderStep("ProScriptMovementOverride", Enum.RenderPriority.Character.Value + 5, function(dt)
    if not ScreenGui.Parent then return end
    local char, hum, root = GetLocalAnatomy()
    if not char or not root or not root.Parent then return end

    local clampedDt = math.clamp(dt, 0.001, 0.05)

    -- 1. Sustained Multi-Frame HighJump / InfiniteJump Upward Lift
    if tick() < ActiveJumpBoostUntil and not Config.FlyMode then
        pcall(function()
            local curVel = root.AssemblyLinearVelocity
            if curVel.Y < ActiveJumpTargetVel * 0.92 then
                root.AssemblyLinearVelocity = Vector3.new(curVel.X, ActiveJumpTargetVel, curVel.Z)
            end
            root.CFrame = root.CFrame + Vector3.new(0, ActiveJumpTargetVel * 0.28 * clampedDt, 0)
        end)
    end

    -- 2. Guaranteed Cross-Map WalkSpeed
    if Config.SpeedBoost and (not hum or not hum.SeatPart) and not Config.FlyMode then
        if hum then
            pcall(function() hum.WalkSpeed = Config.WalkSpeed end)
        end

        local moveDir = GetActiveMoveDirection(hum)
        if moveDir.Magnitude > 0.02 then
            local currentWalkProp = (hum and hum.WalkSpeed) or 16
            local isWarpMode = (Config.SpeedMethod == "วาร์ปสเต็ป (ทะลุล็อค)")

            local extraSpeed = 0
            if isWarpMode or currentWalkProp < (Config.WalkSpeed - 1) then
                extraSpeed = math.max(4, Config.WalkSpeed - 14)
            else
                extraSpeed = math.max(0, (Config.WalkSpeed - 16) * 0.55)
            end

            if extraSpeed > 0 then
                local stepVec = moveDir * (extraSpeed * clampedDt)
                local canStep = true

                if not Config.Noclip then
                    MoveRayParams.FilterDescendantsInstances = {char, Camera}
                    local hit = Workspace:Raycast(root.Position, moveDir * (stepVec.Magnitude + 1.6), MoveRayParams)
                    if hit and hit.Instance and hit.Instance.CanCollide then
                        canStep = false
                    end
                end

                if canStep then
                    root.CFrame = root.CFrame + stepVec
                end
            end

            if not isWarpMode and tick() >= ActiveJumpBoostUntil then
                pcall(function()
                    local curVel = root.AssemblyLinearVelocity
                    local targetXZ = moveDir * Config.WalkSpeed
                    root.AssemblyLinearVelocity = Vector3.new(
                        curVel.X + (targetXZ.X - curVel.X) * 0.55,
                        curVel.Y,
                        curVel.Z + (targetXZ.Z - curVel.Z) * 0.55
                    )
                end)
            end
        end
    end

    -- 3. HighJump Property Enforcement
    if Config.HighJump and hum then
        pcall(function()
            hum.UseJumpPower = true
            hum.JumpPower = Config.JumpPower
        end)
    end
end)

-- Physics Stepped Loop for Noclip & FullBright
TrackConnection(RunService.Stepped:Connect(function()
    if Config.Noclip then
        local char = LocalPlayer.Character or MyCachedModel
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end

    if Config.FullBright then
        Lighting.Ambient = Color3.fromRGB(190, 190, 190)
        Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190)
        Lighting.Brightness = 2.2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 9e9
    end
end))

-- Dynamic Active ESP Color Resolver
local function GetActiveESPColor(entity)
    if Config.ESPRainbow then
        local hue = (tick() * 0.28) % 1
        return Color3.fromHSV(hue, 0.85, 1)
    elseif entity and entity.IsNPC then
        return Color3.fromRGB(255, 80, 80)
    elseif Config.ESPUseTeamColor and entity and entity.TeamColor then
        return entity.TeamColor
    end
    return Config.ESPColor
end

-- Cosmetics: Character Aura & Neon Weapon Updater
UpdateCharacterAura = function()
    local _, _, root = GetLocalAnatomy()
    if not root then return end
    local existingLight = root:FindFirstChild("ProScriptAuraLight")
    local existingSpark = root:FindFirstChild("ProScriptAuraSpark")
    local activeCol = GetActiveESPColor(nil)

    if Config.CharacterAura then
        if not existingLight then
            existingLight = Instance.new("PointLight")
            existingLight.Name = "ProScriptAuraLight"
            existingLight.Brightness = 3.5
            existingLight.Range = 16
            existingLight.Parent = root
        end
        if not existingSpark then
            existingSpark = Instance.new("Sparkles")
            existingSpark.Name = "ProScriptAuraSpark"
            existingSpark.Parent = root
        end
        existingLight.Color = activeCol
        existingSpark.SparkleColor = activeCol
    else
        if existingLight then existingLight:Destroy() end
        if existingSpark then existingSpark:Destroy() end
    end
end

ApplyNeonWeapon = function()
    if not Config.NeonWeapon then return end
    local char = LocalPlayer.Character or MyCachedModel
    local activeCol = GetActiveESPColor(nil)

    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") or child:IsA("Model") then
                for _, part in ipairs(child:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Material = Enum.Material.Neon
                        part.Color = activeCol
                    end
                end
            end
        end
    end

    local tpsWeapons = Workspace:FindFirstChild("TpsWeapons") or Workspace:FindFirstChild("WarZClientWeaponVisuals")
    if tpsWeapons then
        local myWep = tpsWeapons:FindFirstChild(LocalPlayer.Name)
        if myWep then
            for _, part in ipairs(myWep:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Material = Enum.Material.Neon
                    part.Color = activeCol
                end
            end
        end
    end
end

TrackConnection(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    SyncCharacterMovement()
    UpdateCharacterAura()
    BindMobileJumpButtons()
end))

-- ==========================================
-- UNIVERSAL ESP SCANNER (ALL MAPS & CUSTOM RIGS)
-- ==========================================
local IsSingleTeamServer = false
local function UpdateServerTeamMode()
    local plrs = Players:GetPlayers()
    if #plrs <= 1 or not LocalPlayer.Team then
        IsSingleTeamServer = true
        return
    end
    local sameTeamCount = 0
    for _, p in ipairs(plrs) do
        if p.Team == LocalPlayer.Team then
            sameTeamCount = sameTeamCount + 1
        end
    end
    IsSingleTeamServer = (sameTeamCount / #plrs) >= 0.85
end

local function IsPlayerEnemy(plr, charModel)
    if not plr or plr == LocalPlayer then return false end
    if not Config.ESPTeamCheck or IsSingleTeamServer then
        return true
    end
    if plr.Team ~= nil and LocalPlayer.Team ~= nil then
        return plr.Team ~= LocalPlayer.Team
    end
    if plr.TeamColor ~= nil and LocalPlayer.TeamColor ~= nil and not plr.Neutral and not LocalPlayer.Neutral then
        return plr.TeamColor ~= LocalPlayer.TeamColor
    end
    local myTeamAttr = LocalPlayer:GetAttribute("Team") or (LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Team"))
    local theirTeamAttr = plr:GetAttribute("Team") or (charModel and charModel:GetAttribute("Team"))
    if myTeamAttr ~= nil and theirTeamAttr ~= nil then
        return myTeamAttr ~= theirTeamAttr
    end
    return true
end

local function IsModelAlive(model, hum)
    if not model or not model.Parent then return false end
    if hum then
        return hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead
    end
    local hpAttr = model:GetAttribute("Health") or model:GetAttribute("HP")
    if type(hpAttr) == "number" then
        return hpAttr > 0
    end
    local hpVal = model:FindFirstChild("Health") or model:FindFirstChild("HP")
    if hpVal and (hpVal:IsA("NumberValue") or hpVal:IsA("IntValue")) then
        return hpVal.Value > 0
    end
    return true
end

local function ResolveEquippedWeapon(plr, model)
    if not model then return nil end
    local tool = model:FindFirstChildOfClass("Tool")
    if tool then return tool.Name end

    local wepAttr = model:GetAttribute("EquippedWeapon") or model:GetAttribute("Weapon") or model:GetAttribute("CurrentWeapon") or (plr and plr:GetAttribute("EquippedWeapon"))
    if type(wepAttr) == "string" and #wepAttr > 0 then
        return wepAttr
    end

    local tpsFolder = Workspace:FindFirstChild("TpsWeapons")
    if tpsFolder and plr then
        local wepObj = tpsFolder:FindFirstChild(plr.Name)
        if wepObj then
            local subModel = wepObj:FindFirstChildOfClass("Model")
            return (subModel and subModel.Name) or wepObj.Name
        end
    end

    return nil
end

local function GetObjectWorldPosition(obj, cachedPart)
    if cachedPart and cachedPart.Parent then
        return cachedPart.Position
    end
    if not obj or not obj.Parent then return nil end
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") then
        local ok, pivot = pcall(function() return obj:GetPivot() end)
        if ok and pivot then
            return pivot.Position
        end
    end
    local anyPart = obj:FindFirstChildWhichIsA("BasePart", true)
    return anyPart and anyPart.Position or nil
end

local ActiveEntities = {}
local DroppedItemEntries = {}
local ExtraObjectEntries = {}

-- Background Scanner (Runs every 0.25s off-RenderStepped for 0 FPS lag)
task.spawn(function()
    while ScreenGui.Parent do
        UpdateServerTeamMode()
        local myChar, _, _ = GetLocalAnatomy()

        if Config.CharacterAura and Config.ESPRainbow then
            UpdateCharacterAura()
        end
        if Config.NeonWeapon then
            pcall(ApplyNeonWeapon)
        end

        local newEntities = {}
        local newItems = {}
        local newExtras = {}
        local claimedModels = {}

        if myChar then
            claimedModels[myChar] = true
        end
        if LocalPlayer.Character then
            claimedModels[LocalPlayer.Character] = true
        end

        -- 1. Scan All Players across Standard & Custom Folders
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                if not char or not char.Parent then
                    local wsModel = Workspace:FindFirstChild(plr.Name) or Workspace:FindFirstChild(plr.DisplayName)
                    if wsModel and (wsModel:IsA("Model") or wsModel:IsA("BasePart")) then
                        char = wsModel
                    end
                end
                if not char or not char.Parent then
                    for _, fName in ipairs(UniversalPlayerFolders) do
                        local folder = Workspace:FindFirstChild(fName)
                        if folder then
                            local found = folder:FindFirstChild(plr.Name) or folder:FindFirstChild(tostring(plr.UserId))
                            if found then
                                char = found
                                break
                            end
                        end
                    end
                end

                if char and char.Parent and not claimedModels[char] then
                    local root, head, torso, hum = ResolveModelAnatomy(char)
                    if IsModelAlive(char, hum) then
                        claimedModels[char] = true
                        newEntities[char] = {
                            Model = char,
                            Player = plr,
                            Name = plr.DisplayName or plr.Name,
                            IsNPC = false,
                            IsEnemy = IsPlayerEnemy(plr, char),
                            Root = root,
                            Head = head,
                            Torso = torso,
                            Humanoid = hum,
                            Weapon = ResolveEquippedWeapon(plr, char),
                            TeamColor = plr.TeamColor and plr.TeamColor.Color or nil
                        }
                    end
                end
            end
        end

        -- 2. Scan Zombies / Bots / Monsters (Clean Thai Labels Without Emoji Boxes)
        if Config.ESPMaster and Config.ESPZombies then
            local zombieFolders = {"BloxZZombies", "WZ_NPCs", "Zombies", "Enemies", "Mobs", "NPCs", "Monsters", "Bots"}
            for _, fName in ipairs(zombieFolders) do
                local folder = Workspace:FindFirstChild(fName)
                if folder then
                    for _, zObj in ipairs(folder:GetChildren()) do
                        if (zObj:IsA("Model") or zObj:IsA("BasePart")) and not claimedModels[zObj] then
                            local root, head, torso, hum = ResolveModelAnatomy(zObj)
                            if IsModelAlive(zObj, hum) then
                                claimedModels[zObj] = true
                                local cleanName = string.gsub(zObj.Name, "_rc%d+:[%w%-]+:%d+", "")
                                newEntities[zObj] = {
                                    Model = zObj,
                                    Player = nil,
                                    Name = "ซอมบี้: " .. cleanName,
                                    IsNPC = true,
                                    IsEnemy = true,
                                    Root = root,
                                    Head = head,
                                    Torso = torso,
                                    Humanoid = hum,
                                    Weapon = nil,
                                    TeamColor = nil
                                }
                            end
                        end
                    end
                end
            end

            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("Model") and not claimedModels[obj] and not Players:GetPlayerFromCharacter(obj) then
                    local isZombieName = string.find(obj.Name, "Zombie") or string.find(obj.Name, "Boss") or string.find(obj.Name, "NPC")
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    if isZombieName or (hum and hum.Health > 0) then
                        local root, head, torso, resolvedHum = ResolveModelAnatomy(obj)
                        if IsModelAlive(obj, resolvedHum) then
                            claimedModels[obj] = true
                            local cleanName = string.gsub(obj.Name, "_rc%d+:[%w%-]+:%d+", "")
                            newEntities[obj] = {
                                Model = obj,
                                Player = nil,
                                Name = "บอท: " .. cleanName,
                                IsNPC = true,
                                IsEnemy = true,
                                Root = root,
                                Head = head,
                                Torso = torso,
                                Humanoid = resolvedHum,
                                Weapon = nil,
                                TeamColor = nil
                            }
                        end
                    end
                end
            end
        end

        -- 3. Scan Dropped Items / Crates / Lockboxes
        if Config.ESPMaster and Config.ESPItems then
            local lootFolderNames = {
                "WarZWorldDrops",
                "WarZSummonCrates",
                "WarZPendingDrops_" .. tostring(LocalPlayer.UserId),
                "WarzLoot",
                "DroppedItems",
                "BloxZWorldLoot",
                "WarZLockboxes",
                "Drops",
                "Items",
                "Loot"
            }

            for _, fName in ipairs(lootFolderNames) do
                local lFolder = Workspace:FindFirstChild(fName)
                if lFolder then
                    for _, itemObj in ipairs(lFolder:GetChildren()) do
                        if itemObj:IsA("Model") or itemObj:IsA("BasePart") or itemObj:IsA("Tool") then
                            local part = itemObj:IsA("BasePart") and itemObj or itemObj:FindFirstChild("Handle") or itemObj:FindFirstChildWhichIsA("BasePart", true)
                            local itemName = itemObj:GetAttribute("ItemName") or itemObj:GetAttribute("Name") or itemObj:GetAttribute("ItemId") or itemObj.Name
                            newItems[itemObj] = {
                                Model = itemObj,
                                Part = part,
                                Name = tostring(itemName)
                            }
                        end
                    end
                end
            end

            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("Tool") and not newItems[obj] then
                    local part = obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart", true)
                    newItems[obj] = {Model = obj, Part = part, Name = obj.Name}
                end
            end
        end

        -- 4. Scan Map Extras (Vehicles, LogoutBodies, Shields)
        if Config.ESPMaster and Config.ESPExtras then
            local vehicleFolder = Workspace:FindFirstChild("WarZVehicles") or Workspace:FindFirstChild("Vehicles")
            if vehicleFolder then
                for _, vObj in ipairs(vehicleFolder:GetChildren()) do
                    if vObj:IsA("Model") or vObj:IsA("BasePart") then
                        local part = vObj:IsA("BasePart") and vObj or vObj:FindFirstChildWhichIsA("BasePart", true)
                        newExtras[vObj] = {
                            Model = vObj,
                            Part = part,
                            Name = "รถ: " .. vObj.Name,
                            Color = Color3.fromRGB(65, 205, 255)
                        }
                    end
                end
            end

            local logoutFolder = Workspace:FindFirstChild("LogoutBodies")
            if logoutFolder then
                for _, bObj in ipairs(logoutFolder:GetChildren()) do
                    if bObj:IsA("Model") or bObj:IsA("BasePart") then
                        local part = bObj:IsA("BasePart") and bObj or bObj:FindFirstChildWhichIsA("BasePart", true)
                        newExtras[bObj] = {
                            Model = bObj,
                            Part = part,
                            Name = "ร่างสลบ: " .. bObj.Name,
                            Color = Color3.fromRGB(255, 145, 55)
                        }
                    end
                end
            end

            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj.Name == "PlacedShield" and (obj:IsA("Model") or obj:IsA("BasePart")) then
                    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                    newExtras[obj] = {
                        Model = obj,
                        Part = part,
                        Name = "โล่ตั้งพื้น",
                        Color = Color3.fromRGB(185, 130, 255)
                    }
                end
            end
        end

        ActiveEntities = newEntities
        DroppedItemEntries = newItems
        ExtraObjectEntries = newExtras
        task.wait(0.25)
    end
end)

-- ==========================================
-- UNIVERSAL 2D OVERLAY ESP RENDERER
-- ==========================================
local ESPContainer = Instance.new("Frame")
ESPContainer.Name = "ProScriptESPContainer"
ESPContainer.Parent = ScreenGui
ESPContainer.BackgroundTransparency = 1
ESPContainer.Size = UDim2.new(1, 0, 1, 0)
ESPContainer.ZIndex = 1

local EntityESPCache = {}
local TagESPCache = {}

local function CreateEntityESPUI(modelKey)
    local holder = Instance.new("Frame")
    holder.Name = "ESP_Entry"
    holder.Parent = ESPContainer
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(1, 0, 1, 0)
    holder.Visible = false

    local box = Instance.new("Frame")
    box.Name = "Box"
    box.Parent = holder
    box.BackgroundColor3 = Config.ESPColor
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Config.ESPColor
    boxStroke.Thickness = Config.ESPThickness
    boxStroke.Parent = box

    local corners = {}
    local cornerSpecs = {
        {Anchor = Vector2.new(0, 0), Pos = UDim2.new(0, 0, 0, 0), IsHoriz = true},
        {Anchor = Vector2.new(0, 0), Pos = UDim2.new(0, 0, 0, 0), IsHoriz = false},
        {Anchor = Vector2.new(1, 0), Pos = UDim2.new(1, 0, 0, 0), IsHoriz = true},
        {Anchor = Vector2.new(1, 0), Pos = UDim2.new(1, 0, 0, 0), IsHoriz = false},
        {Anchor = Vector2.new(0, 1), Pos = UDim2.new(0, 0, 1, 0), IsHoriz = true},
        {Anchor = Vector2.new(0, 1), Pos = UDim2.new(0, 0, 1, 0), IsHoriz = false},
        {Anchor = Vector2.new(1, 1), Pos = UDim2.new(1, 0, 1, 0), IsHoriz = true},
        {Anchor = Vector2.new(1, 1), Pos = UDim2.new(1, 0, 1, 0), IsHoriz = false}
    }

    for _, spec in ipairs(cornerSpecs) do
        local line = Instance.new("Frame")
        line.Parent = box
        line.AnchorPoint = spec.Anchor
        line.Position = spec.Pos
        line.BackgroundColor3 = Config.ESPColor
        line.BorderSizePixel = 0
        line.Visible = false
        table.insert(corners, {Frame = line, IsHoriz = spec.IsHoriz})
    end

    local hbBg = Instance.new("Frame")
    hbBg.Name = "HealthBG"
    hbBg.Parent = box
    hbBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    hbBg.BorderSizePixel = 0
    hbBg.Position = UDim2.new(0, -7, 0, 0)
    hbBg.Size = UDim2.new(0, 3, 1, 0)
    hbBg.Visible = false

    local hbFill = Instance.new("Frame")
    hbFill.Name = "Fill"
    hbFill.Parent = hbBg
    hbFill.BackgroundColor3 = Theme.AccentLight
    hbFill.BorderSizePixel = 0
    hbFill.AnchorPoint = Vector2.new(0, 1)
    hbFill.Position = UDim2.new(0, 0, 1, 0)
    hbFill.Size = UDim2.new(1, 0, 1, 0)

    local hpText = Instance.new("TextLabel")
    hpText.Name = "HPText"
    hpText.Parent = hbBg
    hpText.BackgroundTransparency = 1
    hpText.Position = UDim2.new(0, -34, 0, -4)
    hpText.Size = UDim2.new(0, 30, 0, 12)
    hpText.Font = Typography.FontBold
    hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
    hpText.TextStrokeTransparency = 0.2
    hpText.TextSize = 10
    hpText.TextXAlignment = Enum.TextXAlignment.Right
    hpText.Text = "100%"

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Name = "NameDist"
    nameLbl.Parent = box
    nameLbl.BackgroundTransparency = 1
    nameLbl.Position = UDim2.new(0.5, -110, 0, -19)
    nameLbl.Size = UDim2.new(0, 220, 0, 16)
    nameLbl.Font = Typography.FontBold
    nameLbl.TextColor3 = Theme.TextPrimary
    nameLbl.TextStrokeTransparency = 0.15
    nameLbl.TextSize = 12
    nameLbl.Visible = false

    local wepLbl = Instance.new("TextLabel")
    wepLbl.Name = "WeaponLbl"
    wepLbl.Parent = box
    wepLbl.BackgroundTransparency = 1
    wepLbl.Position = UDim2.new(0.5, -100, 1, 3)
    wepLbl.Size = UDim2.new(0, 200, 0, 15)
    wepLbl.Font = Typography.FontMedium
    wepLbl.TextColor3 = Color3.fromRGB(230, 240, 235)
    wepLbl.TextStrokeTransparency = 0.2
    wepLbl.TextSize = 11
    wepLbl.Visible = false

    local headDot = Instance.new("Frame")
    headDot.Name = "HeadDot"
    headDot.Parent = holder
    headDot.AnchorPoint = Vector2.new(0.5, 0.5)
    headDot.BackgroundColor3 = Config.ESPColor
    headDot.BackgroundTransparency = 0.2
    headDot.Size = UDim2.new(0, 8, 0, 8)
    headDot.Visible = false

    local headDotCorner = Instance.new("UICorner")
    headDotCorner.CornerRadius = UDim.new(1, 0)
    headDotCorner.Parent = headDot

    local headDotStroke = Instance.new("UIStroke")
    headDotStroke.Color = Color3.fromRGB(255, 255, 255)
    headDotStroke.Thickness = 1
    headDotStroke.Parent = headDot

    local tracer = Instance.new("Frame")
    tracer.Name = "Tracer"
    tracer.Parent = holder
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.BackgroundColor3 = Config.ESPColor
    tracer.BorderSizePixel = 0
    tracer.Visible = false

    EntityESPCache[modelKey] = {
        Holder = holder,
        Box = box,
        BoxStroke = boxStroke,
        Corners = corners,
        HealthBG = hbBg,
        HealthFill = hbFill,
        HPText = hpText,
        NameLbl = nameLbl,
        WeaponLbl = wepLbl,
        HeadDot = headDot,
        Tracer = tracer
    }
end

local function CreateFloatingTagUI(objKey)
    local tag = Instance.new("TextLabel")
    tag.Name = "FloatingTagESP"
    tag.Parent = ESPContainer
    tag.AnchorPoint = Vector2.new(0.5, 0.5)
    tag.BackgroundTransparency = 1
    tag.Size = UDim2.new(0, 200, 0, 16)
    tag.Font = Typography.FontBold
    tag.TextColor3 = Color3.fromRGB(255, 215, 55)
    tag.TextStrokeTransparency = 0.15
    tag.TextSize = 12
    tag.Visible = false
    TagESPCache[objKey] = tag
end

-- Main RenderStepped Loop (Fast Slide, Fast Car, Fly & 2D ESP)
local FlyBV, FlyBG = nil, nil

TrackConnection(RunService.RenderStepped:Connect(function()
    if not ScreenGui.Parent then return end
    Camera = Workspace.CurrentCamera
    if not Camera then return end

    local myChar, myHum, myHrp = GetLocalAnatomy()

    -- 1. Fast Slide, Fast Car & Cross-Platform Fly
    if myChar and myHrp then
        if Config.FastSlide and (not myHum or not myHum.SeatPart) then
            local moveDir = GetActiveMoveDirection(myHum)
            if moveDir.Magnitude > 0.02 then
                local isSliding = isSlideKeyHeld
                    or (myHum and myHum.HipHeight < 1.2 and myHum.RigType == Enum.HumanoidRigType.R15)
                    or myHrp:FindFirstChildOfClass("BodyVelocity")
                    or myHrp:FindFirstChildOfClass("LinearVelocity")
                if isSliding then
                    local slideVec = moveDir * Config.SlideSpeed
                    myHrp.AssemblyLinearVelocity = Vector3.new(slideVec.X, myHrp.AssemblyLinearVelocity.Y, slideVec.Z)
                end
            end
        end

        local seat = myHum and myHum.SeatPart
        if Config.FastCar and seat and seat:IsA("BasePart") then
            if seat:IsA("VehicleSeat") then
                seat.MaxSpeed = Config.CarSpeed
                seat.Torque = math.max(seat.Torque, 55000)
                if math.abs(seat.ThrottleFloat) > 0.05 then
                    local forwardDir = seat.CFrame.LookVector * seat.ThrottleFloat
                    local currentVel = seat.AssemblyLinearVelocity
                    local targetVel = forwardDir * Config.CarSpeed
                    seat.AssemblyLinearVelocity = currentVel:Lerp(Vector3.new(targetVel.X, currentVel.Y, targetVel.Z), 0.18)
                end
            else
                local moveDir = GetActiveMoveDirection(myHum)
                if moveDir.Magnitude > 0.02 then
                    local moveVel = moveDir * Config.CarSpeed
                    seat.AssemblyLinearVelocity = seat.AssemblyLinearVelocity:Lerp(Vector3.new(moveVel.X, seat.AssemblyLinearVelocity.Y, moveVel.Z), 0.18)
                end
            end
        end

        if Config.FlyMode then
            if not FlyBV or FlyBV.Parent ~= myHrp then
                FlyBV = Instance.new("BodyVelocity")
                FlyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                FlyBV.Velocity = Vector3.zero
                FlyBV.Parent = myHrp
            end
            if not FlyBG or FlyBG.Parent ~= myHrp then
                FlyBG = Instance.new("BodyGyro")
                FlyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                FlyBG.P = 9e4
                FlyBG.Parent = myHrp
            end
            if myHum then myHum.PlatformStand = true end
            FlyBG.CFrame = Camera.CFrame

            local moveDir = GetActiveMoveDirection(myHum)
            local verticalBoost = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                verticalBoost = 1
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then
                verticalBoost = -1
            end

            if moveDir.Magnitude > 0.02 or verticalBoost ~= 0 then
                local camLook = Camera.CFrame.LookVector
                local camRight = Camera.CFrame.RightVector
                local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
                local forwardDot = (flatLook.Magnitude > 0.01) and moveDir:Dot(flatLook.Unit) or 0
                local rightDot = moveDir:Dot(Vector3.new(camRight.X, 0, camRight.Z).Unit)
                local flyDir = (camLook * forwardDot + camRight * rightDot) + Vector3.new(0, verticalBoost, 0)
                if flyDir.Magnitude > 0.01 then
                    FlyBV.Velocity = flyDir.Unit * Config.FlySpeed
                else
                    FlyBV.Velocity = moveDir.Unit * Config.FlySpeed
                end
            else
                FlyBV.Velocity = Vector3.zero
            end
        else
            if FlyBV then FlyBV:Destroy() FlyBV = nil end
            if FlyBG then FlyBG:Destroy() FlyBG = nil end
            if myHum and myHum.PlatformStand then
                myHum.PlatformStand = false
            end
        end
    end

    -- 2. Universal Real-Time 2D ESP Render (Clean Parentheses Format - No Tofu Boxes)
    local vpSize = Camera.ViewportSize
    local visitedModels = {}
    local refOrigin = (myHrp and myHrp.Parent and myHrp.Position) or Camera.CFrame.Position

    for model, entity in pairs(ActiveEntities) do
        if model and model.Parent then
            visitedModels[model] = true
            if not EntityESPCache[model] then
                CreateEntityESPUI(model)
            end
            local ui = EntityESPCache[model]
            local hum = entity.Humanoid
            local shouldRenderEntity = entity.IsEnemy and ((not entity.IsNPC) or Config.ESPZombies)
            local worldPos = GetObjectWorldPosition(model, entity.Root)

            if Config.ESPMaster and shouldRenderEntity and worldPos and IsModelAlive(model, hum) then
                local worldDist = (worldPos - refOrigin).Magnitude
                local meters = math.floor(worldDist * 0.28)
                local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)

                if onScreen and screenPos.Z > 0.5 and meters <= Config.ESPMaxDist then
                    local activeColor = GetActiveESPColor(entity)
                    local thickness = Config.ESPThickness

                    ui.Holder.Visible = true
                    local scaleFactor = 1 / (screenPos.Z * math.tan(math.rad(Camera.FieldOfView * 0.5)) * 2) * 1000
                    local boxH = math.clamp(scaleFactor * 4.8, 18, 360)
                    local boxW = math.clamp(boxH * 0.62, 12, 240)

                    ui.Box.Position = UDim2.new(0, screenPos.X - boxW / 2, 0, screenPos.Y - boxH / 2)
                    ui.Box.Size = UDim2.new(0, boxW, 0, boxH)
                    ui.Box.Visible = Config.ESPBox or Config.ESPHealth or Config.ESPNameDist or Config.ESPWeapon

                    if Config.ESPBox and Config.ESPBoxFill then
                        ui.Box.BackgroundColor3 = activeColor
                        ui.Box.BackgroundTransparency = 0.84
                    else
                        ui.Box.BackgroundTransparency = 1
                    end

                    local isCornerStyle = (Config.ESPBoxStyle == "กรอบมุม")
                    ui.BoxStroke.Enabled = Config.ESPBox and not isCornerStyle
                    ui.BoxStroke.Color = activeColor
                    ui.BoxStroke.Thickness = thickness

                    local cornerLenW = math.clamp(math.floor(boxW * 0.26), 4, 28)
                    local cornerLenH = math.clamp(math.floor(boxH * 0.22), 4, 28)
                    for _, c in ipairs(ui.Corners) do
                        c.Frame.Visible = Config.ESPBox and isCornerStyle
                        if c.Frame.Visible then
                            c.Frame.BackgroundColor3 = activeColor
                            if c.IsHoriz then
                                c.Frame.Size = UDim2.new(0, cornerLenW, 0, thickness)
                            else
                                c.Frame.Size = UDim2.new(0, thickness, 0, cornerLenH)
                            end
                        end
                    end

                    if Config.ESPHealth then
                        ui.HealthBG.Visible = true
                        local curHp = (hum and hum.Health) or (model:GetAttribute("Health")) or (model:GetAttribute("HP")) or 100
                        local maxHp = (hum and hum.MaxHealth) or (model:GetAttribute("MaxHealth")) or 100
                        local hpRatio = math.clamp(curHp / math.max(maxHp, 1), 0, 1)
                        ui.HealthFill.Size = UDim2.new(1, 0, hpRatio, 0)
                        ui.HealthFill.BackgroundColor3 = Color3.fromRGB(255 * (1 - hpRatio), 255 * hpRatio, 65)
                        ui.HPText.Text = tostring(math.floor(hpRatio * 100)) .. "%"
                    else
                        ui.HealthBG.Visible = false
                    end

                    if Config.ESPNameDist then
                        ui.NameLbl.Visible = true
                        ui.NameLbl.TextColor3 = activeColor
                        ui.NameLbl.Text = string.format("%s (%d ม.)", entity.Name, meters)
                    else
                        ui.NameLbl.Visible = false
                    end

                    if Config.ESPWeapon and entity.Weapon then
                        ui.WeaponLbl.Visible = true
                        ui.WeaponLbl.Text = tostring(entity.Weapon)
                    else
                        ui.WeaponLbl.Visible = false
                    end

                    local headPos3D = GetObjectWorldPosition(entity.Head, entity.Head) or (worldPos + Vector3.new(0, 1.8, 0))
                    if Config.ESPHeadDot and headPos3D then
                        local headPos, headOnScreen = Camera:WorldToViewportPoint(headPos3D)
                        if headOnScreen and headPos.Z > 0.5 then
                            local dotSize = math.clamp(boxW * 0.22, 5, 16)
                            ui.HeadDot.Visible = true
                            ui.HeadDot.BackgroundColor3 = activeColor
                            ui.HeadDot.Size = UDim2.new(0, dotSize, 0, dotSize)
                            ui.HeadDot.Position = UDim2.new(0, headPos.X, 0, headPos.Y)
                        else
                            ui.HeadDot.Visible = false
                        end
                    else
                        ui.HeadDot.Visible = false
                    end

                    if Config.ESPTracer then
                        local startY = (Config.ESPTracerOrigin == "กลางจอ") and (vpSize.Y / 2) or (vpSize.Y - 12)
                        local startPt = Vector2.new(vpSize.X / 2, startY)
                        local endPt = Vector2.new(screenPos.X, screenPos.Y + boxH / 2)
                        local diff = endPt - startPt
                        local dist = diff.Magnitude
                        local center = (startPt + endPt) / 2
                        local angle = math.deg(math.atan2(diff.Y, diff.X))

                        ui.Tracer.Visible = true
                        ui.Tracer.BackgroundColor3 = activeColor
                        ui.Tracer.Position = UDim2.new(0, center.X, 0, center.Y)
                        ui.Tracer.Size = UDim2.new(0, dist, 0, thickness)
                        ui.Tracer.Rotation = angle
                    else
                        ui.Tracer.Visible = false
                    end
                else
                    ui.Holder.Visible = false
                end
            else
                ui.Holder.Visible = false
            end
        end
    end

    for modelKey, ui in pairs(EntityESPCache) do
        if not visitedModels[modelKey] or not modelKey.Parent then
            if ui.Holder then ui.Holder:Destroy() end
            EntityESPCache[modelKey] = nil
        end
    end

    -- 3. Dropped Items & Map Extras 2D Tags (Clean Text Without Missing Emoji Boxes)
    local visitedTags = {}

    if Config.ESPMaster and Config.ESPItems then
        for itemObj, itemData in pairs(DroppedItemEntries) do
            if itemObj and itemObj.Parent then
                local pos = GetObjectWorldPosition(itemObj, itemData.Part)
                if pos then
                    visitedTags[itemObj] = true
                    if not TagESPCache[itemObj] then
                        CreateFloatingTagUI(itemObj)
                    end
                    local tag = TagESPCache[itemObj]
                    local distMeters = math.floor((pos - refOrigin).Magnitude * 0.28)
                    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
                    if onScreen and screenPos.Z > 0.5 and distMeters <= Config.ESPMaxDist then
                        tag.Visible = true
                        tag.TextColor3 = Color3.fromRGB(255, 215, 55)
                        tag.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
                        tag.Text = string.format("ของดรอป: %s (%d ม.)", itemData.Name, distMeters)
                    else
                        tag.Visible = false
                    end
                end
            end
        end
    end

    if Config.ESPMaster and Config.ESPExtras then
        for extraObj, extraData in pairs(ExtraObjectEntries) do
            if extraObj and extraObj.Parent then
                local pos = GetObjectWorldPosition(extraObj, extraData.Part)
                if pos then
                    visitedTags[extraObj] = true
                    if not TagESPCache[extraObj] then
                        CreateFloatingTagUI(extraObj)
                    end
                    local tag = TagESPCache[extraObj]
                    local distMeters = math.floor((pos - refOrigin).Magnitude * 0.28)
                    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
                    if onScreen and screenPos.Z > 0.5 and distMeters <= Config.ESPMaxDist then
                        tag.Visible = true
                        tag.TextColor3 = extraData.Color
                        tag.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
                        tag.Text = string.format("%s (%d ม.)", extraData.Name, distMeters)
                    else
                        tag.Visible = false
                    end
                end
            end
        end
    end

    for objKey, tag in pairs(TagESPCache) do
        if not visitedTags[objKey] or not objKey.Parent then
            tag:Destroy()
            TagESPCache[objKey] = nil
        end
    end
end))

-- Smart Highlight Pool Manager (Respects Roblox's 31-Highlight Engine Limit)
local ActiveHighlights = {}

local function SetModelHighlight(targetModel, color, enabled)
    if not targetModel or not targetModel.Parent then return end
    local hl = targetModel:FindFirstChild("ProScriptHL")
    if enabled then
        if not hl then
            hl = Instance.new("Highlight")
            hl.Name = "ProScriptHL"
            hl.FillTransparency = 0.62
            hl.OutlineTransparency = 0.08
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = targetModel
        end
        hl.FillColor = color
        hl.OutlineColor = color
        hl.Enabled = true
        ActiveHighlights[targetModel] = hl
    else
        if hl then
            hl:Destroy()
        end
        ActiveHighlights[targetModel] = nil
    end
end

task.spawn(function()
    while ScreenGui.Parent do
        local candidates = {}
        local _, _, myHrp = GetLocalAnatomy()
        local refPos = (myHrp and myHrp.Parent and myHrp.Position) or (Camera and Camera.CFrame.Position) or Vector3.zero

        if Config.ESPMaster then
            for model, entity in pairs(ActiveEntities) do
                if model and model.Parent and entity.IsEnemy then
                    local wantChams = (not entity.IsNPC and Config.ESPChams) or (entity.IsNPC and Config.ESPZombies)
                    if wantChams then
                        local pos = GetObjectWorldPosition(model, entity.Root)
                        if pos then
                            table.insert(candidates, {
                                Model = model,
                                Color = GetActiveESPColor(entity),
                                Dist = (pos - refPos).Magnitude
                            })
                        end
                    end
                end
            end

            if Config.ESPItems then
                for itemObj, itemData in pairs(DroppedItemEntries) do
                    if itemObj and itemObj.Parent then
                        local pos = GetObjectWorldPosition(itemObj, itemData.Part)
                        if pos then
                            table.insert(candidates, {
                                Model = itemObj,
                                Color = Color3.fromRGB(255, 215, 0),
                                Dist = (pos - refPos).Magnitude
                            })
                        end
                    end
                end
            end

            if Config.ESPExtras then
                for extraObj, extraData in pairs(ExtraObjectEntries) do
                    if extraObj and extraObj.Parent then
                        local pos = GetObjectWorldPosition(extraObj, extraData.Part)
                        if pos then
                            table.insert(candidates, {
                                Model = extraObj,
                                Color = extraData.Color,
                                Dist = (pos - refPos).Magnitude
                            })
                        end
                    end
                end
            end
        end

        table.sort(candidates, function(a, b)
            return a.Dist < b.Dist
        end)

        local keepSet = {}
        local maxHighlights = math.min(#candidates, 28)
        for i = 1, maxHighlights do
            local entry = candidates[i]
            keepSet[entry.Model] = true
            SetModelHighlight(entry.Model, entry.Color, true)
        end

        for model, _ in pairs(ActiveHighlights) do
            if not keepSet[model] or not model.Parent then
                SetModelHighlight(model, Color3.new(1, 1, 1), false)
            end
        end

        task.wait(0.3)
    end
end)