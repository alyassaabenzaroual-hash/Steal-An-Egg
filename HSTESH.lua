--[[
    HSTESH v6 — Full Mobile Support Edition
    Repository: alyassaabenzaroual-hash / Zerowifly

    Mobile-Ready Features:
    - Activated() everywhere (touch + mouse + gamepad)
    - Responsive UI sizes (auto-detect touch-only devices)
    - Tap vs Drag detection for Clown button
    - Keyboard keybind disabled on mobile
    - Touch-optimized scrollbar + button spacing
]]

local HttpService       = game:GetService("HttpService")
local TeleportService   = game:GetService("TeleportService")
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local Stats             = game:GetService("Stats")
local VirtualUser       = game:GetService("VirtualUser")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local placeId   = game.PlaceId

-- ============================================================
-- 📱 DEVICE DETECTION
-- ============================================================
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local hasKeyboard = UserInputService.KeyboardEnabled

print(string.format("[HSTESH] Device: %s | Keyboard: %s",
    isMobile and "📱 Mobile" or "💻 Desktop",
    tostring(hasKeyboard)))

-- 🔗 GitHub Raw Direct Link
local SCRIPT_URL = "https://raw.githubusercontent.com/alyassaabenzaroual-hash/Steal-An-Egg/main/HSTESH.lua"

-- Persistent States via Environment
local genv = (getgenv and getgenv()) or _G
if genv.HSTESH_AutoJoin == nil then genv.HSTESH_AutoJoin = false end
if genv.HSTESH_RetryCount == nil then genv.HSTESH_RetryCount = 0 end

-- Config
local MAX_PLAYERS_ALLOWED = 4

-- ============================================================
-- PERSISTENCE
-- ============================================================
local queueFn = queue_on_teleport
    or queueonteleport
    or (syn and syn.queue_on_teleport)
    or (fluxus and fluxus.queue_on_teleport)

local function persistScript()
    if not queueFn then return end
    pcall(queueFn, string.format(
        'repeat task.wait() until game:IsLoaded() loadstring(game:HttpGet("%s"))()',
        SCRIPT_URL
    ))
end

-- ============================================================
-- ANTI-AFK
-- ============================================================
player.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(0.1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end)

-- ============================================================
-- THEME
-- ============================================================
local Theme = {
    Background  = Color3.fromRGB(16, 16, 21),
    Panel       = Color3.fromRGB(22, 22, 29),
    Row         = Color3.fromRGB(27, 27, 35),
    Accent      = Color3.fromRGB(224, 42, 42),
    AccentDark  = Color3.fromRGB(178, 28, 28),
    Green       = Color3.fromRGB(63, 181, 96),
    GreenDark   = Color3.fromRGB(46, 148, 76),
    Text        = Color3.fromRGB(245, 245, 248),
    SubText     = Color3.fromRGB(170, 170, 180),
}

local function corner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = inst
    return c
end

local function stroke(inst, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Accent
    s.Thickness = thickness or 1
    s.Parent = inst
    return s
end

local function tween(inst, props, time)
    TweenService:Create(inst, TweenInfo.new(time or 0.15, Enum.EasingStyle.Quad), props):Play()
end

-- ============================================================
-- ROOT CLEANUP & SETUP
-- ============================================================
local old = playerGui:FindFirstChild("HSTESH")
if old then old:Destroy() end
pcall(function()
    local core = game:GetService("CoreGui")
    if core:FindFirstChild("HSTESH") then
        core.HSTESH:Destroy()
    end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HSTESH"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    if gethui then
        screenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = game:GetService("CoreGui")
    else
        screenGui.Parent = playerGui
    end
end)

-- ============================================================
-- 📱 RESPONSIVE DIMENSIONS
-- ============================================================
local DIM = isMobile and {
    FrameW = 350, FrameH = 440,
    HeaderH = 58,
    TitleSize = 13,
    StatusSize = 11,
    PingSize = 11,
    BtnH = 44,
    BtnTextSize = 16,
    InputH = 44,
    InputTextSize = 13,
    RowH = 62,
    RowTextSize = 12,
    RowBadgeSize = 42,
    RowJoinW = 78,
    RowJoinH = 42,
    RowJoinTextSize = 12,
    ClownSize = 62,
    ActionH = 48,
} or {
    FrameW = 560, FrameH = 470,
    HeaderH = 64,
    TitleSize = 16,
    StatusSize = 13,
    PingSize = 13,
    BtnH = 40,
    BtnTextSize = 14,
    InputH = 40,
    InputTextSize = 14,
    RowH = 52,
    RowTextSize = 14,
    RowBadgeSize = 40,
    RowJoinW = 84,
    RowJoinH = 36,
    RowJoinTextSize = 13,
    ClownSize = 55,
    ActionH = 40,
}

-- ============================================================
-- MAIN FRAME
-- ============================================================
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, DIM.FrameW, 0, DIM.FrameH)
main.Position = UDim2.new(0.5, -DIM.FrameW/2, 0.5, -DIM.FrameH/2)
main.BackgroundColor3 = Theme.Background
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Visible = true
main.Parent = screenGui
corner(main, 12)
stroke(main, Theme.AccentDark, 1)

-- ============================================================
-- 🤡 CLOWN TOGGLE BUTTON (Tap vs Drag aware)
-- ============================================================
local clownButton = Instance.new("TextButton")
clownButton.Name = "ClownToggleButton"
clownButton.Size = UDim2.new(0, DIM.ClownSize, 0, DIM.ClownSize)
clownButton.Position = UDim2.new(0, 20, 0, 20)
clownButton.Text = "🤡"
clownButton.TextScaled = true
clownButton.BackgroundColor3 = Theme.Panel
clownButton.TextColor3 = Theme.Text
clownButton.Font = Enum.Font.GothamBold
clownButton.AutoButtonColor = true
clownButton.Parent = screenGui
corner(clownButton, 100)
stroke(clownButton, Theme.Accent, 2)

local function toggleUI()
    main.Visible = not main.Visible
end

local TAP_THRESHOLD = 10
local clownDragging = false
local clownDragStart, clownStartPos
local clownMoved = false

clownButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        clownDragging = true
        clownMoved = false
        clownDragStart = input.Position
        clownStartPos = clownButton.Position
    end
end)

clownButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        local wasDragging = clownDragging
        local moved = clownMoved
        clownDragging = false
        clownMoved = false

        if wasDragging and not moved then
            toggleUI()
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not clownDragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - clownDragStart
        if delta.Magnitude > TAP_THRESHOLD then
            clownMoved = true
        end
        if clownMoved then
            clownButton.Position = UDim2.new(
                clownStartPos.X.Scale, clownStartPos.X.Offset + delta.X,
                clownStartPos.Y.Scale, clownStartPos.Y.Offset + delta.Y
            )
        end
    end
end)

if hasKeyboard then
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
            toggleUI()
        end
    end)
end

-- ============================================================
-- HEADER
-- ============================================================
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, DIM.HeaderH)
header.BackgroundColor3 = Theme.Panel
header.BorderSizePixel = 0
header.Parent = main
corner(header, 12)

local headerMask = Instance.new("Frame")
headerMask.BackgroundColor3 = Theme.Panel
headerMask.BorderSizePixel = 0
headerMask.Size = UDim2.new(1, 0, 0, 12)
headerMask.Position = UDim2.new(0, 0, 1, -12)
headerMask.Parent = header

local icon = Instance.new("TextLabel")
icon.Size = UDim2.new(0, 40, 0, 40)
icon.Position = UDim2.new(0, 12, 0.5, -20)
icon.BackgroundColor3 = Theme.Accent
icon.Text = "H"
icon.Font = Enum.Font.GothamBold
icon.TextSize = 20
icon.TextColor3 = Theme.Text
icon.Parent = header
corner(icon, 10)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 60, 0, 8)
title.Size = UDim2.new(1, -200, 0, 20)
title.Font = Enum.Font.GothamBold
title.TextSize = DIM.TitleSize
title.TextColor3 = Theme.Accent
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextTruncate = Enum.TextTruncate.AtEnd
title.Text = isMobile and "HSTESH HOPPER" or "HSTESH SERVER HOPPER  [RightCtrl]"
title.Parent = header

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 60, 0, 28)
statusLabel.Size = UDim2.new(1, -200, 0, 18)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = DIM.StatusSize
statusLabel.TextColor3 = Theme.SubText
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Text = "Status: Idle"
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
statusLabel.Parent = header

local statsLabel = Instance.new("TextLabel")
statsLabel.BackgroundTransparency = 1
statsLabel.Position = UDim2.new(1, -160, 0, 8)
statsLabel.Size = UDim2.new(0, 110, 0, 18)
statsLabel.Font = Enum.Font.GothamBold
statsLabel.TextSize = DIM.PingSize
statsLabel.TextColor3 = Theme.SubText
statsLabel.TextXAlignment = Enum.TextXAlignment.Right
statsLabel.Text = "PING: -- ms"
statsLabel.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -42, 0, DIM.HeaderH/2 - 15)
closeBtn.BackgroundColor3 = Theme.Row
closeBtn.Text = "—"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = Theme.Text
closeBtn.AutoButtonColor = true
closeBtn.Parent = header
corner(closeBtn, 6)

closeBtn.Activated:Connect(function()
    main.Visible = false
end)

-- Header Drag Logic
do
    local draggingMain = false
    local mainDragStart, mainStartPos

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingMain = true
            mainDragStart = input.Position
            mainStartPos = main.Position
        end
    end)

    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingMain = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not draggingMain then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - mainDragStart
            main.Position = UDim2.new(
                mainStartPos.X.Scale, mainStartPos.X.Offset + delta.X,
                mainStartPos.Y.Scale, mainStartPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================
-- ACTION BUTTONS
-- ============================================================
local actionRow = Instance.new("Frame")
actionRow.BackgroundTransparency = 1
actionRow.Position = UDim2.new(0, 12, 0, DIM.HeaderH + 12)
actionRow.Size = UDim2.new(1, -24, 0, DIM.ActionH)
actionRow.Parent = main

local actionLayout = Instance.new("UIListLayout")
actionLayout.FillDirection = Enum.FillDirection.Horizontal
actionLayout.Padding = UDim.new(0, 8)
actionLayout.Parent = actionRow

local function makeActionButton(name, desktopText, mobileText)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0.25, -6, 1, 0)
    btn.BackgroundColor3 = Theme.Accent
    btn.Text = isMobile and mobileText or desktopText
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = isMobile and 22 or 14
    btn.TextColor3 = Theme.Text
    btn.AutoButtonColor = true
    btn.Parent = actionRow
    corner(btn, 8)

    if not isMobile then
        btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = Theme.AccentDark}) end)
        btn.MouseLeave:Connect(function()
            if not (name == "AutoJoin" and genv.HSTESH_AutoJoin) then
                tween(btn, {BackgroundColor3 = Theme.Accent})
            end
        end)
    end

    return btn
end

local copyIdBtn   = makeActionButton("CopyID", "Copy ID", "📋")
local refreshBtn  = makeActionButton("Refresh", "Refresh", "🔄")
local bestHopBtn  = makeActionButton("BestHop", "Best Hop", "⚡")
local autoJoinBtn = makeActionButton("AutoJoin", "Auto Join", "🤖")

if genv.HSTESH_AutoJoin then
    autoJoinBtn.BackgroundColor3 = Theme.GreenDark
end

-- ============================================================
-- JOB ID INPUT + JOIN
-- ============================================================
local inputRow = Instance.new("Frame")
inputRow.BackgroundTransparency = 1
inputRow.Position = UDim2.new(0, 12, 0, DIM.HeaderH + 12 + DIM.ActionH + 10)
inputRow.Size = UDim2.new(1, -24, 0, DIM.InputH)
inputRow.Parent = main

local joinBtnW = isMobile and 60 or 96

local jobIdBox = Instance.new("TextBox")
jobIdBox.Size = UDim2.new(1, -joinBtnW - 8, 1, 0)
jobIdBox.BackgroundColor3 = Theme.Panel
jobIdBox.PlaceholderText = isMobile and "Job ID..." or "Enter Job ID..."
jobIdBox.Text = ""
jobIdBox.Font = Enum.Font.Gotham
jobIdBox.TextSize = DIM.InputTextSize
jobIdBox.TextColor3 = Theme.Text
jobIdBox.PlaceholderColor3 = Theme.SubText
jobIdBox.ClearTextOnFocus = false
jobIdBox.Parent = inputRow
corner(jobIdBox, 8)
stroke(jobIdBox, Theme.AccentDark, 1)

local joinBtn = Instance.new("TextButton")
joinBtn.Size = UDim2.new(0, joinBtnW, 1, 0)
joinBtn.Position = UDim2.new(1, -joinBtnW, 0, 0)
joinBtn.BackgroundColor3 = Theme.Green
joinBtn.Text = isMobile and "▶" or "Join"
joinBtn.Font = Enum.Font.GothamBold
joinBtn.TextSize = isMobile and 20 or 14
joinBtn.TextColor3 = Theme.Text
joinBtn.AutoButtonColor = true
joinBtn.Parent = inputRow
corner(joinBtn, 8)

if not isMobile then
    joinBtn.MouseEnter:Connect(function() tween(joinBtn, {BackgroundColor3 = Theme.GreenDark}) end)
    joinBtn.MouseLeave:Connect(function() tween(joinBtn, {BackgroundColor3 = Theme.Green}) end)
end

-- ============================================================
-- SERVER LIST
-- ============================================================
local listTopY = DIM.HeaderH + 12 + DIM.ActionH + 10 + DIM.InputH + 10

local listFrame = Instance.new("ScrollingFrame")
listFrame.Position = UDim2.new(0, 12, 0, listTopY)
listFrame.Size = UDim2.new(1, -24, 1, -(listTopY + 12))
listFrame.BackgroundColor3 = Theme.Panel
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = isMobile and 8 or 5
listFrame.ScrollBarImageColor3 = Theme.Accent
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.ScrollingDirection = Enum.ScrollingDirection.Y
listFrame.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
listFrame.Parent = main
corner(listFrame, 8)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, isMobile and 8 or 6)
listLayout.Parent = listFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 6)
listPadding.PaddingBottom = UDim.new(0, 6)
listPadding.PaddingLeft = UDim.new(0, 6)
listPadding.PaddingRight = UDim.new(0, 6)
listPadding.Parent = listFrame

-- ============================================================
-- CORE LOGIC
-- ============================================================
local HSTESH = {
    Servers = {},
    IsFetching = false
}

local function clearList()
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
end

local function joinServer(jobId)
    statusLabel.Text = "Status: Teleporting..."
    persistScript()
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
    end)
    if not ok then
        statusLabel.Text = "Status: Teleport Failed!"
        warn("[HSTESH] Teleport Error: " .. tostring(err))
    end
end

local function buildRow(index, data)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, DIM.RowH)
    row.BackgroundColor3 = Theme.Row
    row.Parent = listFrame
    corner(row, 8)

    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0, DIM.RowBadgeSize, 0, DIM.RowBadgeSize)
    badge.Position = UDim2.new(0, 8, 0.5, -DIM.RowBadgeSize/2)
    badge.BackgroundColor3 = Theme.Accent
    badge.Parent = row
    corner(badge, 8)

    local badgeLabel = Instance.new("TextLabel")
    badgeLabel.BackgroundTransparency = 1
    badgeLabel.Size = UDim2.new(1, 0, 1, 0)
    badgeLabel.Font = Enum.Font.GothamBold
    badgeLabel.TextSize = DIM.RowTextSize + 2
    badgeLabel.TextColor3 = Theme.Text
    badgeLabel.Text = "#" .. index
    badgeLabel.Parent = badge

    local freeSlots = (data.maxPlayers or 0) - (data.playing or 0)

    local info = Instance.new("TextLabel")
    info.BackgroundTransparency = 1
    info.Position = UDim2.new(0, DIM.RowBadgeSize + 16, 0, 0)
    info.Size = UDim2.new(1, -(DIM.RowBadgeSize + 16 + DIM.RowJoinW + 20), 1, 0)
    info.Font = Enum.Font.Gotham
    info.TextSize = DIM.RowTextSize
    info.TextColor3 = Theme.Text
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.Text = isMobile
        and string.format("%d/%d  •  %d free", data.playing or 0, data.maxPlayers or 0, freeSlots)
        or string.format("Players: %d/%d | Free Slots: %d", data.playing or 0, data.maxPlayers or 0, freeSlots)
    info.Parent = row

    local rowJoin = Instance.new("TextButton")
    rowJoin.Size = UDim2.new(0, DIM.RowJoinW, 0, DIM.RowJoinH)
    rowJoin.Position = UDim2.new(1, -(DIM.RowJoinW + 8), 0.5, -DIM.RowJoinH/2)
    rowJoin.BackgroundColor3 = Theme.Green
    rowJoin.Text = "Join"
    rowJoin.Font = Enum.Font.GothamBold
    rowJoin.TextSize = DIM.RowJoinTextSize
    rowJoin.TextColor3 = Theme.Text
    rowJoin.AutoButtonColor = true
    rowJoin.Parent = row
    corner(rowJoin, 6)

    if not isMobile then
        rowJoin.MouseEnter:Connect(function() tween(rowJoin, {BackgroundColor3 = Theme.GreenDark}) end)
        rowJoin.MouseLeave:Connect(function() tween(rowJoin, {BackgroundColor3 = Theme.Green}) end)
    end

    rowJoin.Activated:Connect(function()
        joinServer(data.id)
    end)

    return row
end

local function renderList()
    clearList()
    for i, data in ipairs(HSTESH.Servers) do
        buildRow(i, data)
    end
end

function HSTESH.FetchServers()
    if HSTESH.IsFetching then return end
    HSTESH.IsFetching = true
    statusLabel.Text = "Status: Fetching..."

    task.spawn(function()
        local filtered = {}
        local cursor = ""

        for page = 1, 5 do
            local rawUrl = string.format(
                "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s",
                placeId,
                cursor ~= "" and ("&cursor=" .. HttpService:UrlEncode(cursor)) or ""
            )

            local success, response = pcall(function()
                return game:HttpGet(rawUrl)
            end)

            if success and response then
                local data = HttpService:JSONDecode(response)
                if data and data.data then
                    for _, s in ipairs(data.data) do
                        if type(s) == "table"
                            and s.id ~= game.JobId
                            and s.playing and s.maxPlayers
                            and s.playing <= MAX_PLAYERS_ALLOWED
                            and s.playing < s.maxPlayers then

                            table.insert(filtered, {
                                id = s.id,
                                playing = s.playing,
                                maxPlayers = s.maxPlayers
                            })
                        end
                    end
                    cursor = data.nextPageCursor or ""
                    if cursor == "" then break end
                else
                    break
                end
            else
                break
            end
            task.wait(0.2)
        end

        table.sort(filtered, function(a, b)
            if a.playing ~= b.playing then return a.playing < b.playing end
            return a.id < b.id
        end)

        HSTESH.Servers = filtered
        renderList()

        if #filtered > 0 then
            genv.HSTESH_RetryCount = 0
            statusLabel.Text = "Loaded: " .. #filtered .. " servers"

            if genv.HSTESH_AutoJoin then
                statusLabel.Text = "Auto-joining..."
                task.wait(0.5)
                if genv.HSTESH_AutoJoin then
                    joinServer(filtered[1].id)
                end
            end
        else
            statusLabel.Text = "No low-player servers"

            if genv.HSTESH_AutoJoin then
                genv.HSTESH_RetryCount = genv.HSTESH_RetryCount + 1
                local waitTime = math.min(5 * genv.HSTESH_RetryCount, 60)
                statusLabel.Text = string.format("Retry in %ds...", waitTime)
                task.wait(waitTime)
                HSTESH.IsFetching = false
                if genv.HSTESH_AutoJoin then
                    HSTESH.FetchServers()
                end
                return
            end
        end

        HSTESH.IsFetching = false
    end)
end

-- ============================================================
-- EVENT HANDLERS
-- ============================================================
refreshBtn.Activated:Connect(function()
    HSTESH.FetchServers()
end)

bestHopBtn.Activated:Connect(function()
    if #HSTESH.Servers > 0 then
        statusLabel.Text = "Hopping..."
        joinServer(HSTESH.Servers[1].id)
    else
        HSTESH.FetchServers()
    end
end)

autoJoinBtn.Activated:Connect(function()
    genv.HSTESH_AutoJoin = not genv.HSTESH_AutoJoin
    if genv.HSTESH_AutoJoin then
        autoJoinBtn.BackgroundColor3 = Theme.GreenDark
        autoJoinBtn.Text = isMobile and "✅" or "Auto Join: ON"
        HSTESH.FetchServers()
    else
        autoJoinBtn.BackgroundColor3 = Theme.Accent
        autoJoinBtn.Text = isMobile and "🤖" or "Auto Join"
    end
end)

joinBtn.Activated:Connect(function()
    local id = jobIdBox.Text
    if id and #id > 0 then
        joinServer(id)
    end
end)

copyIdBtn.Activated:Connect(function()
    local jobId = game.JobId
    local copied = false

    pcall(function()
        if setclipboard then
            setclipboard(jobId)
            copied = true
        elseif syn and syn.write_clipboard then
            syn.write_clipboard(jobId)
            copied = true
        end
    end)

    if copied then
        statusLabel.Text = "✅ Job ID copied!"
    else
        jobIdBox.Text = jobId
        statusLabel.Text = "Job ID in input"
    end

    task.delay(2, function()
        statusLabel.Text = "Idle"
    end)
end)

-- Live Ping Display
RunService.Heartbeat:Connect(function()
    local ping = 0
    pcall(function()
        ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    statsLabel.Text = "PING: " .. math.floor(ping) .. " ms"
end)

-- Initial Execution
HSTESH.FetchServers()

return HSTESH
