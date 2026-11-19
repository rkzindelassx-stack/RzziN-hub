local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")

-- CONFIG
local CFG = {
    ESP = { Outline=false, FullBody=false, Name=false, Tracers=false, Distance=false, OffScreenArrows=false, DroppedGun=false, Traps=false },
    Combat = { Aimbot=false, HitboxSize=1, ShowHitbox=false, SilentThrow=false, KillAll=false, KillSheriff=false, ShootMurderer=false, GrabGun=false, BombJump=false, ThrowKnife=false, WallHop=false, Fly=false, Noclip=false, FreeXray=false },
    Misc = { AutoGrabGun=false, WallCheck=false, SilentAim=false, Triggerbot=false, SilentKnife=false, AutoFarm=false },
    Teleport = { Enabled=false },
}

local ROLE_CACHE = {}
local function getCharacter(p) return p and p.Character end
local function getRootPart(p) local c=getCharacter(p); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHead(p) local c=getCharacter(p); return c and c:FindFirstChild("Head") end
local function isAlive(p)
    local c=getCharacter(p); if not c then return false end
    local h=c:FindFirstChildOfClass("Humanoid"); return h and h.Health>0
end
local function detectRole(player)
    local ok,val=pcall(function() return RS.GameData.Roles:FindFirstChild(player.Name).Value end)
    if ok and val then ROLE_CACHE[player.Name]=val; return val end
    local char=getCharacter(player)
    if char then
        local tool=char:FindFirstChildOfClass("Tool")
        if tool then
            local n=tool.Name:lower()
            if n:find("knife") or n:find("faca") then return "Murderer" end
            if n:find("gun") or n:find("sheriff") or n:find("pistol") then return "Sheriff" end
        end
    end
    return ROLE_CACHE[player.Name] or "Innocent"
end
local ROLE_COLORS = {
    Murderer = Color3.fromRGB(220,50,50),
    Sheriff  = Color3.fromRGB(50,150,255),
    Hero     = Color3.fromRGB(50,150,255),
    Innocent = Color3.fromRGB(50,220,50),
}
local function getRoleColor(player)
    return ROLE_COLORS[detectRole(player)] or ROLE_COLORS.Innocent
end
local function getMyRole()
    local ok,role=pcall(function() return LocalPlayer.PlayerGui.GameGui.RoleFrame.RoleLabel.Text end)
    if ok and role then return role:lower() end
    local char=getCharacter(LocalPlayer)
    if char then
        local tool=char:FindFirstChildOfClass("Tool") or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if tool then
            local n=tool.Name:lower()
            if n:find("knife") then return "murderer" end
            if n:find("gun") or n:find("sheriff") then return "sheriff" end
        end
    end
    return "innocent"
end

-- GUI
local old=gethui():FindFirstChild("RzziNHub"); if old then old:Destroy() end
local SG=Instance.new("ScreenGui")
SG.Name="RzziNHub"; SG.ResetOnSpawn=false; SG.IgnoreGuiInset=true
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; SG.Parent=gethui()

-- Main window
local Win=Instance.new("Frame")
Win.Size=UDim2.new(0,780,0,520)
Win.Position=UDim2.new(0.5,-390,0.5,-260)
Win.BackgroundColor3=Color3.fromRGB(18,18,24)
Win.BorderSizePixel=0; Win.ClipsDescendants=true; Win.Parent=SG
Instance.new("UICorner",Win).CornerRadius=UDim.new(0,10)
local wstroke=Instance.new("UIStroke",Win); wstroke.Color=Color3.fromRGB(50,50,70); wstroke.Thickness=1

-- Top bar
local TopBar=Instance.new("Frame")
TopBar.Size=UDim2.new(1,0,0,48)
TopBar.BackgroundColor3=Color3.fromRGB(12,12,18)
TopBar.BorderSizePixel=0; TopBar.Parent=Win
Instance.new("UICorner",TopBar).CornerRadius=UDim.new(0,10)

-- Logo / title
local Logo=Instance.new("TextLabel")
Logo.Text="⚔  RzziN Hub"
Logo.Font=Enum.Font.GothamBold; Logo.TextSize=16
Logo.TextColor3=Color3.fromRGB(255,255,255)
Logo.BackgroundTransparency=1
Logo.Size=UDim2.new(0,200,1,0); Logo.Position=UDim2.new(0,14,0,0)
Logo.TextXAlignment=Enum.TextXAlignment.Left; Logo.Parent=TopBar

local SubTitle=Instance.new("TextLabel")
SubTitle.Text="Murder Mystery 2"
SubTitle.Font=Enum.Font.Gotham; SubTitle.TextSize=11
SubTitle.TextColor3=Color3.fromRGB(120,120,160)
SubTitle.BackgroundTransparency=1
SubTitle.Size=UDim2.new(0,200,1,0); SubTitle.Position=UDim2.new(0,14,0,18)
SubTitle.TextXAlignment=Enum.TextXAlignment.Left; SubTitle.Parent=TopBar

-- Close
local XBtn=Instance.new("TextButton")
XBtn.Text="✕"; XBtn.Font=Enum.Font.GothamBold; XBtn.TextSize=14
XBtn.TextColor3=Color3.fromRGB(180,180,200); XBtn.BackgroundTransparency=1
XBtn.Size=UDim2.new(0,36,0,36); XBtn.Position=UDim2.new(1,-40,0.5,-18); XBtn.Parent=TopBar
XBtn.MouseButton1Click:Connect(function() Win.Visible=not Win.Visible end)

-- Minimize
local MBtn=Instance.new("TextButton")
MBtn.Text="—"; MBtn.Font=Enum.Font.GothamBold; MBtn.TextSize=14
MBtn.TextColor3=Color3.fromRGB(180,180,200); MBtn.BackgroundTransparency=1
MBtn.Size=UDim2.new(0,36,0,36); MBtn.Position=UDim2.new(1,-78,0.5,-18); MBtn.Parent=TopBar

local minimized=false
local fullSize=UDim2.new(0,780,0,520)
local miniSize=UDim2.new(0,780,0,48)
MBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    TweenService:Create(Win,TweenInfo.new(0.2),{Size=minimized and miniSize or fullSize}):Play()
end)

-- Drag
local drag,ds,dp=false,nil,nil
TopBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        drag=true; ds=Vector2.new(i.Position.X,i.Position.Y); dp=Win.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=Vector2.new(i.Position.X,i.Position.Y)-ds
        Win.Position=UDim2.new(dp.X.Scale,dp.X.Offset+d.X,dp.Y.Scale,dp.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
end)

-- Top action buttons (Shoot Murderer, Grab Gun, Aimbot ON, Bomb Jump, Throw Knife, Wall Hop, Kill All Murder, Kill Sheriff, Fly, Noclip, Free X-Ray)
local BtnBar=Instance.new("Frame")
BtnBar.Size=UDim2.new(1,0,0,70)
BtnBar.Position=UDim2.new(0,0,0,48)
BtnBar.BackgroundColor3=Color3.fromRGB(14,14,20)
BtnBar.BorderSizePixel=0; BtnBar.Parent=Win
local BtnLayout=Instance.new("UIListLayout",BtnBar)
BtnLayout.FillDirection=Enum.FillDirection.Horizontal
BtnLayout.SortOrder=Enum.SortOrder.LayoutOrder
BtnLayout.Padding=UDim.new(0,4)
local BtnPad=Instance.new("UIPadding",BtnBar)
BtnPad.PaddingLeft=UDim.new(0,8); BtnPad.PaddingTop=UDim.new(0,8)

local ACTION_BTNS = {
    {label="SHOOT\nMURDERER", key="ShootMurderer", tbl=CFG.Combat},
    {label="GRAB\nGUN",       key="GrabGun",       tbl=CFG.Combat},
    {label="AIMBOT",          key="Aimbot",         tbl=CFG.Combat},
    {label="BOMB\nJUMP",      key="BombJump",       tbl=CFG.Combat},
    {label="THROW\nKNIFE",    key="ThrowKnife",     tbl=CFG.Combat},
    {label="WALL\nHOP",       key="WallHop",        tbl=CFG.Combat},
    {label="KILL ALL\nMURDER ONLY", key="KillAll",  tbl=CFG.Combat},
    {label="KILL\nSHERIFF",   key="KillSheriff",    tbl=CFG.Combat},
    {label="FLY",             key="Fly",            tbl=CFG.Combat},
    {label="NOCLIP",          key="Noclip",         tbl=CFG.Combat},
    {label="FREE\nX-RAY",     key="FreeXray",       tbl=CFG.Combat},
}

local function makeActionBtn(data, order)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(0,62,0,54); f.LayoutOrder=order
    f.BackgroundColor3=Color3.fromRGB(28,28,38); f.BorderSizePixel=0; f.Parent=BtnBar
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
    local lbl=Instance.new("TextLabel")
    lbl.Text=data.label; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=9
    lbl.TextColor3=Color3.fromRGB(180,180,210); lbl.BackgroundTransparency=1
    lbl.Size=UDim2.new(1,0,1,0); lbl.TextWrapped=true; lbl.Parent=f
    local indicator=Instance.new("Frame")
    indicator.Size=UDim2.new(1,0,0,3); indicator.Position=UDim2.new(0,0,1,-3)
    indicator.BackgroundColor3=Color3.fromRGB(0,200,100); indicator.BorderSizePixel=0
    indicator.Visible=false; indicator.Parent=f
    Instance.new("UICorner",indicator).CornerRadius=UDim.new(0,2)
    local btn=Instance.new("TextButton")
    btn.Text=""; btn.BackgroundTransparency=1; btn.Size=UDim2.new(1,0,1,0); btn.Parent=f
    btn.MouseButton1Click:Connect(function()
        data.tbl[data.key]=not data.tbl[data.key]
        indicator.Visible=data.tbl[data.key]
        f.BackgroundColor3=data.tbl[data.key] and Color3.fromRGB(35,35,55) or Color3.fromRGB(28,28,38)
        lbl.TextColor3=data.tbl[data.key] and Color3.fromRGB(0,220,120) or Color3.fromRGB(180,180,210)
        if data.key=="Aimbot" then lbl.Text=data.tbl[data.key] and "AIMBOT\nON" or "AIMBOT" end
    end)
end
for i,d in ipairs(ACTION_BTNS) do makeActionBtn(d,i) end

-- Separator
local Sep=Instance.new("Frame")
Sep.Size=UDim2.new(1,0,0,1); Sep.Position=UDim2.new(0,0,0,118)
Sep.BackgroundColor3=Color3.fromRGB(40,40,60); Sep.BorderSizePixel=0; Sep.Parent=Win

-- Left sidebar
local Sidebar=Instance.new("Frame")
Sidebar.Size=UDim2.new(0,160,1,-120)
Sidebar.Position=UDim2.new(0,0,0,120)
Sidebar.BackgroundColor3=Color3.fromRGB(14,14,20)
Sidebar.BorderSizePixel=0; Sidebar.Parent=Win

local SideLayout=Instance.new("UIListLayout",Sidebar)
SideLayout.SortOrder=Enum.SortOrder.LayoutOrder
SideLayout.Padding=UDim.new(0,2)
local SidePad=Instance.new("UIPadding",Sidebar)
SidePad.PaddingTop=UDim.new(0,8); SidePad.PaddingLeft=UDim.new(0,8); SidePad.PaddingRight=UDim.new(0,8)

-- Search bar
local SearchFrame=Instance.new("Frame")
SearchFrame.Size=UDim2.new(1,0,0,32); SearchFrame.LayoutOrder=0
SearchFrame.BackgroundColor3=Color3.fromRGB(28,28,38); SearchFrame.BorderSizePixel=0; SearchFrame.Parent=Sidebar
Instance.new("UICorner",SearchFrame).CornerRadius=UDim.new(0,6)
local SearchBox=Instance.new("TextBox")
SearchBox.Text=""; SearchBox.PlaceholderText="Search"
SearchBox.Font=Enum.Font.Gotham; SearchBox.TextSize=12
SearchBox.TextColor3=Color3.fromRGB(200,200,220); SearchBox.PlaceholderColor3=Color3.fromRGB(100,100,130)
SearchBox.BackgroundTransparency=1; SearchBox.Size=UDim2.new(1,-10,1,0); SearchBox.Position=UDim2.new(0,10,0,0)
SearchBox.TextXAlignment=Enum.TextXAlignment.Left; SearchBox.Parent=SearchFrame

-- Content area
local ContentArea=Instance.new("ScrollingFrame")
ContentArea.Size=UDim2.new(1,-160,1,-120)
ContentArea.Position=UDim2.new(0,160,0,120)
ContentArea.BackgroundColor3=Color3.fromRGB(18,18,24)
ContentArea.BorderSizePixel=0
ContentArea.ScrollBarThickness=4
ContentArea.ScrollBarImageColor3=Color3.fromRGB(80,80,120)
ContentArea.CanvasSize=UDim2.new(0,0,0,0)
ContentArea.AutomaticCanvasSize=Enum.AutomaticSize.Y
ContentArea.Parent=Win
local CALayout=Instance.new("UIListLayout",ContentArea)
CALayout.SortOrder=Enum.SortOrder.LayoutOrder; CALayout.Padding=UDim.new(0,2)
local CAPad=Instance.new("UIPadding",ContentArea)
CAPad.PaddingLeft=UDim.new(0,14); CAPad.PaddingRight=UDim.new(0,14); CAPad.PaddingTop=UDim.new(0,10)

-- Sidebar vertical separator
local VSep=Instance.new("Frame")
VSep.Size=UDim2.new(0,1,1,-120); VSep.Position=UDim2.new(0,160,0,120)
VSep.BackgroundColor3=Color3.fromRGB(40,40,60); VSep.BorderSizePixel=0; VSep.Parent=Win

-- Tab system
local PAGES={}
local activePage=nil

local CATEGORIES = {
    {name="Combat",        icon="🗡"},
    {name="Crosshair",     icon="⊕"},
    {name="Skin Changer",  icon="🎨"},
    {name="Buttons",       icon="⚙"},
    {name="ESP",           icon="👁"},
    {name="Fling & Teleport", icon="⚡"},
    {name="Autofarm",      icon="💰"},
    {name="Player",        icon="👤"},
    {name="Visuals",       icon="✨"},
    {name="Keybinds",      icon="⌨"},
}

local function switchPage(name)
    for pname,p in pairs(PAGES) do p.Visible=(pname==name) end
    activePage=name
end

local function makeSideBtn(cat, order)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,0,36); btn.LayoutOrder=order+1
    btn.BackgroundColor3=Color3.fromRGB(28,28,38); btn.BorderSizePixel=0; btn.Parent=Sidebar
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
    btn.Text=""; btn.AutoButtonColor=false

    local icon=Instance.new("TextLabel")
    icon.Text=cat.icon; icon.Font=Enum.Font.GothamBold; icon.TextSize=14
    icon.TextColor3=Color3.fromRGB(150,150,200); icon.BackgroundTransparency=1
    icon.Size=UDim2.new(0,28,1,0); icon.Position=UDim2.new(0,6,0,0); icon.Parent=btn

    local lbl=Instance.new("TextLabel")
    lbl.Text=cat.name; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=12
    lbl.TextColor3=Color3.fromRGB(180,180,210); lbl.BackgroundTransparency=1
    lbl.Size=UDim2.new(1,-36,1,0); lbl.Position=UDim2.new(0,34,0,0)
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=btn

    btn.MouseButton1Click:Connect(function()
        switchPage(cat.name)
        for _,c in pairs(Sidebar:GetChildren()) do
            if c:IsA("TextButton") then
                c.BackgroundColor3=Color3.fromRGB(28,28,38)
                local l=c:FindFirstChildOfClass("TextLabel")
                if l then l.TextColor3=Color3.fromRGB(180,180,210) end
            end
        end
        btn.BackgroundColor3=Color3.fromRGB(38,35,65)
        lbl.TextColor3=Color3.fromRGB(220,210,255)
    end)

    -- Page container
    local page=Instance.new("Frame")
    page.BackgroundTransparency=1; page.Size=UDim2.new(1,0,0,0)
    page.AutomaticSize=Enum.AutomaticSize.Y; page.LayoutOrder=order
    page.Visible=false; page.Parent=ContentArea
    local pl=Instance.new("UIListLayout",page)
    pl.SortOrder=Enum.SortOrder.LayoutOrder; pl.Padding=UDim.new(0,4)
    PAGES[cat.name]=page
    return page
end

for i,cat in ipairs(CATEGORIES) do makeSideBtn(cat,i) end

-- Section header
local function makeHeader(parent, text, order)
    local lbl=Instance.new("TextLabel")
    lbl.Text=text; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=13
    lbl.TextColor3=Color3.fromRGB(220,210,255); lbl.BackgroundTransparency=1
    lbl.Size=UDim2.new(1,0,0,28); lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.LayoutOrder=order; lbl.Parent=parent
end

-- Toggle row
local function makeToggle(parent, label, desc, cfgTable, cfgKey, order)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,desc and 52 or 38)
    row.BackgroundColor3=Color3.fromRGB(24,24,34); row.BorderSizePixel=0
    row.LayoutOrder=order; row.Parent=parent
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)

    local lbl=Instance.new("TextLabel")
    lbl.Text=label; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=13
    lbl.TextColor3=Color3.fromRGB(220,215,240); lbl.BackgroundTransparency=1
    lbl.Size=UDim2.new(1,-60,0,22); lbl.Position=UDim2.new(0,14,0,desc and 7 or 8)
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row

    if desc then
        local dlbl=Instance.new("TextLabel")
        dlbl.Text=desc; dlbl.Font=Enum.Font.Gotham; dlbl.TextSize=10
        dlbl.TextColor3=Color3.fromRGB(120,115,160); dlbl.BackgroundTransparency=1
        dlbl.Size=UDim2.new(1,-60,0,18); dlbl.Position=UDim2.new(0,14,0,26)
        dlbl.TextXAlignment=Enum.TextXAlignment.Left; dlbl.TextWrapped=true; dlbl.Parent=row
    end

    local bg=Instance.new("Frame")
    bg.Size=UDim2.new(0,44,0,22); bg.Position=UDim2.new(1,-54,0.5,-11)
    bg.BackgroundColor3=cfgTable[cfgKey] and Color3.fromRGB(80,80,220) or Color3.fromRGB(50,50,70)
    bg.BorderSizePixel=0; bg.Parent=row
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,11)

    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,18,0,18)
    knob.Position=cfgTable[cfgKey] and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
    knob.BackgroundColor3=Color3.fromRGB(255,255,255); knob.BorderSizePixel=0; knob.Parent=bg
    Instance.new("UICorner",knob).CornerRadius=UDim.new(0,9)

    local function refresh()
        local on=cfgTable[cfgKey]
        TweenService:Create(bg,TweenInfo.new(0.15),{BackgroundColor3=on and Color3.fromRGB(80,80,220) or Color3.fromRGB(50,50,70)}):Play()
        TweenService:Create(knob,TweenInfo.new(0.15),{Position=on and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)}):Play()
    end

    local btn=Instance.new("TextButton")
    btn.Text=""; btn.BackgroundTransparency=1; btn.Size=UDim2.new(1,0,1,0); btn.Parent=row
    btn.MouseButton1Click:Connect(function() cfgTable[cfgKey]=not cfgTable[cfgKey]; refresh() end)
end

-- Slider
local function makeSlider(parent, label, desc, min, max, default, onChange, order)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,62); row.BackgroundColor3=Color3.fromRGB(24,24,34)
    row.BorderSizePixel=0; row.LayoutOrder=order; row.Parent=parent
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)

    local lbl=Instance.new("TextLabel")
    lbl.Text=label; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=13
    lbl.TextColor3=Color3.fromRGB(220,215,240); lbl.BackgroundTransparency=1
    lbl.Size=UDim2.new(1,-80,0,20); lbl.Position=UDim2.new(0,14,0,7)
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row

    local valLbl=Instance.new("TextLabel")
    valLbl.Text=tostring(default); valLbl.Font=Enum.Font.GothamBold; valLbl.TextSize=13
    valLbl.TextColor3=Color3.fromRGB(150,140,220); valLbl.BackgroundTransparency=1
    valLbl.Size=UDim2.new(0,60,0,20); valLbl.Position=UDim2.new(1,-74,0,7)
    valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.Parent=row

    if desc then
        local dlbl=Instance.new("TextLabel")
        dlbl.Text=desc; dlbl.Font=Enum.Font.Gotham; dlbl.TextSize=10
        dlbl.TextColor3=Color3.fromRGB(120,115,160); dlbl.BackgroundTransparency=1
        dlbl.Size=UDim2.new(1,-20,0,14); dlbl.Position=UDim2.new(0,14,0,24)
        dlbl.TextXAlignment=Enum.TextXAlignment.Left; dlbl.TextWrapped=true; dlbl.Parent=row
    end

    local track=Instance.new("Frame")
    track.Size=UDim2.new(1,-28,0,6); track.Position=UDim2.new(0,14,0,45)
    track.BackgroundColor3=Color3.fromRGB(50,50,70); track.BorderSizePixel=0; track.Parent=row
    Instance.new("UICorner",track).CornerRadius=UDim.new(0,3)

    local pct=(default-min)/(max-min)
    local fill=Instance.new("Frame")
    fill.Size=UDim2.new(pct,0,1,0); fill.BackgroundColor3=Color3.fromRGB(80,80,220)
    fill.BorderSizePixel=0; fill.Parent=track
    Instance.new("UICorner",fill).CornerRadius=UDim.new(0,3)

    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,16,0,16); knob.Position=UDim2.new(pct,-8,0.5,-8)
    knob.BackgroundColor3=Color3.fromRGB(255,255,255); knob.BorderSizePixel=0; knob.Parent=track
    Instance.new("UICorner",knob).CornerRadius=UDim.new(0,8)

    local sliding=false
    local function update(input)
        local relX=input.Position.X-track.AbsolutePosition.X
        local p=math.clamp(relX/track.AbsoluteSize.X,0,1)
        local val=math.floor(min+p*(max-min))
        valLbl.Text=tostring(val)
        fill.Size=UDim2.new(p,0,1,0)
        knob.Position=UDim2.new(p,-8,0.5,-8)
        if onChange then onChange(val) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=true; update(i) end
    end)
    knob.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=true end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then update(i) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=false end
    end)
end

-- Button action row
local function makeActionRow(parent, label, desc, onClick, order, highl
