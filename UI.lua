--[[
	██ RUFU UI v2.2 (FULL FIXED VERSION)
	Все баги исправлены: Блюр, Аватарка, Смена Темы (фон теперь красится), Синтаксис.
]]

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Lighting          = game:GetService("Lighting")
local Debris            = game:GetService("Debris")
local HttpService       = game:GetService("HttpService")
local ContentProvider   = game:GetService("ContentProvider")
local Stats             = game:GetService("Stats")
local TextService       = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ══════════════════════════ НАСТРОЙКИ ══════════════════════════
local CONFIG = {
	Title       = "RUFU",
	Version     = "v2.2",
	ToggleKey   = Enum.KeyCode.RightShift,
	Size        = Vector2.new(500, 340),
	MinSize     = Vector2.new(430, 250),
	MaxSize     = Vector2.new(780, 640),
	Accent      = Color3.fromRGB(96, 150, 255),
	Accent2     = Color3.fromRGB(146, 122, 255),
	Blur        = 14,
	Dim         = 0.12,
	Scale       = 1,
	OpenOnStart = false,
	Sounds      = false,
	Watermark   = true,
	BindHud     = true,
	Motion      = 1,
	AutoSave    = true,
	Folder      = "Rufu",
}

local T = {
	Bg      = Color3.fromRGB(14, 15, 20),
	Panel   = Color3.fromRGB(22, 24, 31),
	Side    = Color3.fromRGB(18, 20, 26),
	Card    = Color3.fromRGB(38, 41, 52),
	Track   = Color3.fromRGB(60, 64, 78),
	Text    = Color3.fromRGB(238, 240, 247),
	Sub     = Color3.fromRGB(146, 152, 168),
	Dim     = Color3.fromRGB(104, 110, 126),
	White   = Color3.fromRGB(255, 255, 255),
	Good    = Color3.fromRGB(80, 220, 140),
	Warn    = Color3.fromRGB(255, 190, 90),
	Bad     = Color3.fromRGB(255, 96, 110),
}

local ACCENT, ACCENT2 = CONFIG.Accent, CONFIG.Accent2

-- ══════════════════════════ МОУШЕН-ЯДРО (ФИКС БЛЮРА) ══════════════════════════
local Anim = { mul = CONFIG.Motion, off = false }
local loops = {}
local activeTweens = setmetatable({}, { __mode = "k" })

local function tween(obj, time, style, dir, props)
	local reg = activeTweens[obj]
	if not reg then reg = {}; activeTweens[obj] = reg end
	for prop in pairs(props) do
		local old = reg[prop]
		if old then pcall(function() old:Cancel() end); reg[prop] = nil end
	end
	local t = TweenService:Create(obj, TweenInfo.new(Anim.off and 0.001 or math.max(0.001, time * Anim.mul),
		style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	for prop in pairs(props) do reg[prop] = t end
	local conn
	conn = t.Completed:Connect(function()
		conn:Disconnect()
		for prop in pairs(props) do if reg[prop] == t then reg[prop] = nil end end
	end)
	t:Play()
	return t
end

local function loop(obj, time, style, props, reverse)
	local spec = { obj = obj, time = time, style = style, props = props, rev = reverse }
	loops[#loops + 1] = spec
	if not Anim.off then
		spec.t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, reverse and true or false), props)
		spec.t:Play()
	end
	return spec
end

local function setMotionEnabled(on)
	Anim.off = not on
	for _, s in ipairs(loops) do
		if s.t then pcall(function() s.t:Cancel() end); s.t = nil end
		if on and s.obj and s.obj.Parent then
			s.t = TweenService:Create(s.obj, TweenInfo.new(s.time, s.style or Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, s.rev and true or false), s.props)
			s.t:Play()
		end
	end
end

-- ══════════════════════════ ХЕЛПЕРЫ ══════════════════════════
local function new(class, props, children)
	local obj = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do if k == "Parent" then parent = v else obj[k] = v end end
	for _, c in ipairs(children or {}) do c.Parent = obj end
	obj.Parent = parent
	return obj
end

local function corner(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = o }) end
local function stroke(o, tr, th, col)
	return new("UIStroke", { Color = col or T.White, Transparency = tr or 0.9, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = o })
end
local function pad(o, l, r, t, b)
	return new("UIPadding", { PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0), PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0), Parent = o })
end
local function text(props)
	local d = { BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = "", TextColor3 = T.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Size = UDim2.fromScale(1, 1), TextTruncate = Enum.TextTruncate.AtEnd }
	for k, v in pairs(props) do d[k] = v end
	return new("TextLabel", d)
end

local accentSetters, glassSetters = {}, {}
local function accent(fn) accentSetters[#accentSetters + 1] = fn end
local conns = {}
local function connect(signal, fn) local c = signal:Connect(fn); conns[#conns + 1] = c; return c end
local function lerp(a, b, t) return a + (b - a) * t end
local function clamp(v, a, b) return math.max(a, math.min(b, v)) end
local function round(v) return math.floor(v + 0.5) end

-- ══════════════════════════ ИКОНКИ ══════════════════════════
local ICONS = {
	grid={f={{1,1,5,5,1.5},{8,1,5,5,1.5},{1,8,5,5,1.5},{8,8,5,5,1.5}}}, eye={r={{1,1,12,12,1.4}},f={{5,5,4,4,2}}},
	misc={f={{1,2,12,2,1},{1,6,8,2,1},{1,10,10,2,1}}}, sliders={f={{1,3,12,2,1},{1,9,12,2,1},{2,1.5,5,5,3},{7,7.5,5,5,3}}},
	search={r={{1,1,9,9,1.3}},f={{8,9,5,1.6,1,45}}}, close={f={{1,6,12,1.6,1,45},{1,6,12,1.6,1,-45}}}, minus={f={{2,6,10,1.8,1}}},
	plus={f={{2,6,10,1.8,1},{6,2,1.8,10,1}}}, user={f={{4.5,1,5,5,3},{2,8,10,5,2.5}}}, players={f={{2,2,4,4,2},{8,2,4,4,2},{1,8,6,4,2},{7,8,6,4,2}}},
	palette={r={{1,1,12,12,1.4}},f={{3,4,2,2,1},{7,2.5,2,2,1},{9.5,6,2,2,1},{5,9,2,2,1}}}, save={r={{1,1,12,12,2}},f={{4,2,6,4,1},{3,8,8,4,1}}},
	folder={f={{1,3,12,9,2},{1,2,5,2,1}}}, key={r={{1,4,6,6,1.4}},f={{6,6.4,7,1.6,1},{10,8,1.6,3,1}}}, bolt={f={{4,1,4,7,1,16},{6,6,4,7,1,16}}},
	check={f={{1.5,6.6,5,1.8,1,45},{4.4,7,8.4,1.8,1,-45}}}, warn={f={{6,1,2,8,1},{6,11,2,2,1}}}, info={f={{6,5,2,7.5,1},{6,1.5,2,2,1}}},
	terminal={r={{1,2,12,10,2}},f={{3,5,4,1.4,1},{3,8,6,1.4,1}}}, pin={f={{6,1,2,8,1},{3,8,8,1.6,1},{6.2,9,1.6,4,1}}},
	refresh={r={{1,1,12,12,1.4}},f={{8.5,0.5,4,3,1}}}, copy={r={{1,1,8,8,1.6},{4.5,4.5,8.5,8.5,1.6}}}, chevron={f={{1.6,4.6,6,1.6,1,45},{6.4,4.6,6,1.6,1,-45}}},
	spark={f={{6,0.5,2,13,1},{0.5,6,13,2,1},{3,3,1.6,1.6,1},{9.4,9.4,1.6,1.6,1}}}, target={r={{1,1,12,12,1.3},{4,4,6,6,1.3}},f={{6,6,2,2,1}}},
	home={f={{2,6,10,7,1.5},{0.6,3.4,7.4,1.8,1,-40},{6,3.4,7.4,1.8,1,40}}},
}
local function icon(kind, parent, color, pos, size)
	local box = new("Frame", { Name="Icon", BackgroundTransparency=1, Size=UDim2.fromOffset(size or 14, size or 14), Position=pos or UDim2.fromOffset(0,0), Parent=parent })
	local spec = ICONS[kind] or ICONS.grid; local parts = {}
	for _, d in ipairs(spec.f or {}) do
		local f = new("Frame", { BackgroundColor3=color, BorderSizePixel=0, Size=UDim2.fromOffset(d[3],d[4]), Position=UDim2.fromOffset(d[1],d[2]), Rotation=d[6] or 0, Parent=box })
		corner(f, d[5] or 1); parts[#parts+1] = { o=f, p="BackgroundColor3" }
	end
	for _, d in ipairs(spec.r or {}) do
		local f = new("Frame", { BackgroundTransparency=1, Size=UDim2.fromOffset(d[3],d[4]), Position=UDim2.fromOffset(d[1],d[2]), Parent=box })
		corner(f, 99); local s = stroke(f, 0, d[5] or 1.4, color); parts[#parts+1] = { o=s, p="Color" }
	end
	local function recolor(c, time) for _, p in ipairs(parts) do tween(p.o, time or 0.22, Enum.EasingStyle.Quad, nil, { [p.p]=c }) end end
	return box, recolor
end

-- ══════════════════════════ АВАТАРКИ ══════════════════════════
local function setAvatar(img, userId, px)
	px = px or 150; img.ScaleType = Enum.ScaleType.Crop; img.ImageTransparency = 1
	img.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=%d&h=%d", userId, px, px)
	task.spawn(function()
		pcall(function() ContentProvider:PreloadAsync({ img }) end)
		if not img.Parent then return end
		tween(img, 0.45, Enum.EasingStyle.Quad, nil, { ImageTransparency = 0 })
		for i = 1, 3 do
			local ok, url, ready = pcall(function() return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
			if ok and url and ready then if img.Parent then img.Image = url end return end
			task.wait(0.5 * i)
		end
	end)
end

-- ══════════════════════════ ХРАНИЛИЩЕ ══════════════════════════
local function isfn(f) return typeof(f) == "function" end
local FS = { available = isfn(writefile) and isfn(readfile) }
local memory = _G.__RufuFiles or {}; _G.__RufuFiles = memory
pcall(function() if FS.available and isfn(makefolder) and isfn(isfolder) and not isfolder(CONFIG.Folder) then makefolder(CONFIG.Folder) end end)
local function fpath(name) return CONFIG.Folder .. "/" .. name .. ".json" end
function FS.write(name, data) if FS.available then local ok = pcall(function() writefile(fpath(name), data) end); if ok then return true end end memory[name] = data; return false end
function FS.read(name) if FS.available and isfn(isfile) then local ok, data = pcall(function() if isfile(fpath(name)) then return readfile(fpath(name)) end return nil end); if ok and data then return data end end return memory[name] end
function FS.list()
	local out = {}
	if FS.available and isfn(listfiles) then pcall(function() for _, f in ipairs(listfiles(CONFIG.Folder)) do local n = string.match(f, "([^/\\]+)%.json$"); if n then out[#out+1] = n end end end) end
	for n in pairs(memory) do local found = false; for _, v in ipairs(out) do if v == n then found = true end end; if not found then out[#out+1] = n end end
	table.sort(out); return out
end
function FS.delete(name) memory[name] = nil; if FS.available and isfn(delfile) then pcall(function() delfile(fpath(name)) end) end end

-- ══════════════════════════ КАРКАС ══════════════════════════
if _G.__RufuUI and _G.__RufuUI.Destroy then pcall(function() _G.__RufuUI:Destroy() end) end
local W, H = CONFIG.Size.X, CONFIG.Size.Y; local MARGIN = 40
local gui = new("ScreenGui", { Name="RufuUI", ResetOnSpawn=false, IgnoreGuiInset=true, AutoLocalize=false, DisplayOrder=999, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, Enabled=true, Parent=PlayerGui })
local root = new("CanvasGroup", { Name="Root", BackgroundTransparency=1, GroupTransparency=1, Visible=false, AnchorPoint=Vector2.new(0.5,0.5), Size=UDim2.fromOffset(W+MARGIN*2, H+MARGIN*2), Position=UDim2.fromScale(0.5,0.5), Parent=gui })
local uiScale = new("UIScale", { Scale=CONFIG.Scale, Parent=root })

local shadows, glow = {}, nil
do
	local function shadow(grow, tr, col, r)
		local f = new("Frame", { BackgroundColor3=col or Color3.new(0,0,0), BackgroundTransparency=tr, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,4), Size=UDim2.fromOffset(W+grow,H+grow), ZIndex=1, Parent=root }, { new("UICorner", { CornerRadius=UDim.new(0, r or 18) }) })
		shadows[#shadows+1] = { o=f, grow=grow }; return f
	end
	glow = shadow(70, 0.965, ACCENT, 28); accent(function(c) tween(glow, 0.35, nil, nil, { BackgroundColor3=c }) end)
	shadow(36, 0.90, nil, 22); shadow(18, 0.86, nil, 20); shadow(8, 0.80, nil, 18)
end
local function layoutShadows(h, instant)
	for _, s in ipairs(shadows) do local size = UDim2.fromOffset(W+s.grow, (h or H)+s.grow); if instant then s.o.Size = size else tween(s.o, 0.35, nil, nil, { Size=size }) end end
	root.Size = UDim2.fromOffset(W+MARGIN*2, (h or H)+MARGIN*2)
end

local panel = new("Frame", { Name="Panel", BackgroundColor3=T.Panel, BackgroundTransparency=0.12, BorderSizePixel=0, ClipsDescendants=true, ZIndex=2, Position=UDim2.fromOffset(MARGIN,MARGIN), Size=UDim2.fromOffset(W,H), Parent=root })
corner(panel, 14); local panelStroke = stroke(panel, 0.86, 1.2)

-- Градиент панели (теперь красится при смене темы)
local panelGrad = new("UIGradient", {
	Rotation = 115,
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 43, 56)),
		ColorSequenceKeypoint.new(0.55, T.Panel),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 16, 21)),
	}),
	Parent = panel,
})
accent(function(c)
	local h, s, v = Color3.toHSV(c)
	tween(panelGrad, 0.4, nil, nil, {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(h, clamp(s*0.4,0,1), 0.22)),
			ColorSequenceKeypoint.new(0.55, Color3.fromHSV(h, clamp(s*0.4,0,1), 0.12)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(h, clamp(s*0.5,0,1), 0.06))
		})
	})
end)

glassSetters[#glassSetters+1] = function(v) tween(panel, 0.3, nil, nil, { BackgroundTransparency=v }); tween(panelStroke, 0.3, nil, nil, { Transparency=clamp(v+0.74,0,0.95) }) end

local sheenGrad = new("UIGradient", { Transparency=NumberSequence.new({ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(0.42,1), NumberSequenceKeypoint.new(0.5,0.15), NumberSequenceKeypoint.new(0.58,1), NumberSequenceKeypoint.new(1,1) }), Color=ColorSequence.new(T.White, ACCENT), Offset=Vector2.new(-1,0) })
sheenGrad.Parent = new("Frame", { BackgroundColor3=T.White, BorderSizePixel=0, ZIndex=6, Position=UDim2.fromOffset(16,0), Size=UDim2.new(1,-32,0,1), Parent=panel })
accent(function(c) tween(sheenGrad, 0.35, nil, nil, { Color=ColorSequence.new(T.White, c) }) end)

local dragZone = new("TextButton", { Name="Drag", Text="", AutoButtonColor=false, BackgroundTransparency=1, Size=UDim2.new(1,0,0,46), ZIndex=1, Parent=panel })

-- ── сайдбар ──
local SIDE_W = 124
local side = new("Frame", { Name="Sidebar", BackgroundColor3=T.Side, BackgroundTransparency=0.28, BorderSizePixel=0, Size=UDim2.new(0,SIDE_W,1,0), ZIndex=2, Parent=panel })
new("UIGradient", { Rotation=90, Transparency=NumberSequence.new({ NumberSequenceKeypoint.new(0,0.15), NumberSequenceKeypoint.new(1,0.55) }), Parent=side })
glassSetters[#glassSetters+1] = function(v) tween(side, 0.3, nil, nil, { BackgroundTransparency=clamp(v+0.16,0,0.9) }) end
new("Frame", { BackgroundColor3=T.White, BackgroundTransparency=0.92, BorderSizePixel=0, Position=UDim2.new(1,-1,0,0), Size=UDim2.new(0,1,1,0), Parent=side })

local logoBtn = new("TextButton", { Text="", AutoButtonColor=false, BackgroundColor3=ACCENT, BorderSizePixel=0, ZIndex=3, Position=UDim2.fromOffset(12,13), Size=UDim2.fromOffset(20,20), Parent=side })
corner(logoBtn, 6); accent(function(c) tween(logoBtn, 0.35, nil, nil, { BackgroundColor3=c }) end)
local logoGrad = new("UIGradient", { Rotation=45, Color=ColorSequence.new(ACCENT, ACCENT2), Parent=logoBtn }); accent(function(c) tween(logoGrad, 0.35, nil, nil, { Color=ColorSequence.new(c, ACCENT2) }) end)
local logoScale = new("UIScale", { Scale=1, Parent=logoBtn })
local logoDot = new("Frame", { BackgroundColor3=T.White, BackgroundTransparency=0.15, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(7,7), Parent=logoBtn }); corner(logoDot, 4)
text({ Text=CONFIG.Title, Font=Enum.Font.GothamBold, TextSize=13, ZIndex=3, Position=UDim2.fromOffset(38,12), Size=UDim2.fromOffset(64,14), Parent=side })
local verChip = new("Frame", { BackgroundColor3=ACCENT, BackgroundTransparency=0.82, BorderSizePixel=0, ZIndex=3, Position=UDim2.fromOffset(38,26), Size=UDim2.fromOffset(30,11), Parent=side }); corner(verChip, 5); accent(function(c) tween(verChip, 0.35, nil, nil, { BackgroundColor3=c }) end)
text({ Text=CONFIG.Version, TextSize=8, Font=Enum.Font.GothamBold, TextColor3=T.Text, TextXAlignment=Enum.TextXAlignment.Center, ZIndex=3, Size=UDim2.fromScale(1,1), Parent=verChip })

local tabsBox = new("CanvasGroup", { BackgroundTransparency=1, GroupTransparency=0, Position=UDim2.fromOffset(9,58), Size=UDim2.new(1,-18,1,-128), ZIndex=3, Parent=side })
local TAB_H, TAB_GAP = 32, 4
local pill = new("Frame", { Name="Pill", BackgroundColor3=T.White, BackgroundTransparency=0.9, BorderSizePixel=0, Size=UDim2.new(1,0,0,TAB_H), Position=UDim2.fromOffset(0,0), ZIndex=1, Parent=tabsBox }); corner(pill, 9); stroke(pill, 0.9, 1)
local pillBar = new("Frame", { BackgroundColor3=ACCENT, BorderSizePixel=0, AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,0,0.5,0), Size=UDim2.fromOffset(3,15), Parent=pill }); corner(pillBar, 2); accent(function(c) tween(pillBar, 0.35, nil, nil, { BackgroundColor3=c }) end)

-- ── профиль (ФИКС АВАТАРКИ) ──
local profile = new("CanvasGroup", { Name="Profile", BackgroundTransparency=1, GroupTransparency=0, ZIndex=3, AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,12,1,-10), Size=UDim2.new(1,-24,0,34), Parent=side })
local avatarHolder = new("Frame", { BackgroundColor3=T.Card, BackgroundTransparency=0.25, BorderSizePixel=0, ZIndex=2, AnchorPoint=Vector2.new(0.5,0.5), Size=UDim2.fromOffset(28,28), Position=UDim2.fromOffset(16,17), Parent=profile })
corner(avatarHolder, 14)
local avatarRing = stroke(avatarHolder, 0.55, 1.4, ACCENT); accent(function(c) tween(avatarRing, 0.35, nil, nil, { Color=c }) end)
text({ Text=string.upper(string.sub(LocalPlayer.DisplayName,1,1)), Font=Enum.Font.GothamBold, TextSize=12, TextColor3=T.Sub, TextXAlignment=Enum.TextXAlignment.Center, ZIndex=2, Size=UDim2.fromScale(1,1), Parent=avatarHolder })
local avatar = new("ImageLabel", { BackgroundTransparency=1, BorderSizePixel=0, ImageTransparency=1, ZIndex=3, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromScale(1,1), Parent=avatarHolder }); corner(avatar, 14)
local avatarScale = new("UIScale", { Scale=1, Parent=avatarHolder }); setAvatar(avatar, LocalPlayer.UserId, 150)
text({ Text=LocalPlayer.DisplayName, TextSize=10, TextColor3=T.Sub, ZIndex=2, Position=UDim2.fromOffset(36,4), Size=UDim2.new(1,-38,0,12), Parent=profile })
local statusDot = new("Frame", { BackgroundColor3=T.Good, BorderSizePixel=0, ZIndex=2, Position=UDim2.fromOffset(36,19), Size=UDim2.fromOffset(5,5), Parent=profile }); corner(statusDot, 3)
local clockLabel = text({ Text="--:--", TextSize=9, TextColor3=T.Dim, ZIndex=2, Position=UDim2.fromOffset(45,15), Size=UDim2.new(1,-46,0,12), Parent=profile })

-- ── контент ──
local content = new("Frame", { Name="Content", BackgroundTransparency=1, ZIndex=2, Position=UDim2.fromOffset(SIDE_W,0), Size=UDim2.new(1,-SIDE_W,1,0), Parent=panel })
local pageTitle = text({ Text="Main", Font=Enum.Font.GothamBold, TextSize=13, ZIndex=3, Position=UDim2.fromOffset(14,9), Size=UDim2.fromOffset(130,16), Parent=content })
local pageSub = text({ Text="", TextSize=9, TextColor3=T.Dim, ZIndex=3, Position=UDim2.fromOffset(14,25), Size=UDim2.fromOffset(150,12), Parent=content })

local SEARCH_W = 118
local searchBox = new("Frame", { BackgroundColor3=T.Bg, BackgroundTransparency=0.35, BorderSizePixel=0, ZIndex=3, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-84,0,23), Size=UDim2.fromOffset(SEARCH_W,24), Parent=content }); corner(searchBox, 8)
local searchStroke = stroke(searchBox, 0.9, 1)
local _, searchRecolor = icon("search", searchBox, T.Dim, UDim2.fromOffset(8,5))
local searchInput = new("TextBox", { BackgroundTransparency=1, Text="", PlaceholderText="Search · Ctrl+F", PlaceholderColor3=T.Dim, TextColor3=T.Text, Font=Enum.Font.GothamMedium, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false, ZIndex=2, Position=UDim2.fromOffset(26,0), Size=UDim2.new(1,-46,1,0), Parent=searchBox })
local searchCount = text({ Text="", TextSize=9, TextColor3=T.Dim, TextXAlignment=Enum.TextXAlignment.Right, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-8,0.5,0), Size=UDim2.fromOffset(22,12), ZIndex=2, Parent=searchBox })
local searchClear = new("TextButton", { Text="", AutoButtonColor=false, BackgroundTransparency=1, BorderSizePixel=0, ZIndex=3, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-6,0.5,0), Size=UDim2.fromOffset(14,14), Visible=false, Parent=searchBox })
local _, searchClearRecolor = icon("close", searchClear, T.Dim, UDim2.fromOffset(0,0))

local function headBtn(x, kind)
	local b = new("TextButton", { Text="", AutoButtonColor=false, BackgroundColor3=T.White, BackgroundTransparency=1, BorderSizePixel=0, ZIndex=3, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,x,0,23), Size=UDim2.fromOffset(20,20), Parent=content }); corner(b, 6)
	local box, recolor = icon(kind, b, T.Dim, UDim2.fromOffset(3,3)); local sc = new("UIScale", { Scale=1, Parent=b }); local spin = (kind == "close" or kind == "spark")
	connect(b.MouseEnter, function() tween(b,0.18,nil,nil,{BackgroundTransparency=0.9}); recolor(T.Text); tween(sc,0.25,Enum.EasingStyle.Back,nil,{Scale=1.12}); if spin then tween(box,0.35,Enum.EasingStyle.Quint,nil,{Rotation=90}) end end)
	connect(b.MouseLeave, function() tween(b,0.22,nil,nil,{BackgroundTransparency=1}); recolor(T.Dim); tween(sc,0.3,nil,nil,{Scale=1}); if spin then tween(box,0.4,Enum.EasingStyle.Quint,nil,{Rotation=0}) end end)
	return b, box
end
local paletteBtn = headBtn(-58, "spark"); local miniBtn, miniIcon = headBtn(-34, "minus"); local closeBtn = headBtn(-10, "close")
new("Frame", { BackgroundColor3=T.White, BackgroundTransparency=0.93, BorderSizePixel=0, Position=UDim2.fromOffset(14,46), Size=UDim2.new(1,-28,0,1), Parent=content })
local pagesBox = new("Frame", { BackgroundTransparency=1, ClipsDescendants=true, Position=UDim2.fromOffset(0,50), Size=UDim2.new(1,0,1,-74), Parent=content })

local topMask, bottomMask
do
	local function fadeMask(pos, size, rot) local f = new("Frame", { BackgroundColor3=T.Panel, BackgroundTransparency=0.25, BorderSizePixel=0, ZIndex=6, Position=pos, Size=size, Parent=content }); new("UIGradient", { Rotation=rot, Transparency=NumberSequence.new({ NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1) }), Parent=f }); return f end
	topMask = fadeMask(UDim2.fromOffset(0,50), UDim2.new(1,0,0,10), 90); bottomMask = fadeMask(UDim2.new(0,0,1,-34), UDim2.new(1,0,0,10), -90)
end

local footer = new("CanvasGroup", { BackgroundTransparency=1, GroupTransparency=0, AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,0,1,0), Size=UDim2.new(1,0,0,24), Parent=content })
local keyHint = text({ Text="", TextSize=9, TextColor3=T.Dim, Position=UDim2.fromOffset(14,0), Size=UDim2.new(1,-196,1,0), Parent=footer })
local pingLabel = text({ Text="0 ms", TextSize=9, TextColor3=T.Dim, TextXAlignment=Enum.TextXAlignment.Right, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-120,0,0), Size=UDim2.fromOffset(48,24), Parent=footer })
local sparkBox = new("Frame", { BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-64,0.5,0), Size=UDim2.fromOffset(47,12), Parent=footer })
local sparkBars = {}
for i = 1, 16 do local b = new("Frame", { BackgroundColor3=ACCENT, BackgroundTransparency=0.35, BorderSizePixel=0, AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,(i-1)*3,1,0), Size=UDim2.fromOffset(2,3), Parent=sparkBox }); corner(b, 1); sparkBars[i] = b; accent(function(c) tween(b, 0.35, nil, nil, { BackgroundColor3=c }) end) end
local fpsLabel = text({ Text="60 fps", TextSize=9, TextColor3=T.Dim, TextXAlignment=Enum.TextXAlignment.Right, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-14,0,0), Size=UDim2.fromOffset(46,24), Parent=footer })

local grip = new("TextButton", { Text="", AutoButtonColor=false, BackgroundTransparency=1, ZIndex=9, AnchorPoint=Vector2.new(1,1), Position=UDim2.new(1,-2,1,-2), Size=UDim2.fromOffset(16,16), Parent=panel })
for i = 1, 3 do local l = new("Frame", { BackgroundColor3=T.Dim, BackgroundTransparency=0.4, BorderSizePixel=0, AnchorPoint=Vector2.new(1,1), Position=UDim2.new(1,-2,1,-2-(i-1)*4), Size=UDim2.fromOffset(3+(i-1)*4,1.4), Rotation=-45, Parent=grip }); corner(l, 1) end

local blur = new("BlurEffect", { Name="RufuBlur", Size=0, Parent=Lighting })
local cc = new("ColorCorrectionEffect", { Name="RufuDim", Brightness=0, Saturation=0, Contrast=0, Parent=Lighting })

local toastBox = new("Frame", { Name="Toasts", BackgroundTransparency=1, AnchorPoint=Vector2.new(1,1), Position=UDim2.new(1,-18,1,-18), Size=UDim2.fromOffset(252,320), ZIndex=20, Parent=gui })
new("UIListLayout", { Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder, VerticalAlignment=Enum.VerticalAlignment.Bottom, HorizontalAlignment=Enum.HorizontalAlignment.Right, Parent=toastBox })

local tooltip = new("CanvasGroup", { Name="Tooltip", BackgroundColor3=T.Bg, BackgroundTransparency=0.08, BorderSizePixel=0, GroupTransparency=1, Visible=false, ZIndex=40, AutomaticSize=Enum.AutomaticSize.X, Size=UDim2.fromOffset(0,22), Parent=gui }); corner(tooltip, 6); stroke(tooltip, 0.82, 1); pad(tooltip, 8, 8, 0, 0)
local tooltipText = text({ Text="", TextSize=10, TextColor3=T.Sub, AutomaticSize=Enum.AutomaticSize.X, TextTruncate=Enum.TextTruncate.None, Size=UDim2.fromOffset(0,22), Parent=tooltip })

local watermark = new("CanvasGroup", { Name="Watermark", BackgroundColor3=T.Panel, BackgroundTransparency=0.18, BorderSizePixel=0, GroupTransparency=1, AutomaticSize=Enum.AutomaticSize.X, Size=UDim2.fromOffset(0,26), Position=UDim2.fromOffset(18,18), ZIndex=15, Parent=gui }); corner(watermark, 8); stroke(watermark, 0.85, 1); pad(watermark, 8, 10, 0, 0)
new("UIListLayout", { FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,7), SortOrder=Enum.SortOrder.LayoutOrder, VerticalAlignment=Enum.VerticalAlignment.Center, Parent=watermark })
local wmFps, wmPing, wmTime
do
	local wmAH = new("Frame", { BackgroundColor3=T.Card, BackgroundTransparency=0.3, BorderSizePixel=0, Size=UDim2.fromOffset(18,18), LayoutOrder=1, Parent=watermark }); corner(wmAH, 9)
	local wmA = new("ImageLabel", { BackgroundTransparency=1, ImageTransparency=1, Size=UDim2.fromScale(1,1), Parent=wmAH }); corner(wmA, 9); setAvatar(wmA, LocalPlayer.UserId, 48)
	local function wl(o,s,c,w) return text({ Text=s, TextSize=10, TextColor3=c or T.Sub, LayoutOrder=o, Size=UDim2.fromOffset(w or 40,26), Parent=watermark }) end
	local wn = wl(2, CONFIG.Title, T.Text, 34); wn.Font = Enum.Font.GothamBold
	wmFps = wl(4, "60 fps", T.Sub, 44); wmPing = wl(6, "0 ms", T.Sub, 42); wmTime = wl(8, "--:--:--", T.Dim, 48)
	local function wd(o) local d = new("Frame", { BackgroundColor3=ACCENT, BackgroundTransparency=0.3, BorderSizePixel=0, Size=UDim2.fromOffset(3,3), LayoutOrder=o, Parent=watermark }); corner(d, 2); accent(function(c) tween(d, 0.35, nil, nil, { BackgroundColor3=c }) end) end
	wd(3); wd(5); wd(7)
end

local bindHud = new("CanvasGroup", { Name="BindHud", BackgroundColor3=T.Panel, BackgroundTransparency=0.22, BorderSizePixel=0, GroupTransparency=1, AutomaticSize=Enum.AutomaticSize.Y, Size=UDim2.fromOffset(150,0), AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,18,0.5,0), ZIndex=15, Parent=gui }); corner(bindHud, 9); stroke(bindHud, 0.86, 1); pad(bindHud, 10, 10, 8, 8)
new("UIListLayout", { Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder, Parent=bindHud })
local bindHudTitle = text({ Text="KEYBINDS", TextSize=8, Font=Enum.Font.GothamBold, TextColor3=T.Dim, LayoutOrder=0, Size=UDim2.new(1,0,0,12), Parent=bindHud })

local touchBtn
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	touchBtn = new("TextButton", { Text="", AutoButtonColor=false, BackgroundColor3=T.Panel, BackgroundTransparency=0.15, BorderSizePixel=0, AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,18,1,-80), Size=UDim2.fromOffset(44,44), ZIndex=18, Parent=gui }); corner(touchBtn, 22); stroke(touchBtn, 0.8, 1.2, ACCENT)
	local tl = new("Frame", { BackgroundColor3=ACCENT, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(16,16), Parent=touchBtn }); corner(tl, 5); new("UIGradient", { Rotation=45, Color=ColorSequence.new(ACCENT, ACCENT2), Parent=tl })
end

local palette = new("CanvasGroup", { Name="Palette", BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=0.45, GroupTransparency=1, Visible=false, ZIndex=30, Size=UDim2.fromScale(1,1), Parent=panel })
local palBox = new("Frame", { BackgroundColor3=T.Panel, BackgroundTransparency=0.04, BorderSizePixel=0, ZIndex=2, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(320,224), Parent=palette }); corner(palBox, 12); stroke(palBox, 0.8, 1.2)
local palScale = new("UIScale", { Scale=0.94, Parent=palBox })
local palHead = new("Frame", { BackgroundColor3=T.Bg, BackgroundTransparency=0.35, BorderSizePixel=0, Position=UDim2.fromOffset(10,10), Size=UDim2.new(1,-20,0,28), Parent=palBox }); corner(palHead, 8)
local palStroke = stroke(palHead, 0.7, 1, ACCENT); accent(function(c) tween(palStroke, 0.35, nil, nil, { Color=c }) end)
icon("spark", palHead, ACCENT, UDim2.fromOffset(9,7))
local palInput = new("TextBox", { BackgroundTransparency=1, Text="", PlaceholderText="Найти контрол или действие...", PlaceholderColor3=T.Dim, TextColor3=T.Text, Font=Enum.Font.GothamMedium, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false, Position=UDim2.fromOffset(30,0), Size=UDim2.new(1,-40,1,0), Parent=palHead })
local palList = new("ScrollingFrame", { BackgroundTransparency=1, BorderSizePixel=0, Position=UDim2.fromOffset(10,46), Size=UDim2.new(1,-20,1,-74), CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarThickness=2, ScrollBarImageColor3=T.White, ScrollBarImageTransparency=0.85, ScrollingDirection=Enum.ScrollingDirection.Y, Parent=palBox })
new("UIListLayout", { Padding=UDim.new(0,3), SortOrder=Enum.SortOrder.LayoutOrder, Parent=palList })
text({ Text="↑↓ выбор   Enter выполнить   Esc закрыть", TextSize=9, TextColor3=T.Dim, AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,12,1,-8), Size=UDim2.new(1,-24,0,14), Parent=palBox })

-- ══════════════════════════ СОСТОЯНИЕ ══════════════════════════
local Window = { Flags = {}, Tabs = {}, _open = false }; _G.__RufuUI = Window
local userScale, baseScale = CONFIG.Scale, CONFIG.Scale
local targetPos, curPos = Vector2.new(0,0), Vector2.new(0,0)
local dragging, moved, resizing, minimized = false, false, false, false
local dragStartInput, dragStartPos, resizeStart, resizeStartSize = nil, nil, nil, nil
local renderConn, camConn = nil, nil
local activeTab, listening = nil, nil
local binds, controls, byFlag = {}, {}, {}
local paletteOpen, palIndex, palItems = false, 1, {}
local saveQueued = false
local cursorGlow, cursorGlowTarget = 0.5, 0.5
local wmDrag, wmStart, wmStartPos = false, nil, nil
local applyRowState, updateDeps, stagger, refreshBindHud, renderPalette, queueAutoSave
local openPalette, closePalette, focusControl

local function viewport() local c = workspace.CurrentCamera; return c and c.ViewportSize or Vector2.new(1280,720) end
local function centerPanel() local v = viewport(); targetPos = Vector2.new(v.X*0.5, v.Y*0.5) end
local function responsive() local v = viewport(); return clamp(math.min(v.X/1440, v.Y/900), 0.78, 1.1) end
local function panelHeight() return minimized and 46 or H end
local function clickSound(f) if not CONFIG.Sounds then return end local s = Instance.new("Sound"); s.SoundId="rbxasset://sounds/electronicpingshort.wav"; s.Volume=0.22; s.PlaybackSpeed=f or 1.4; s.Parent=gui; s:Play(); Debris:AddItem(s,1) end
local function ripple(obj, color) local r = new("Frame", { BackgroundColor3=color or T.White, BackgroundTransparency=0.86, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(0,0), ZIndex=0, Parent=obj }); corner(r, 999); local d = math.max(obj.AbsoluteSize.X, obj.AbsoluteSize.Y)*1.5; tween(r, 0.5, Enum.EasingStyle.Quint, nil, { Size=UDim2.fromOffset(d,d), BackgroundTransparency=1 }); Debris:AddItem(r, 0.55) end
local function shake(obj, amt) local base = obj.Position; task.spawn(function() for i=1,4 do local off=(i%2==0) and -(amt or 4) or (amt or 4); tween(obj, 0.05, Enum.EasingStyle.Quad, nil, { Position=base+UDim2.fromOffset(off,0) }); task.wait(0.05) end; tween(obj, 0.12, Enum.EasingStyle.Quad, nil, { Position=base }) end) end
local function hoverize(card, b, h) connect(card.MouseEnter, function() tween(card, 0.18, Enum.EasingStyle.Quad, nil, { BackgroundTransparency=h }) end); connect(card.MouseLeave, function() tween(card, 0.22, Enum.EasingStyle.Quad, nil, { BackgroundTransparency=b }) end) end

-- ══════════════════════════ ТОСТЫ ══════════════════════════
do
	local KIND = { info="info", good="check", warn="warn", bad="close" }
	local function kindColor(k) if k=="good" then return T.Good elseif k=="warn" then return T.Warn elseif k=="bad" then return T.Bad end return ACCENT end
	function Window:Notify(msg, sub, kind, time)
		if Window._loading then return end
		kind = kind or "info"; local col, total = kindColor(kind), time or 3.2
		local kids, count = toastBox:GetChildren(), 0; for _, k in ipairs(kids) do if k:IsA("GuiObject") then count+=1 end end
		if count >= 5 then for _, k in ipairs(kids) do if k:IsA("GuiObject") then k:Destroy(); break end end end
		local wrap = new("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0, sub and 42 or 34), Parent=toastBox })
		local t = new("CanvasGroup", { BackgroundColor3=T.Panel, BackgroundTransparency=0.08, BorderSizePixel=0, GroupTransparency=1, Active=true, Size=UDim2.fromScale(1,1), Position=UDim2.fromOffset(30,0), Parent=wrap }); corner(t, 10); stroke(t, 0.84, 1)
		local bar = new("Frame", { BackgroundColor3=col, BorderSizePixel=0, AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,0,1,0), Size=UDim2.new(1,0,0,2), Parent=t })
		local ib = icon(KIND[kind] or "info", t, col, UDim2.fromOffset(12, sub and 13 or 10))
		text({ Text=msg, TextSize=11, Position=UDim2.fromOffset(32, sub and 8 or 0), Size=UDim2.new(1,-44,0, sub and 14 or 34), Parent=t })
		if sub then text({ Text=sub, TextSize=9, TextColor3=T.Dim, Position=UDim2.fromOffset(32,23), Size=UDim2.new(1,-44,0,12), Parent=t }) end
		local hit = new("TextButton", { Text="", AutoButtonColor=false, BackgroundTransparency=1, Size=UDim2.fromScale(1,1), ZIndex=5, Parent=t })
		tween(t, 0.45, Enum.EasingStyle.Back, nil, { Position=UDim2.fromOffset(0,0) }); tween(t, 0.25, nil, nil, { GroupTransparency=0 }); ib.Rotation=-35; tween(ib, 0.5, Enum.EasingStyle.Back, nil, { Rotation=0 })
		local paused, dead = false, false
		connect(hit.MouseEnter, function() paused=true; tween(t, 0.2, nil, nil, { BackgroundTransparency=0.02 }) end)
		connect(hit.MouseLeave, function() paused=false; tween(t, 0.2, nil, nil, { BackgroundTransparency=0.08 }) end)
		local function kill() if dead then return end dead=true; tween(t, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { GroupTransparency=1, Position=UDim2.fromOffset(30,0) }); task.delay(0.26, function() wrap:Destroy() end) end
		connect(hit.MouseButton1Click, kill)
		task.spawn(function() local life=0; while life<total and not dead and wrap.Parent do task.wait(0.05); if not paused then life+=0.05; bar.Size=UDim2.new(clamp(1-life/total,0,1),0,0,2) end end; kill() end)
		clickSound(1.5); return t
	end
end

-- ══════════════════════════ ТУЛТИПЫ ══════════════════════════
local hideTooltip, showTooltip, attachTooltip
do
	local tok = 0
	hideTooltip = function() tok+=1; tween(tooltip, 0.15, nil, nil, { GroupTransparency=1 }); task.delay(0.18, function() if tooltip.GroupTransparency>0.95 then tooltip.Visible=false end end) end
	showTooltip = function(s) tok+=1; local my=tok; task.delay(0.42, function() if my~=tok then return end; tooltipText.Text=s; tooltip.Visible=true; tooltip.GroupTransparency=1; tween(tooltip, 0.2, nil, nil, { GroupTransparency=0 }) end) end
	attachTooltip = function(o, tip) if not tip then return end; connect(o.MouseEnter, function() showTooltip(tip) end); connect(o.MouseLeave, hideTooltip) end
	attachTooltip(paletteBtn, "Командная палитра · Ctrl+K"); attachTooltip(miniBtn, "Свернуть окно"); attachTooltip(closeBtn, "Закрыть · RightShift")
	attachTooltip(logoBtn, "Сменить акцент"); attachTooltip(avatarHolder, LocalPlayer.Name.." · id "..LocalPlayer.UserId); attachTooltip(grip, "Тяни, чтобы изменить размер")
end

-- ══════════════════════════ ТЕМА / МАСШТАБ (ФИКС БАГА ФОНА) ══════════════════════════
function Window:SetAccent(c1, c2)
	ACCENT, ACCENT2 = c1, c2 or c1
	
	-- Генерируем темные оттенки для фона
	local h, s, v = Color3.toHSV(ACCENT)
	local darkPanel = Color3.fromHSV(h, clamp(s * 0.4, 0, 1), 0.12)
	local darkSide = Color3.fromHSV(h, clamp(s * 0.5, 0, 1), 0.09)
	
	-- Красим основные фоны
	tween(panel, 0.4, nil, nil, { BackgroundColor3 = darkPanel })
	tween(side, 0.4, nil, nil, { BackgroundColor3 = darkSide })
	tween(pill, 0.4, nil, nil, { BackgroundColor3 = Color3.fromHSV(h, clamp(s * 0.5, 0, 1), 0.25) })
	
	for _, fn in ipairs(accentSetters) do fn(ACCENT) end
	logoGrad.Color = ColorSequence.new(ACCENT, ACCENT2)
end

function Window:SetGlass(v) for _, fn in ipairs(glassSetters) do fn(v) end end
function Window:SetScale(s) userScale = s; baseScale = userScale * responsive(); tween(uiScale, 0.3, nil, nil, { Scale=baseScale }) end

-- ══════════════════════════ РЕЕСТР ══════════════════════════
local function register(e) controls[#controls+1] = e; if e.flag then byFlag[e.flag] = e end; return e end
applyRowState = function(e, inst)
	local vis = (e.match~=false) and (e.depOK~=false) and (e.secOK~=false); local h = vis and (e.rowHeight or 34) or 0
	if e._vis==vis and e._h==h and not inst then return end
	e._vis, e._h = vis, h
	if inst then e.holder.Visible=vis; e.holder.Size=UDim2.new(1,0,0,h); e.holder.GroupTransparency=vis and 0 or 1; return end
	if vis then e.holder.Visible=true; tween(e.holder, 0.32, Enum.EasingStyle.Quint, nil, { Size=UDim2.new(1,0,0,h), GroupTransparency=0 })
	else tween(e.holder, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Size=UDim2.new(1,0,0,0), GroupTransparency=1 }); task.delay(0.24, function() if not e._vis and e.holder.Parent then e.holder.Visible=false end end) end
end
updateDeps = function()
	for _, e in ipairs(controls) do if e.dep then
		local src = byFlag[e.dep.Flag]; local ok = true
		if src then local v = Window.Flags[e.dep.Flag]; if e.dep.Value~=nil then ok=(v==e.dep.Value) elseif e.dep.Not~=nil then ok=(v~=e.dep.Not) else ok=v and true or false end end
		e.depOK = ok; applyRowState(e)
	end end
end
stagger = function(page)
	if not page or Anim.off then return end
	local i = 0
	for _, holder in ipairs(page.scroll:GetChildren()) do if holder:IsA("GuiObject") and holder.Visible then local card = holder:FindFirstChild("Card"); if card then card.Position=UDim2.fromOffset(0,14); tween(card, 0.36+i*0.012, Enum.EasingStyle.Quint, nil, { Position=UDim2.fromOffset(0,0) }); i+=1 end end end
end
local function changed(e) if e and e.flag then updateDeps(); queueAutoSave() end; refreshBindHud() end

-- ══════════════════════════ HUD ══════════════════════════
do
	local bindRows = {}
	refreshBindHud = function()
		if not CONFIG.BindHud then return end
		for _, r in pairs(bindRows) do r:Destroy() end; bindRows = {}
		local n = 0
		for _, b in ipairs(binds) do local k = b.get(); if k and b.name then
			n += 1
			local row = new("Frame", { BackgroundTransparency=1, LayoutOrder=n, Size=UDim2.new(1,0,0,16), Parent=bindHud })
			text({ Text=string.upper(tostring(k.Name)), TextSize=9, Font=Enum.Font.GothamBold, TextColor3=ACCENT, TextXAlignment=Enum.TextXAlignment.Right, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,0,0,0), Size=UDim2.fromOffset(46,16), Parent=row })
			text({ Text=b.name, TextSize=9, TextColor3=(b.state and T.Text or T.Sub), Size=UDim2.new(1,-50,1,0), Parent=row })
			bindRows[#bindRows+1] = row
			if b.state then local d = new("Frame", { BackgroundColor3=T.Good, BorderSizePixel=0, AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,-6,0.5,0), Size=UDim2.fromOffset(3,3), Parent=row }); corner(d, 2) end
		end end
		bindHudTitle.Visible = n > 0
		tween(bindHud, 0.3, nil, nil, { GroupTransparency=(CONFIG.BindHud and n>0) and 0 or 1 })
	end
end

-- ══════════════════════════ ПАЛИТРА ══════════════════════════
local palActions = {}
local function addAction(name, hint, fn) palActions[#palActions+1] = { name=name, hint=hint or "действие", run=fn } end
local function palSelect(i)
	palIndex = clamp(i, 1, math.max(#palItems, 1))
	for idx, it in ipairs(palItems) do
		local on = (idx==palIndex)
		tween(it.row, 0.18, nil, nil, { BackgroundTransparency=on and 0.55 or 1 }); tween(it.label, 0.18, nil, nil, { TextColor3=on and T.Text or T.Sub }); tween(it.bar, 0.2, nil, nil, { BackgroundTransparency=on and 0 or 1 })
		if on then local y = it.row.AbsolutePosition.Y-palList.AbsolutePosition.Y+palList.CanvasPosition.Y; local h = palList.AbsoluteSize.Y
			if y<palList.CanvasPosition.Y then tween(palList, 0.25, nil, nil, { CanvasPosition=Vector2.new(0, math.max(0,y-4)) }) elseif y+26>palList.CanvasPosition.Y+h then tween(palList, 0.25, nil, nil, { CanvasPosition=Vector2.new(0,y+26-h+4) }) end
		end
	end
end
renderPalette = function(q)
	q = string.lower(q or "")
	for _, c in ipairs(palList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	palItems = {}
	local function push(item)
		local i = #palItems+1
		local wrap = new("Frame", { BackgroundTransparency=1, LayoutOrder=i, Size=UDim2.new(1,0,0,26), Parent=palList })
		local row = new("TextButton", { Text="", AutoButtonColor=false, BackgroundColor3=T.Card, BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.fromScale(1,1), Parent=wrap }); corner(row, 7)
		local bar = new("Frame", { BackgroundColor3=ACCENT, BackgroundTransparency=1, BorderSizePixel=0, AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,0,0.5,0), Size=UDim2.fromOffset(2,14), Parent=row }); corner(bar, 1)
		local label = text({ Text=item.name, TextSize=10, TextColor3=T.Sub, Position=UDim2.fromOffset(10,0), Size=UDim2.new(1,-90,1,0), Parent=row })
		text({ Text=item.hint, TextSize=9, TextColor3=T.Dim, TextXAlignment=Enum.TextXAlignment.Right, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-10,0,0), Size=UDim2.fromOffset(76,26), Parent=row })
		item.row, item.label, item.bar = row, label, bar; palItems[i] = item
		connect(row.MouseEnter, function() palSelect(i) end)
		connect(row.MouseButton1Click, function() ripple(row, ACCENT); clickSound(1.6); task.spawn(item.run) end)
		row.Position = UDim2.fromOffset(0,8); tween(row, 0.28+i*0.012, Enum.EasingStyle.Quint, nil, { Position=UDim2.fromOffset(0,0) })
	end
	for _, a in ipairs(palActions) do if q=="" or string.find(string.lower(a.name), q, 1, true) then push(a) end end
	for _, e in ipairs(controls) do
		if e.flag and e.name and (q=="" or string.find(string.lower(e.name.." "..(e.tabName or "")), q, 1, true)) then
			push({ name=e.name, hint=(e.tabName or "").." · "..e.kind, run=function()
				closePalette()
				if e.kind=="toggle" then e.set(not e.get()); Window:Notify(e.name, e.get() and "включено" or "выключено", e.get() and "good" or "info", 1.8)
				elseif e.kind=="button" then e.set()
				else focusControl(e) end
			end })
		end
	end
	palList.CanvasPosition = Vector2.new(0,0); palSelect(1)
end
openPalette = function()
	if paletteOpen then return end; paletteOpen = true
	if not Window._open then Window:Open() end
	palette.Visible = true; palScale.Scale = 0.94; palBox.Position = UDim2.new(0.5,0,0.5,10)
	tween(palette, 0.2, nil, nil, { GroupTransparency=0 }); tween(palScale, 0.4, Enum.EasingStyle.Back, nil, { Scale=1 }); tween(palBox, 0.4, Enum.EasingStyle.Quint, nil, { Position=UDim2.new(0.5,0,0.5,0) })
	renderPalette(""); palInput.Text = ""; task.defer(function() palInput:CaptureFocus() end); clickSound(1.7)
end
closePalette = function()
	if not paletteOpen then return end; paletteOpen = false; palInput:ReleaseFocus()
	tween(palette, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { GroupTransparency=1 }); tween(palScale, 0.2, nil, nil, { Scale=0.96 })
	task.delay(0.2, function() if not paletteOpen then palette.Visible=false end end)
end
focusControl = function(e)
	if not e then return end
	if e.tab then Window:SelectTab(e.tab) end
	if not Window._open then Window:Open() end
	task.delay(0.18, function()
		local scroll = e.tab and e.tab.scroll; if not scroll or not e.holder.Parent then return end
		local y = e.holder.AbsolutePosition.Y-scroll.AbsolutePosition.Y+scroll.CanvasPosition.Y
		tween(scroll, 0.4, Enum.EasingStyle.Quint, nil, { CanvasPosition=Vector2.new(0, math.max(0,y-20)) })
		local card = e.holder:FindFirstChild("Card")
		if card then local st = card:FindFirstChildOfClass("UIStroke"); tween(card, 0.2, nil, nil, { BackgroundTransparency=0.2 })
			if st then st.Color=ACCENT; tween(st, 0.2, nil, nil, { Transparency=0.2 }); task.delay(0.7, function() tween(st, 0.5, nil, nil, { Transparency=0.93, Color=T.White }) end) end
			task.delay(0.7, function() tween(card, 0.5, nil, nil, { BackgroundTransparency=0.55 }) end)
		end
	end)
end
Window.FocusControl = function(self, e) focusControl(e) end

-- ══════════════════════════ КОНФИГИ ══════════════════════════
local function toHex(c) return string.format("#%02X%02X%02X", round(c.R*255), round(c.G*255), round(c.B*255)) end
local function fromHex(h) if typeof(h)~="string" then return nil end local r,g,b = string.match(h, "#?(%x%x)(%x%x)(%x%x)"); if not r then return nil end return Color3.fromRGB(tonumber(r,16), tonumber(g,16), tonumber(b,16)) end
Window.ToHex, Window.FromHex = toHex, fromHex

function Window:GetConfig()
	local flags = {}
	for _, e in ipairs(controls) do if e.flag and e.serialize then local ok, v = pcall(e.serialize); if ok then flags[e.flag] = v end end end
	return { name=CONFIG.Title, version=CONFIG.Version, flags=flags, ui={ x=targetPos.X, y=targetPos.Y, w=W, h=H, moved=moved, scale=userScale, accent=toHex(ACCENT), accent2=toHex(ACCENT2), blur=CONFIG.Blur, sounds=CONFIG.Sounds, watermark=CONFIG.Watermark, bindhud=CONFIG.BindHud, motion=Anim.mul, reduce=Anim.off } }
end
function Window:ApplyConfig(data)
	if typeof(data)~="table" then return false end
	Window._loading = true; local n = 0
	if typeof(data.flags)=="table" then for flag, v in pairs(data.flags) do local e = byFlag[flag]; if e and e.deserialize then if pcall(e.deserialize, v) then n+=1 end end end end
	local ui = data.ui
	if typeof(ui)=="table" then
		if ui.accent then local c1, c2 = fromHex(ui.accent), fromHex(ui.accent2 or ui.accent); if c1 then Window:SetAccent(c1, c2) end end
		if tonumber(ui.w) and tonumber(ui.h) then W=clamp(tonumber(ui.w), CONFIG.MinSize.X, CONFIG.MaxSize.X); H=clamp(tonumber(ui.h), CONFIG.MinSize.Y, CONFIG.MaxSize.Y); panel.Size=UDim2.fromOffset(W,H); layoutShadows(H,true) end
		if tonumber(ui.scale) then Window:SetScale(clamp(tonumber(ui.scale), 0.7, 1.4)) end
		if ui.moved and tonumber(ui.x) and tonumber(ui.y) then moved=true; targetPos=Vector2.new(ui.x, ui.y); curPos=targetPos end
		if tonumber(ui.blur) then CONFIG.Blur=clamp(tonumber(ui.blur), 0, 24) end
		if ui.sounds~=nil then CONFIG.Sounds=ui.sounds and true or false end
		if ui.watermark~=nil then CONFIG.Watermark=ui.watermark and true or false end
		if ui.bindhud~=nil then CONFIG.BindHud=ui.bindhud and true or false end
		if tonumber(ui.motion) then Anim.mul=clamp(tonumber(ui.motion), 0.25, 2) end
	end
	updateDeps(); refreshBindHud(); tween(watermark, 0.3, nil, nil, { GroupTransparency=CONFIG.Watermark and 0 or 1 })
	Window._loading = false; return true, n
end
function Window:SaveConfig(name)
	name = (name and name~="") and name or "default"
	local ok, json = pcall(function() return HttpService:JSONEncode(Window:GetConfig()) end)
	if not ok then Window:Notify("Не удалось сериализовать", tostring(json), "bad"); return false end
	local disk = FS.write(name, json); Window:Notify("Конфиг сохранён", name..(disk and " · файл" or " · память"), "good"); return true
end
function Window:LoadConfig(name)
	name = (name and name~="") and name or "default"
	local raw = FS.read(name); if not raw then Window:Notify("Конфиг не найден", name, "warn"); return false end
	local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok or typeof(data)~="table" then Window:Notify("Битый конфиг", name, "bad"); return false end
	local _, n = Window:ApplyConfig(data); Window:Notify("Конфиг загружен", name.." · "..tostring(n or 0).." значений", "good"); return true
end
function Window:ExportConfig()
	local ok, json = pcall(function() return HttpService:JSONEncode(Window:GetConfig()) end); if not ok then return "" end
	if isfn(setclipboard) then pcall(function() setclipboard(json) end); Window:Notify("Скопировано в буфер", #json.." байт", "good") else print("[RUFU] config:\n"..json); Window:Notify("Конфиг в консоли (F9)", #json.." байт", "info") end
	return json
end
function Window:ImportConfig(str)
	if typeof(str)~="string" or str=="" then Window:Notify("Пустая строка импорта", nil, "warn"); return false end
	local ok, data = pcall(function() return HttpService:JSONDecode(str) end)
	if not ok or typeof(data)~="table" then Window:Notify("Неверный JSON", nil, "bad"); return false end
	Window:ApplyConfig(data); Window:Notify("Конфиг импортирован", nil, "good"); return true
end
function Window:ResetDefaults() for _, e in ipairs(controls) do if e.flag and e.reset then pcall(e.reset) end end; updateDeps(); Window:Notify("Значения сброшены", "по умолчанию", "warn") end
queueAutoSave = function()
	if not CONFIG.AutoSave or saveQueued or Window._loading then return end
	saveQueued = true
	task.delay(1.5, function() saveQueued=false; if not CONFIG.AutoSave then return end; local ok, json = pcall(function() return HttpService:JSONEncode(Window:GetConfig()) end); if ok then FS.write("autosave", json) end end)
end

-- ══════════════════════════ ЦИКЛ / ОКНО ══════════════════════════
local function startLoop()
	if renderConn then return end
	local acc, frames, sparkAcc, slowAcc = 0, 0, 0, 0; local fps = 60
	renderConn = connect(RunService.RenderStepped, function(dt)
		if dragging and dragStartInput then
			local m = UserInputService:GetMouseLocation(); local v = viewport(); local half = Vector2.new(W, panelHeight())*0.5*uiScale.Scale
			targetPos = Vector2.new(clamp(dragStartPos.X+(m.X-dragStartInput.X), half.X+8, math.max(half.X+8, v.X-half.X-8)), clamp(dragStartPos.Y+(m.Y-dragStartInput.Y), half.Y+8, math.max(half.Y+8, v.Y-half.Y-8)))
		end
		if resizing and resizeStart then
			local m = UserInputService:GetMouseLocation(); local d = (m-resizeStart)/math.max(uiScale.Scale, 0.1)
			W = clamp(round(resizeStartSize.X+d.X), CONFIG.MinSize.X, CONFIG.MaxSize.X); H = clamp(round(resizeStartSize.Y+d.Y), CONFIG.MinSize.Y, CONFIG.MaxSize.Y)
			panel.Size = UDim2.fromOffset(W,H); layoutShadows(H,true)
		end
		if Window._open then
			local a = 1-math.exp(-dt*19); local prev = curPos; curPos = curPos:Lerp(targetPos, a)
			root.Position = UDim2.fromOffset(round(curPos.X), round(curPos.Y))
			local vel = (curPos.X-prev.X)/math.max(dt, 1/240); root.Rotation = lerp(root.Rotation, clamp(vel*0.004, -1.4, 1.4), 1-math.exp(-dt*10))
			local m = UserInputService:GetMouseLocation(); local rel = (m.X-panel.AbsolutePosition.X)/math.max(panel.AbsoluteSize.X, 1)
			cursorGlowTarget = clamp(rel, -0.5, 1.5); cursorGlow = lerp(cursorGlow, cursorGlowTarget, 1-math.exp(-dt*6)); sheenGrad.Offset = Vector2.new(cursorGlow-0.5, 0)
		end
		if tooltip.Visible then local m = UserInputService:GetMouseLocation(); local v = viewport(); tooltip.Position = UDim2.fromOffset(clamp(m.X+14, 4, v.X-tooltip.AbsoluteSize.X-4), clamp(m.Y+18, 4, v.Y-30)) end
		if wmDrag and wmStart then local m = UserInputService:GetMouseLocation(); watermark.Position = UDim2.fromOffset(wmStartPos.X+(m.X-wmStart.X), wmStartPos.Y+(m.Y-wmStart.Y)) end
		acc, frames = acc+dt, frames+1; sparkAcc += dt; slowAcc += dt
		if acc >= 0.5 then fps = round(frames/acc); fpsLabel.Text = fps.." fps"; wmFps.Text = fps.." fps"; acc, frames = 0, 0 end
		if sparkAcc >= 0.22 then sparkAcc = 0; for i=1,#sparkBars-1 do sparkBars[i].Size = sparkBars[i+1].Size end; local h = clamp(fps/120, 0.08, 1)*12; tween(sparkBars[#sparkBars], 0.2, Enum.EasingStyle.Quad, nil, { Size=UDim2.fromOffset(2,h) }) end
		if slowAcc >= 1 then
			slowAcc = 0; local t = os.date("*t")
			clockLabel.Text = string.format("%02d:%02d", t.hour, t.min); wmTime.Text = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
			local ping = 0; local okP = pcall(function() ping = round(LocalPlayer:GetNetworkPing()*1000) end)
			if not okP then pcall(function() ping = round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end) end
			pingLabel.Text = ping.." ms"; wmPing.Text = ping.." ms"
			tween(wmPing, 0.4, nil, nil, { TextColor3=(ping<90) and T.Good or ((ping<180) and T.Warn or T.Bad) })
		end
	end)
end
function Window:Open()
	if self._open then return end; self._open = true; root.Visible = true
	if self._firstOpen ~= false then self._firstOpen = false; for i,t in ipairs(self.Tabs) do local y = (i-1)*(TAB_H+TAB_GAP); t.btn.Position = UDim2.fromOffset(-16, y); task.delay(0.06+i*0.045, function() tween(t.btn, 0.45, Enum.EasingStyle.Quint, nil, { Position=UDim2.fromOffset(0,y) }) end) end end
	if not moved then centerPanel() end
	curPos = targetPos+Vector2.new(0,18); root.Rotation = 0; uiScale.Scale = baseScale*0.93; root.GroupTransparency = 1
	tween(uiScale, 0.45, Enum.EasingStyle.Back, nil, { Scale=baseScale }); tween(root, 0.26, Enum.EasingStyle.Quad, nil, { GroupTransparency=0 })
	tween(blur, 0.4, nil, nil, { Size=CONFIG.Blur }); tween(cc, 0.4, nil, nil, { Brightness=-CONFIG.Dim*0.35, Saturation=-CONFIG.Dim })
	stagger(activeTab); hideTooltip(); clickSound(1.6)
end
function Window:Close()
	if not self._open then return end; self._open = false; dragging, resizing = false, false; closePalette(); hideTooltip()
	tween(uiScale, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In, { Scale=baseScale*0.96 }); tween(root, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { GroupTransparency=1 })
	tween(blur, 0.3, nil, nil, { Size=0 }); tween(cc, 0.3, nil, nil, { Brightness=0, Saturation=0 }); clickSound(1.1)
	task.delay(0.24, function() if not Window._open then root.Visible=false end end)
end
function Window:Toggle() if self._open then self:Close() else self:Open() end end
function Window:SetMinimized(v)
	minimized = v and true or false; local h = panelHeight()
	tween(panel, 0.42, Enum.EasingStyle.Quint, nil, { Size=UDim2.fromOffset(W,h) }); layoutShadows(h)
	tween(footer, 0.22, nil, nil, { GroupTransparency=minimized and 1 or 0 }); tween(profile, 0.22, nil, nil, { GroupTransparency=minimized and 1 or 0 }); tween(tabsBox, 0.22, nil, nil, { GroupTransparency=minimized and 1 or 0 })
	tween(topMask, 0.22, nil, nil, { BackgroundTransparency=minimized and 1 or 0.25 }); tween(bottomMask, 0.22, nil, nil, { BackgroundTransparency=minimized and 1 or 0.25 })
	tween(miniIcon, 0.35, Enum.EasingStyle.Quint, nil, { Rotation=minimized and 180 or 0 })
	if minimized then task.delay(0.3, function() if minimized then pagesBox.Visible=false end end) else pagesBox.Visible=true; stagger(activeTab) end
	clickSound(minimized and 1.2 or 1.5)
end
function Window:SetWatermark(on) CONFIG.Watermark = on and true or false; tween(watermark, 0.3, nil, nil, { GroupTransparency=CONFIG.Watermark and 0 or 1 }) end
function Window:Destroy()
	if renderConn then renderConn:Disconnect(); renderConn=nil end
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end; table.clear(conns)
	gui:Destroy(); blur:Destroy(); cc:Destroy(); _G.__RufuUI = nil
end

-- ══════════════════════════ DRAG / RESIZE ══════════════════════════
connect(dragZone.InputBegan, function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true; dragStartInput=UserInputService:GetMouseLocation(); dragStartPos=targetPos; tween(uiScale, 0.25, nil, nil, { Scale=baseScale*1.015 }) end end)
connect(dragZone.MouseButton2Click, function() moved=false; centerPanel(); Window:Notify("Окно по центру", nil, "info", 1.4) end)
connect(grip.InputBegan, function(input) if minimized then return end; if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then resizing=true; resizeStart=UserInputService:GetMouseLocation(); resizeStartSize=Vector2.new(W,H); tween(panelStroke, 0.2, nil, nil, { Transparency=0.5, Color=ACCENT }) end end)
connect(grip.MouseEnter, function() tween(panelStroke, 0.2, nil, nil, { Transparency=0.72 }) end)
connect(grip.MouseLeave, function() if not resizing then tween(panelStroke, 0.25, nil, nil, { Transparency=0.86, Color=T.White }) end end)
connect(UserInputService.InputEnded, function(input)
	local m1 = input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch; if not m1 then return end
	if dragging then dragging=false; moved=true; tween(uiScale, 0.4, Enum.EasingStyle.Back, nil, { Scale=baseScale }); queueAutoSave() end
	if resizing then resizing=false; moved=true; tween(panelStroke, 0.3, nil, nil, { Transparency=0.86, Color=T.White }); queueAutoSave() end
	if wmDrag then wmDrag=false end
end)
local lastClick = 0
connect(dragZone.MouseButton1Click, function() local now = os.clock(); if now-lastClick < 0.32 then moved=false; centerPanel(); tween(uiScale, 0.4, Enum.EasingStyle.Back, nil, { Scale=baseScale }) end; lastClick=now end)
connect(closeBtn.MouseButton1Click, function() Window:Close() end)
connect(miniBtn.MouseButton1Click, function() Window:SetMinimized(not minimized) end)
connect(paletteBtn.MouseButton1Click, function() if paletteOpen then closePalette() else openPalette() end end)
connect(searchClear.MouseEnter, function() searchClearRecolor(T.Text) end)
connect(searchClear.MouseLeave, function() searchClearRecolor(T.Dim) end)
connect(searchClear.MouseButton1Click, function() searchInput.Text=""; searchClear.Visible=false; searchCount.Visible=true end)
connect(logoBtn.MouseEnter, function() tween(logoScale, 0.3, Enum.EasingStyle.Back, nil, { Scale=1.15 }); tween(logoBtn, 0.35, nil, nil, { Rotation=90 }) end)
connect(logoBtn.MouseLeave, function() tween(logoScale, 0.35, Enum.EasingStyle.Back, nil, { Scale=1 }); tween(logoBtn, 0.45, Enum.EasingStyle.Quint, nil, { Rotation=0 }) end)
connect(logoBtn.MouseButton1Click, function() local c = Color3.fromHSV(math.random(), 0.62, 1); local hh = Color3.toHSV(c); Window:SetAccent(c, Color3.fromHSV((hh+0.12)%1, 0.6, 1)); ripple(logoBtn, T.White); Window:Notify("Акцент обновлён", toHex(c), "good", 1.8) end)
connect(avatarHolder.MouseEnter, function() tween(avatarScale, 0.3, Enum.EasingStyle.Back, nil, { Scale=1.12 }); tween(avatarRing, 0.25, nil, nil, { Transparency=0.15 }) end)
connect(avatarHolder.MouseLeave, function() tween(avatarScale, 0.35, Enum.EasingStyle.Back, nil, { Scale=1 }); tween(avatarRing, 0.3, nil, nil, { Transparency=0.55 }) end)
watermark.Active = true
connect(watermark.InputBegan, function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then wmDrag=true; wmStart=UserInputService:GetMouseLocation(); wmStartPos=Vector2.new(watermark.Position.X.Offset, watermark.Position.Y.Offset) end end)
if touchBtn then connect(touchBtn.MouseButton1Click, function() Window:Toggle() end) end

loop(logoDot, 1.6, Enum.EasingStyle.Sine, { BackgroundTransparency=0.55, Size=UDim2.fromOffset(5,5) }, true)
loop(statusDot, 1.4, Enum.EasingStyle.Sine, { BackgroundTransparency=0.55 }, true)
loop(glow, 3.2, Enum.EasingStyle.Sine, { BackgroundTransparency=0.935 }, true)
loop(avatarRing, 2.4, Enum.EasingStyle.Sine, { Thickness=2 }, true)
loop(verChip, 2.6, Enum.EasingStyle.Sine, { BackgroundTransparency=0.68 }, true)

local function watchCamera()
	if camConn then camConn:Disconnect() end
	local cam = workspace.CurrentCamera; if not cam then return end
	camConn = connect(cam:GetPropertyChangedSignal("ViewportSize"), function()
		local v = viewport(); baseScale = userScale*responsive(); uiScale.Scale = baseScale
		if not moved then centerPanel() end
		local half = Vector2.new(W, panelHeight())*0.5*baseScale
		targetPos = Vector2.new(clamp(targetPos.X, half.X+8, math.max(half.X+8, v.X-half.X-8)), clamp(targetPos.Y, half.Y+8, math.max(half.Y+8, v.Y-half.Y-8)))
		if not Window._open then curPos = targetPos end
	end)
end
watchCamera(); connect(workspace:GetPropertyChangedSignal("CurrentCamera"), watchCamera)

-- ══════════════════════════ КОНТРОЛЫ ══════════════════════════
local Tab = {}; Tab.__index = Tab
local function fadeIcon(box, tr, time) for _, p in ipairs(box:GetChildren()) do if p:IsA("Frame") then tween(p, time or 0.2, nil, nil, { BackgroundTransparency=tr }) end end end
local function pulse(sc, from) sc.Scale = from or 0.97; tween(sc, 0.35, Enum.EasingStyle.Back, nil, { Scale=1 }) end
local function keyName(b) if not b then return "None" end if b.EnumType==Enum.KeyCode then return b.Name end local m = { MouseButton1="M1", MouseButton2="M2", MouseButton3="M3" }; return m[b.Name] or b.Name end
local function captureKey(cb)
	listening = function(input)
		local key
		if input.UserInputType==Enum.UserInputType.Keyboard then key = input.KeyCode
		elseif input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.MouseButton2 or input.UserInputType==Enum.UserInputType.MouseButton3 then key = input.UserInputType end
		if not key then return end
		listening = nil
		if key==Enum.KeyCode.Escape then cb(nil, "cancel"); return end
		if key==CONFIG.ToggleKey then cb(nil, "reserved"); return end
		if key==Enum.KeyCode.Backspace or key==Enum.KeyCode.Delete then cb(nil, "clear"); return end
		cb(key, "ok")
	end
end

function Tab:_row(height, name, clickable)
	local holder = new("CanvasGroup", { Name=name or "Row", BackgroundTransparency=1, GroupTransparency=0, ClipsDescendants=true, Size=UDim2.new(1,0,0,height), Parent=self.scroll })
	local card = new(clickable and "TextButton" or "Frame", { Name="Card", BackgroundColor3=T.Card, BackgroundTransparency=0.55, BorderSizePixel=0, Size=UDim2.fromScale(1,1), Parent=holder })
	if clickable then card.Text=""; card.AutoButtonColor=false end
	corner(card, 9); stroke(card, 0.93, 1)
	
	-- ФИКС ТЕМЫ: Карточки теперь тоже меняют цвет
	accent(function(c) 
		local h, s, v = Color3.toHSV(c)
		tween(card, 0.4, nil, nil, { BackgroundColor3 = Color3.fromHSV(h, clamp(s * 0.3, 0, 1), 0.18) })
	end)

	local sc = new("UIScale", { Scale=1, Parent=card })
	local e = { kind="row", holder=holder, card=card, scale=sc, name=string.lower(name or ""), displayName=name, rowHeight=height, section=self._section, tab=self, tabName=self.name, match=true, depOK=true, secOK=true, _vis=true }
	self.rows[#self.rows+1] = e
	if self._section then self._section.rows[#self._section.rows+1] = e end
	if clickable then connect(card.MouseButton2Click, function() if e.reset then e.reset(); pulse(sc, 0.96); Window:Notify("Сброшено", e.displayName, "info", 1.4) end end) end
	return holder, card, e
end

function Tab:Section(title)
	local holder = new("CanvasGroup", { Name="Section", BackgroundTransparency=1, GroupTransparency=0, ClipsDescendants=true, Size=UDim2.new(1,0,0,22), Parent=self.scroll })
	local btn = new("TextButton", { Text="", AutoButtonColor=false, BackgroundTransparency=1, Size=UDim2.fromScale(1,1), Parent=holder })
	local lbl = text({ Text=string.upper(title), TextSize=9, Font=Enum.Font.GothamBold, TextColor3=T.Dim, Position=UDim2.fromOffset(4,4), Size=UDim2.new(1,-30,0,14), Parent=btn })
	local chev = icon("chevron", btn, T.Dim, UDim2.new(1,-18,0,6))
	local line = new("Frame", { BackgroundColor3=ACCENT, BackgroundTransparency=0.7, BorderSizePixel=0, Position=UDim2.fromOffset(4,19), Size=UDim2.fromOffset(18,1.5), Parent=btn }); corner(line, 1)
	accent(function(c) tween(line, 0.35, nil, nil, { BackgroundColor3=c }) end)
	local sec = { kind="section", holder=holder, rowHeight=22, name=string.lower(title), displayName=title, rows={}, collapsed=false, tab=self, tabName=self.name, match=true, depOK=true, secOK=true, _vis=true }
	self.rows[#self.rows+1] = sec; self.sections[#self.sections+1] = sec; self._section = sec; register(sec)
	connect(btn.MouseEnter, function() tween(lbl, 0.18, nil, nil, { TextColor3=T.Sub }); tween(line, 0.25, nil, nil, { Size=UDim2.fromOffset(34,1.5), BackgroundTransparency=0.35 }) end)
	connect(btn.MouseLeave, function() tween(lbl, 0.22, nil, nil, { TextColor3=T.Dim }); tween(line, 0.3, nil, nil, { Size=UDim2.fromOffset(18,1.5), BackgroundTransparency=0.7 }) end)
	connect(btn.MouseButton1Click, function() sec.collapsed = not sec.collapsed; tween(chev, 0.35, Enum.EasingStyle.Quint, nil, { Rotation=sec.collapsed and -90 or 0 }); clickSound(sec.collapsed and 1.1 or 1.5); for i,e in ipairs(sec.rows) do e.secOK = not sec.collapsed; task.delay(sec.collapsed and (i*0.012) or 0, function() applyRowState(e) end) end end)
	return sec
end

function Tab:Paragraph(txt)
	local w = math.max(120, W-SIDE_W-36); local h = 26
	pcall(function() h = TextService:GetTextSize(txt, 10, Enum.Font.GothamMedium, Vector2.new(w, 600)).Y+6 end)
	local holder = new("CanvasGroup", { Name="Paragraph", BackgroundTransparency=1, GroupTransparency=0, ClipsDescendants=true, Size=UDim2.new(1,0,0,h), Parent=self.scroll })
	text({ Text=txt, TextSize=10, TextColor3=T.Dim, TextWrapped=true, TextTruncate=Enum.TextTruncate.None, TextYAlignment=Enum.TextYAlignment.Top, Position=UDim2.fromOffset(4,2), Size=UDim2.new(1,-8,1,-4), Parent=holder })
	local e = { kind="paragraph", holder=holder, rowHeight=h, name=string.lower(txt), section=self._section, tab=self, tabName=self.name, match=true, depOK=true, secOK=true, _vis=true }
	self.rows[#self.rows+1] = e; if self._section then self._section.rows[#self._section.rows+1] = e end; register(e)
	return holder
end

function Tab:Toggle(cfg)
	local flag = cfg.Flag or cfg.Name; local state = cfg.Default and true or false; Window.Flags[flag] = state
	local holder, card, e = self:_row(34, cfg.Name, true); e.kind, e.flag, e.dep = "toggle", flag, cfg.Depends; attachTooltip(card, cfg.Tooltip)
	text({ Text=cfg.Name, TextSize=11, Position=UDim2.fromOffset(12,0), Size=UDim2.new(1, cfg.Key and -100 or -66, 1, 0), Parent=card })
	local keyChip
	if cfg.Key then keyChip = new("TextButton", { Text=keyName(cfg.Key), AutoButtonColor=false, BackgroundColor3=T.Bg, BackgroundTransparency=0.4, BorderSizePixel=0, TextColor3=T.Dim, Font=Enum.Font.GothamBold, TextSize=8, ZIndex=2, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-50,0.5,0), Size=UDim2.fromOffset(32,16), Parent=card }); corner(keyChip, 5) end
	local track = new("Frame", { BackgroundColor3=T.Track, BorderSizePixel=0, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-12,0.5,0), Size=UDim2.fromOffset(32,18), Parent=card }); corner(track, 9)
	local trackStroke = stroke(track, 0.88, 1)
	local glowRing = new("Frame", { BackgroundTransparency=1, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(40,26), Parent=track }); corner(glowRing, 13)
	local glowStroke = stroke(glowRing, 1, 1.4, ACCENT); accent(function(c) tween(glowStroke, 0.35, nil, nil, { Color=c }) end)
	local knob = new("Frame", { BackgroundColor3=T.White, BorderSizePixel=0, ZIndex=2, Position=UDim2.new(0,2,0.5,-7), Size=UDim2.fromOffset(14,14), Parent=track }); corner(knob, 7)
	local knobScale = new("UIScale", { Scale=1, Parent=knob })
	local check = icon("check", knob, ACCENT, UDim2.fromOffset(1,1), 12); check.ZIndex = 3; fadeIcon(check, 1, 0.01)
	accent(function(c) for _, p in ipairs(check:GetChildren()) do if p:IsA("Frame") then tween(p, 0.35, nil, nil, { BackgroundColor3=c }) end end end)
	local api = {}
	local function set(v, silent)
		state = v and true or false; Window.Flags[flag] = state
		tween(track, 0.28, Enum.EasingStyle.Quad, nil, { BackgroundColor3=state and ACCENT or T.Track })
		tween(trackStroke, 0.28, nil, nil, { Transparency=state and 0.55 or 0.88, Color=state and ACCENT or T.White })
		tween(glowStroke, 0.35, nil, nil, { Transparency=state and 0.65 or 1 })
		tween(knob, 0.34, Enum.EasingStyle.Back, nil, { Position=UDim2.new(0, state and 16 or 2, 0.5, -7) })
		fadeIcon(check, state and 0 or 1, 0.22)
		if not silent then knobScale.Scale = 0.74; tween(knobScale, 0.4, Enum.EasingStyle.Back, nil, { Scale=1 }); clickSound(state and 1.8 or 1.2); if cfg.Callback then task.spawn(cfg.Callback, state) end; changed(e) end
	end
	accent(function(c) if state then tween(track, 0.35, nil, nil, { BackgroundColor3=c }) end end)
	connect(card.MouseButton1Click, function() set(not state); ripple(card, state and ACCENT or T.White) end)
	hoverize(card, 0.55, 0.36); set(state, true)
	if keyChip then
		local entry = { name=cfg.Name, mode="toggle", state=false, get=function() return cfg.Key end, callback=function() set(not state) end }
		binds[#binds+1] = entry
		connect(keyChip.MouseButton1Click, function() keyChip.Text="..."; captureKey(function(k, status) if status=="ok" then cfg.Key=k end; keyChip.Text=keyName(cfg.Key); refreshBindHud() end) end)
	end
	e.get = function() return state end; e.set = set; e.reset = function() set(cfg.Default and true or false) end
	e.serialize = function() return state end; e.deserialize = function(v) set(v and true or false) end
	api.Set, api.Get, api.Instance = function(v) set(v) end, function() return state end, holder
	register(e); updateDeps(); return api
end

function Tab:Slider(cfg)
	local flag = cfg.Flag or cfg.Name; local min, max = cfg.Min or 0, cfg.Max or 100; local step = cfg.Step or 1
	local value = clamp(cfg.Default or min, min, max); Window.Flags[flag] = value
	local holder, card, e = self:_row(46, cfg.Name, true); e.kind, e.flag, e.dep = "slider", flag, cfg.Depends; attachTooltip(card, cfg.Tooltip)
	text({ Text=cfg.Name, TextSize=11, Position=UDim2.fromOffset(12,7), Size=UDim2.new(1,-90,0,16), Parent=card })
	local valLabel = text({ Text="", TextSize=10, TextColor3=ACCENT, TextXAlignment=Enum.TextXAlignment.Right, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-12,0,7), Size=UDim2.fromOffset(74,16), ZIndex=2, Parent=card })
	local valScale = new("UIScale", { Scale=1, Parent=valLabel }); accent(function(c) tween(valLabel, 0.35, nil, nil, { TextColor3=c }) end)
	local valBtn = new("TextButton", { Text="", AutoButtonColor=false, BackgroundTransparency=1, ZIndex=3, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-10,0,5), Size=UDim2.fromOffset(78,20), Parent=card })
	local valInput = new("TextBox", { BackgroundColor3=T.Bg, BackgroundTransparency=0.2, BorderSizePixel=0, Text="", PlaceholderText="число", PlaceholderColor3=T.Dim, TextColor3=T.Text, Font=Enum.Font.GothamMedium, TextSize=10, ClearTextOnFocus=false, Visible=false, ZIndex=4, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-10,0,5), Size=UDim2.fromOffset(78,20), Parent=card }); corner(valInput, 6)
	local track = new("Frame", { BackgroundColor3=T.Track, BackgroundTransparency=0.35, BorderSizePixel=0, Position=UDim2.fromOffset(12,31), Size=UDim2.new(1,-24,0,4), Parent=card }); corner(track, 2)
	local fill = new("Frame", { BackgroundColor3=ACCENT, BorderSizePixel=0, Size=UDim2.fromScale(0,1), Parent=track }); corner(fill, 2)
	local fillGrad = new("UIGradient", { Color=ColorSequence.new(ACCENT, ACCENT2), Parent=fill })
	accent(function(c) tween(fill, 0.35, nil, nil, { BackgroundColor3=c }); tween(fillGrad, 0.35, nil, nil, { Color=ColorSequence.new(c, ACCENT2) }) end)
	local knob = new("Frame", { BackgroundColor3=T.White, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0,0.5), Size=UDim2.fromOffset(10,10), ZIndex=2, Parent=track }); corner(knob, 5); stroke(knob, 0.7, 1, Color3.new(0,0,0))
	local knobScale = new("UIScale", { Scale=1, Parent=knob })
	local knobGlow = new("Frame", { BackgroundTransparency=1, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(20,20), Parent=knob }); corner(knobGlow, 10)
	local knobGlowStroke = stroke(knobGlow, 1, 1.2, ACCENT); accent(function(c) tween(knobGlowStroke, 0.35, nil, nil, { Color=c }) end)
	local function fmt(v) if step>=1 then return tostring(round(v))..(cfg.Suffix or "") end local dec, x = 0, step; while x<1 and dec<3 do x=x*10; dec+=1 end; return string.format("%."..dec.."f", v)..(cfg.Suffix or "") end
	local api = {}; local draggingSlider, shimmer = false, nil
	local function set(v, silent, instant)
		v = clamp(math.floor(v/step+0.5)*step, min, max); local wasChanged = (v~=value); value = v; Window.Flags[flag] = v
		local frac = (max>min) and ((v-min)/(max-min)) or 0; valLabel.Text = fmt(v)
		if instant then fill.Size = UDim2.fromScale(frac,1); knob.Position = UDim2.fromScale(frac,0.5) else tween(fill, 0.16, Enum.EasingStyle.Quad, nil, { Size=UDim2.fromScale(frac,1) }); tween(knob, 0.16, Enum.EasingStyle.Quad, nil, { Position=UDim2.fromScale(frac,0.5) }) end
		if wasChanged and not silent then valScale.Scale = 1.18; tween(valScale, 0.3, Enum.EasingStyle.Back, nil, { Scale=1 }); if cfg.Callback then task.spawn(cfg.Callback, v) end; changed(e) end
	end
	local function fromMouse() local x = UserInputService:GetMouseLocation().X; local frac = clamp((x-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1), 0, 1); set(min+(max-min)*frac, false, true) end
	connect(card.InputBegan, function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			draggingSlider = true; tween(knobScale, 0.25, Enum.EasingStyle.Back, nil, { Scale=1.4 }); tween(knobGlowStroke, 0.25, nil, nil, { Transparency=0.4 }); tween(card, 0.18, nil, nil, { BackgroundTransparency=0.36 })
			if not Anim.off then fillGrad.Offset = Vector2.new(-1,0); shimmer = TweenService:Create(fillGrad, TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Offset=Vector2.new(1,0) }); shimmer:Play() end
			fromMouse()
		end
	end)
	connect(UserInputService.InputChanged, function(input) if draggingSlider and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then fromMouse() end end)
	connect(UserInputService.InputEnded, function(input)
		if (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) and draggingSlider then
			draggingSlider = false; if shimmer then shimmer:Cancel(); shimmer=nil; fillGrad.Offset=Vector2.new(0,0) end
			tween(knobScale, 0.35, Enum.EasingStyle.Back, nil, { Scale=1 }); tween(knobGlowStroke, 0.3, nil, nil, { Transparency=1 }); tween(card, 0.22, nil, nil, { BackgroundTransparency=0.55 }); clickSound(1.3)
		end
	end)
	connect(valBtn.MouseButton1Click, function() valInput.Text=tostring(value); valInput.Visible=true; valLabel.Visible=false; valInput:CaptureFocus() end)
	connect(valInput.FocusLost, function(enter) local n = tonumber(valInput.Text); if enter and n then set(n) end; valInput.Visible=false; valLabel.Visible=true end)
	attachTooltip(valBtn, "Клик — ввести точное значение"); hoverize(card, 0.55, 0.42); set(value, true, true)
	e.get = function() return value end; e.set = set; e.reset = function() set(cfg.Default or min) end
	e.serialize = function() return value end; e.deserialize = function(v) if tonumber(v) then set(tonumber(v)) end end
	api.Set, api.Get, api.Instance = function(v) set(v) end, function() return value end, holder
	register(e); updateDeps(); return api
end

function Tab:Dropdown(cfg)
	local flag = cfg.Flag or cfg.Name; local options = cfg.Options or { "One", "Two" }; local multi = cfg.Multi and true or false
	local value
	if multi then value = {}; for _, v in ipairs(cfg.Default or {}) do value[#value+1] = v end else value = cfg.Default or options[1] end
	Window.Flags[flag] = value; local open = false
	local holder, card, e = self:_row(34, cfg.Name, true); e.kind, e.flag, e.dep = "dropdown", flag, cfg.Depends; attachTooltip(card, cfg.Tooltip); card.ClipsDescendants = false
	text({ Text=cfg.Name, TextSize=11, Position=UDim2.fromOffset(12,0), Size=UDim2.new(1,-122,0,34), Parent=card })
	local chip = new("TextButton", { Text="", AutoButtonColor=false, BackgroundColor3=T.Bg, BackgroundTransparency=0.35, BorderSizePixel=0, AnchorPoint=Vector2.new(1,0), ZIndex=2, Position=UDim2.new(1,-10,0,6), Size=UDim2.fromOffset(98,22), Parent=card }); corner(chip, 7)
	local chipStroke = stroke(chip, 0.9, 1)
	local chipText = text({ Text="", TextSize=10, TextColor3=T.Sub, ZIndex=2, Position=UDim2.fromOffset(9,0), Size=UDim2.new(1,-26,1,0), Parent=chip })
	local caretA = new("Frame", { BackgroundColor3=T.Sub, BorderSizePixel=0, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-11,0.5,1), Size=UDim2.fromOffset(5,1.4), Rotation=45, ZIndex=2, Parent=chip })
	local caretB = new("Frame", { BackgroundColor3=T.Sub, BorderSizePixel=0, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-8,0.5,1), Size=UDim2.fromOffset(5,1.4), Rotation=-45, ZIndex=2, Parent=chip }); corner(caretA, 1); corner(caretB, 1)
	local searchable = (#options>6); local searchH = searchable and 24 or 0; local listH = math.max(22, math.min(#options*25-3, 110))
	local listBox = new("CanvasGroup", { BackgroundTransparency=1, GroupTransparency=1, ClipsDescendants=true, ZIndex=3, Position=UDim2.fromOffset(10,36), Size=UDim2.new(1,-20,0,0), Parent=card })
	local optSearch
	if searchable then
		local sb = new("Frame", { BackgroundColor3=T.Bg, BackgroundTransparency=0.35, BorderSizePixel=0, Size=UDim2.new(1,0,0,20), Parent=listBox }); corner(sb, 6); icon("search", sb, T.Dim, UDim2.fromOffset(6,3), 12)
		optSearch = new("TextBox", { BackgroundTransparency=1, Text="", PlaceholderText="фильтр", PlaceholderColor3=T.Dim, TextColor3=T.Text, Font=Enum.Font.GothamMedium, TextSize=9, ClearTextOnFocus=false, TextXAlignment=Enum.TextXAlignment.Left, Position=UDim2.fromOffset(22,0), Size=UDim2.new(1,-28,1,0), Parent=sb })
	end
	local list = new("ScrollingFrame", { BackgroundTransparency=1, BorderSizePixel=0, Position=UDim2.fromOffset(0,searchH), Size=UDim2.new(1,0,0,listH), CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarThickness=2, ScrollBarImageColor3=T.White, ScrollBarImageTransparency=0.85, ScrollingDirection=Enum.ScrollingDirection.Y, Parent=listBox })
	new("UIListLayout", { Padding=UDim.new(0,3), SortOrder=Enum.SortOrder.LayoutOrder, Parent=list })
	local api = {}; local optionButtons = {}
	local function label() if not multi then return tostring(value) end if #value==0 then return "ничего" end if #value==1 then return tostring(value[1]) end return #value.." выбрано" end
	local function refreshMarks()
		for _, b in ipairs(optionButtons) do
			local on
			if multi then on=false; for _, v in ipairs(value) do if v==b.val then on=true end end else on=(b.val==value) end
			tween(b.bg, 0.2, nil, nil, { BackgroundTransparency=on and 0.72 or 1 }); tween(b.lbl, 0.2, nil, nil, { TextColor3=on and ACCENT or T.Sub }); fadeIcon(b.mark, on and 0 or 1, 0.2); tween(b.mark, 0.3, Enum.EasingStyle.Back, nil, { Rotation=on and 0 or -40 })
		end
	end
	local function setOpen(v)
		open = v; local total = listH+searchH; e.rowHeight = 34+(open and (total+12) or 0); applyRowState(e)
		tween(listBox, 0.32, Enum.EasingStyle.Quint, nil, { Size=UDim2.new(1,-20,0, open and total or 0), GroupTransparency=open and 0 or 1 })
		tween(chipStroke, 0.25, nil, nil, { Transparency=open and 0.6 or 0.9, Color=open and ACCENT or T.White }); tween(chipText, 0.25, nil, nil, { TextColor3=open and T.Text or T.Sub })
		local rot = open and 180 or 0; tween(caretA, 0.32, Enum.EasingStyle.Quint, nil, { Rotation=45+rot }); tween(caretB, 0.32, Enum.EasingStyle.Quint, nil, { Rotation=-45+rot })
		if open then for i,b in ipairs(optionButtons) do if b.wrap.Visible then b.bg.Position=UDim2.fromOffset(0,8); tween(b.bg, 0.3+i*0.015, Enum.EasingStyle.Quint, nil, { Position=UDim2.fromOffset(0,0) }) end end end
	end
	local function set(v, silent) value=v; Window.Flags[flag]=v; chipText.Text=label(); refreshMarks(); if not silent then if cfg.Callback then task.spawn(cfg.Callback, v) end; changed(e) end end
	local function build()
		for _, c in ipairs(list:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
		optionButtons = {}
		for i, opt in ipairs(options) do
			local wrap = new("Frame", { BackgroundTransparency=1, LayoutOrder=i, Size=UDim2.new(1,0,0,22), Parent=list })
			local ob = new("TextButton", { Text="", AutoButtonColor=false, BackgroundColor3=T.Bg, BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.fromScale(1,1), Parent=wrap }); corner(ob, 6)
			local mark = icon("check", ob, ACCENT, UDim2.fromOffset(7,5), 12); fadeIcon(mark, 1, 0.01)
			accent(function(c) for _, p in ipairs(mark:GetChildren()) do if p:IsA("Frame") then tween(p, 0.35, nil, nil, { BackgroundColor3=c }) end end end)
			local lbl = text({ Text=tostring(opt), TextSize=10, TextColor3=T.Sub, Position=UDim2.fromOffset(24,0), Size=UDim2.new(1,-30,1,0), Parent=ob })
			optionButtons[#optionButtons+1] = { wrap=wrap, bg=ob, lbl=lbl, mark=mark, val=opt }
			connect(ob.MouseEnter, function() tween(ob, 0.15, nil, nil, { BackgroundTransparency=0.6 }) end)
			connect(ob.MouseLeave, function() local on=false; if multi then for _, v in ipairs(value) do if v==opt then on=true end end else on=(value==opt) end; tween(ob, 0.2, nil, nil, { BackgroundTransparency=on and 0.72 or 1 }) end)
			connect(ob.MouseButton1Click, function()
				if multi then local found=nil; for idx,v in ipairs(value) do if v==opt then found=idx end end; if found then table.remove(value, found) else value[#value+1]=opt end; set(value) else set(opt); setOpen(false) end
				clickSound(1.5)
			end)
		end
		refreshMarks()
	end
	build()
	if optSearch then
		connect(optSearch:GetPropertyChangedSignal("Text"), function()
			local q = string.lower(optSearch.Text); local n = 0
			for _, b in ipairs(optionButtons) do local ok = (q=="") or string.find(string.lower(tostring(b.val)), q, 1, true); b.wrap.Visible = ok and true or false; if ok then n+=1 end end
			listH = math.max(22, math.min(n*25-3, 110)); list.Size = UDim2.new(1,0,0,listH)
			if open then e.rowHeight = 34+listH+searchH+12; applyRowState(e); tween(listBox, 0.25, nil, nil, { Size=UDim2.new(1,-20,0,listH+searchH) }) end
		end)
	end
	connect(chip.MouseEnter, function() tween(chip, 0.18, nil, nil, { BackgroundTransparency=0.15 }) end)
	connect(chip.MouseLeave, function() tween(chip, 0.22, nil, nil, { BackgroundTransparency=0.35 }) end)
	connect(card.MouseButton1Click, function() setOpen(not open) end)
	connect(chip.MouseButton1Click, function() setOpen(not open) end)
	hoverize(card, 0.55, 0.42); set(value, true)
	e.get = function() return value end; e.set = set
	e.reset = function() if multi then local t={}; for _, v in ipairs(cfg.Default or {}) do t[#t+1]=v end; set(t) else set(cfg.Default or options[1]) end end
	e.serialize = function() return value end
	e.deserialize = function(v) if multi then if typeof(v)=="table" then set(v) end elseif v~=nil then set(v) end end
	e.refresh = function(newOptions) options=newOptions; build(); chipText.Text=label() end
	api.Set, api.Get, api.Instance = function(v) set(v) end, function() return value end, holder
	api.Refresh = function(newOptions) e.refresh(newOptions) end
	register(e); updateDeps(); return api
end

function Tab:Keybind(cfg)
	local flag = cfg.Flag or cfg.Name; local bind = cfg.Default; local mode = cfg.Mode or "toggle"; Window.Flags[flag] = bind
	local waiting = false
	local holder, card, e = self:_row(34, cfg.Name, true); e.kind, e.flag, e.dep = "keybind", flag, cfg.Depends; attachTooltip(card, cfg.Tooltip)
	text({ Text=cfg.Name, TextSize=11, Position=UDim2.fromOffset(12,0), Size=UDim2.new(1,-160,1,0), Parent=card })
	local modeBtn = new("TextButton", { Text=string.upper(mode), AutoButtonColor=false, BackgroundColor3=T.Bg, BackgroundTransparency=0.45, BorderSizePixel=0, TextColor3=T.Dim, Font=Enum.Font.GothamBold, TextSize=8, ZIndex=2, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-100,0.5,0), Size=UDim2.fromOffset(42,20), Parent=card }); corner(modeBtn, 6)
	local chip = new("TextButton", { Text="", AutoButtonColor=false, BackgroundColor3=T.Bg, BackgroundTransparency=0.35, BorderSizePixel=0, AnchorPoint=Vector2.new(1,0.5), ZIndex=2, Position=UDim2.new(1,-10,0.5,0), Size=UDim2.fromOffset(84,22), Parent=card }); corner(chip, 7)
	local chipStroke = stroke(chip, 0.9, 1); local chipScale = new("UIScale", { Scale=1, Parent=chip })
	local chipText = text({ Text=keyName(bind), TextSize=10, TextColor3=T.Sub, ZIndex=2, TextXAlignment=Enum.TextXAlignment.Center, Size=UDim2.fromScale(1,1), Parent=chip })
	local api = {}; local entry = { name=cfg.Name, mode=mode, state=false, get=function() return bind end, callback=cfg.Callback }; binds[#binds+1] = entry
	local pulseTween
	local function stopWait() waiting=false; listening=nil; if pulseTween then pulseTween:Cancel(); pulseTween=nil end; chipText.Text=keyName(bind); tween(chipStroke, 0.25, nil, nil, { Transparency=0.9, Color=T.White }); tween(chipText, 0.25, nil, nil, { TextColor3=T.Sub }); tween(chipScale, 0.3, Enum.EasingStyle.Back, nil, { Scale=1 }) end
	local function startWait()
		waiting=true; chipText.Text="..."; tween(chipStroke, 0.25, nil, nil, { Transparency=0.35, Color=ACCENT }); tween(chipText, 0.25, nil, nil, { TextColor3=ACCENT })
		if not Anim.off then pulseTween = TweenService:Create(chipScale, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale=1.06 }); pulseTween:Play() end
		captureKey(function(k, status)
			if status=="reserved" then stopWait(); shake(chip, 4); Window:Notify("Клавиша занята меню", keyName(CONFIG.ToggleKey), "warn"); return
			elseif status=="cancel" then stopWait(); return
			elseif status=="clear" then bind=nil
			else bind=k end
			Window.Flags[flag] = bind; stopWait(); pulse(chipScale, 0.9); clickSound(1.7); refreshBindHud(); queueAutoSave()
			if cfg.Callback then task.spawn(cfg.Callback, bind) end
		end)
	end
	connect(modeBtn.MouseButton1Click, function() mode=(mode=="toggle") and "hold" or "toggle"; entry.mode=mode; modeBtn.Text=string.upper(mode); pulse(chipScale, 0.95); clickSound(1.4); refreshBindHud() end)
	attachTooltip(modeBtn, "Режим: toggle — вкл/выкл, hold — пока держишь")
	connect(chip.MouseEnter, function() tween(chip, 0.18, nil, nil, { BackgroundTransparency=0.15 }) end)
	connect(chip.MouseLeave, function() tween(chip, 0.22, nil, nil, { BackgroundTransparency=0.35 }) end)
	connect(card.MouseButton1Click, function() if waiting then stopWait() else startWait() end end)
	connect(chip.MouseButton1Click, function() if waiting then stopWait() else startWait() end end)
	hoverize(card, 0.55, 0.42)
	e.get = function() return bind end
	e.set = function(k) bind=k; Window.Flags[flag]=k; chipText.Text=keyName(k); refreshBindHud() end
	e.reset = function() e.set(cfg.Default) end
	e.serialize = function() return bind and tostring(bind) or nil end
	e.deserialize = function(v) if typeof(v)~="string" then return end local en,key = string.match(v, "Enum%.([%w]+)%.([%w]+)"); if en and key then local ok,res = pcall(function() return Enum[en][key] end); if ok then e.set(res) end end end
	api.Set, api.Get, api.Instance = function(k) e.set(k) end, function() return bind end, holder
	register(e); updateDeps(); refreshBindHud(); return api
end

function Tab:Button(cfg)
	local holder, card, e = self:_row(32, cfg.Name, true); e.kind, e.dep = "button", cfg.Depends; e.flag = cfg.Flag; attachTooltip(card, cfg.Tooltip); card.ClipsDescendants = true
	card.BackgroundColor3 = cfg.Danger and Color3.fromRGB(70,40,48) or T.Card
	local lbl = text({ Text=cfg.Name, TextSize=11, TextXAlignment=Enum.TextXAlignment.Center, Size=UDim2.fromScale(1,1), Parent=card })
	if cfg.Icon then icon(cfg.Icon, card, T.Sub, UDim2.new(0,12,0.5,-7)) end
	connect(card.MouseEnter, function() tween(card, 0.18, nil, nil, { BackgroundTransparency=0.3 }); tween(e.scale, 0.22, Enum.EasingStyle.Back, nil, { Scale=1.015 }); tween(lbl, 0.18, nil, nil, { TextColor3=cfg.Danger and T.Bad or T.White }) end)
	connect(card.MouseLeave, function() tween(card, 0.22, nil, nil, { BackgroundTransparency=0.55 }); tween(e.scale, 0.28, nil, nil, { Scale=1 }); tween(lbl, 0.22, nil, nil, { TextColor3=T.Text }) end)
	local function fire() ripple(card, cfg.Danger and T.Bad or ACCENT); pulse(e.scale, 0.96); clickSound(1.5); if cfg.Callback then task.spawn(cfg.Callback) end end
	connect(card.MouseButton1Click, fire)
	e.set, e.get = fire, function() return nil end; e.serialize = function() return nil end
	register(e); updateDeps(); return { Instance=holder, Fire=fire }
end

function Tab:Input(cfg)
	local flag = cfg.Flag or cfg.Name; local value = cfg.Default or ""; Window.Flags[flag] = value
	local holder, card, e = self:_row(34, cfg.Name, false); e.kind, e.flag, e.dep = "input", flag, cfg.Depends; attachTooltip(card, cfg.Tooltip)
	text({ Text=cfg.Name, TextSize=11, Position=UDim2.fromOffset(12,0), Size=UDim2.new(1,-150,1,0), Parent=card })
	local box = new("Frame", { BackgroundColor3=T.Bg, BackgroundTransparency=0.35, BorderSizePixel=0, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0), Size=UDim2.fromOffset(132,22), Parent=card }); corner(box, 7)
	local bs = stroke(box, 0.9, 1)
	local input = new("TextBox", { BackgroundTransparency=1, Text=value, PlaceholderText=cfg.Placeholder or "введи...", PlaceholderColor3=T.Dim, TextColor3=T.Text, Font=Enum.Font.GothamMedium, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false, Position=UDim2.fromOffset(9,0), Size=UDim2.new(1,-18,1,0), Parent=box })
	connect(input.Focused, function() tween(bs, 0.2, nil, nil, { Transparency=0.45, Color=ACCENT }); tween(box, 0.2, nil, nil, { BackgroundTransparency=0.15 }) end)
	connect(input.FocusLost, function(enter)
		tween(bs, 0.25, nil, nil, { Transparency=0.9, Color=T.White }); tween(box, 0.25, nil, nil, { BackgroundTransparency=0.35 })
		value = input.Text; Window.Flags[flag] = value
		if enter and cfg.Callback then task.spawn(cfg.Callback, value) end
		changed(e)
	end)
	e.get = function() return value end; e.set = function(v) value=tostring(v or ""); input.Text=value; Window.Flags[flag]=value end
	e.reset = function() e.set(cfg.Default or "") end
	e.serialize = function() return value end; e.deserialize = function(v) e.set(v) end
	register(e); updateDeps(); return { Set=function(v) e.set(v) end, Get=function() return value end, Instance=holder }
end

function Tab:Colorpicker(cfg)
	local flag = cfg.Flag or cfg.Name; local color = cfg.Default or ACCENT; local h, s, v = Color3.toHSV(color); Window.Flags[flag] = color
	local open = false
	local holder, card, e = self:_row(34, cfg.Name, true); e.kind, e.flag, e.dep = "color", flag, cfg.Depends; attachTooltip(card, cfg.Tooltip)
	text({ Text=cfg.Name, TextSize=11, Position=UDim2.fromOffset(12,0), Size=UDim2.new(1,-80,0,34), Parent=card })
	local swatch = new("Frame", { BackgroundColor3=color, BorderSizePixel=0, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-12,0,7), Size=UDim2.fromOffset(30,20), ZIndex=2, Parent=card }); corner(swatch, 6); stroke(swatch, 0.7, 1)
	local swScale = new("UIScale", { Scale=1, Parent=swatch })
	local pick = new("CanvasGroup", { BackgroundTransparency=1, GroupTransparency=1, ClipsDescendants=true, Position=UDim2.fromOffset(12,38), Size=UDim2.new(1,-24,0,116), Parent=card })
	local sv = new("Frame", { BackgroundColor3=Color3.fromHSV(h,1,1), BorderSizePixel=0, Size=UDim2.new(1,-26,0,86), Parent=pick }); corner(sv, 6)
	local wo = new("Frame", { BackgroundColor3=T.White, BorderSizePixel=0, Size=UDim2.fromScale(1,1), Parent=sv }); corner(wo, 6); new("UIGradient", { Transparency=NumberSequence.new({ NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1) }), Parent=wo })
	local bo = new("Frame", { BackgroundColor3=Color3.new(0,0,0), BorderSizePixel=0, Size=UDim2.fromScale(1,1), Parent=sv }); corner(bo, 6); new("UIGradient", { Rotation=90, Transparency=NumberSequence.new({ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0) }), Parent=bo })
	local svDot = new("Frame", { BackgroundTransparency=1, AnchorPoint=Vector2.new(0.5,0.5), ZIndex=3, Position=UDim2.fromScale(s,1-v), Size=UDim2.fromOffset(10,10), Parent=sv }); corner(svDot, 5); stroke(svDot, 0, 1.6, T.White)
	local svDotScale = new("UIScale", { Scale=1, Parent=svDot })
	local hue = new("Frame", { BackgroundColor3=T.White, BorderSizePixel=0, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,0,0,0), Size=UDim2.fromOffset(14,86), Parent=pick }); corner(hue, 6)
	new("UIGradient", { Rotation=90, Color=ColorSequence.new({ ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)), ColorSequenceKeypoint.new(0.17,Color3.fromRGB(255,255,0)), ColorSequenceKeypoint.new(0.33,Color3.fromRGB(0,255,0)), ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,255,255)), ColorSequenceKeypoint.new(0.67,Color3.fromRGB(0,0,255)), ColorSequenceKeypoint.new(0.83,Color3.fromRGB(255,0,255)), ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0)) }), Parent=hue })
	local hueDot = new("Frame", { BackgroundColor3=T.White, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,h,0), Size=UDim2.new(1,4,0,3), ZIndex=2, Parent=hue }); corner(hueDot, 2)
	local hexBox = new("Frame", { BackgroundColor3=T.Bg, BackgroundTransparency=0.35, BorderSizePixel=0, Position=UDim2.fromOffset(0,92), Size=UDim2.fromOffset(90,22), Parent=pick }); corner(hexBox, 6); stroke(hexBox, 0.9, 1)
	local hexInput = new("TextBox", { BackgroundTransparency=1, Text=toHex(color), PlaceholderText="#FFFFFF", PlaceholderColor3=T.Dim, TextColor3=T.Sub, Font=Enum.Font.Code, TextSize=10, ClearTextOnFocus=false, Size=UDim2.fromScale(1,1), TextXAlignment=Enum.TextXAlignment.Center, Parent=hexBox })
	local preview = new("Frame", { BackgroundColor3=color, BorderSizePixel=0, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,0,0,92), Size=UDim2.new(1,-98,0,22), Parent=pick }); corner(preview, 6)
	text({ Text="предпросмотр", TextSize=9, TextColor3=T.White, TextTransparency=0.25, TextXAlignment=Enum.TextXAlignment.Center, Size=UDim2.fromScale(1,1), Parent=preview })
	local api = {}
	local function apply(silent)
		color = Color3.fromHSV(h,s,v); Window.Flags[flag] = color; sv.BackgroundColor3 = Color3.fromHSV(h,1,1)
		tween(swatch, 0.15, nil, nil, { BackgroundColor3=color }); tween(preview, 0.15, nil, nil, { BackgroundColor3=color })
		svDot.Position = UDim2.fromScale(s,1-v); hueDot.Position = UDim2.new(0.5,0,h,0); hexInput.Text = toHex(color)
		if not silent then if cfg.Callback then task.spawn(cfg.Callback, color) end; changed(e) end
	end
	local function setOpen(o) open=o; e.rowHeight=open and 160 or 34; applyRowState(e); tween(pick, 0.3, Enum.EasingStyle.Quint, nil, { GroupTransparency=open and 0 or 1 }); tween(swScale, 0.3, Enum.EasingStyle.Back, nil, { Scale=open and 1.1 or 1 }) end
	local svDrag, hueDrag = false, false
	local function svFromMouse() local m = UserInputService:GetMouseLocation(); s = clamp((m.X-sv.AbsolutePosition.X)/math.max(sv.AbsoluteSize.X,1), 0, 1); v = 1-clamp((m.Y-sv.AbsolutePosition.Y)/math.max(sv.AbsoluteSize.Y,1), 0, 1); apply() end
	local function hueFromMouse() local m = UserInputService:GetMouseLocation(); h = clamp((m.Y-hue.AbsolutePosition.Y)/math.max(hue.AbsoluteSize.Y,1), 0, 1); apply() end
	connect(sv.InputBegan, function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then svDrag=true; tween(svDotScale, 0.2, Enum.EasingStyle.Back, nil, { Scale=1.4 }); svFromMouse() end end)
	connect(hue.InputBegan, function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then hueDrag=true; hueFromMouse() end end)
	connect(UserInputService.InputChanged, function(input) if input.UserInputType~=Enum.UserInputType.MouseMovement and input.UserInputType~=Enum.UserInputType.Touch then return end; if svDrag then svFromMouse() end; if hueDrag then hueFromMouse() end end)
	connect(UserInputService.InputEnded, function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then if svDrag then svDrag=false; tween(svDotScale, 0.3, Enum.EasingStyle.Back, nil, { Scale=1 }) end; hueDrag=false end end)
	connect(hexInput.FocusLost, function(enter) local c = enter and fromHex(hexInput.Text); if c then h,s,v = Color3.toHSV(c); apply() else hexInput.Text = toHex(color) end end)
	connect(card.MouseButton1Click, function() setOpen(not open) end)
	hoverize(card, 0.55, 0.42); apply(true)
	e.get = function() return color end; e.set = function(c) if typeof(c)=="Color3" then h,s,v = Color3.toHSV(c); apply() end end
	e.reset = function() e.set(cfg.Default or ACCENT) end
	e.serialize = function() return toHex(color) end; e.deserialize = function(x) local c = fromHex(x); if c then h,s,v = Color3.toHSV(c); apply() end end
	api.Set, api.Get, api.Instance = function(c) e.set(c) end, function() return color end, holder
	register(e); updateDeps(); return api
end

function Tab:Stat(cfg)
	local holder, card, e = self:_row(34, cfg.Name, false); e.kind = "stat"
	text({ Text=cfg.Name, TextSize=11, TextColor3=T.Sub, Position=UDim2.fromOffset(12,0), Size=UDim2.new(1,-100,1,0), Parent=card })
	local val = text({ Text=tostring(cfg.Value or 0), TextSize=13, Font=Enum.Font.GothamBold, TextColor3=ACCENT, TextXAlignment=Enum.TextXAlignment.Right, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-12,0,0), Size=UDim2.fromOffset(90,34), Parent=card })
	local vs = new("UIScale", { Scale=1, Parent=val }); accent(function(c) tween(val, 0.35, nil, nil, { TextColor3=c }) end)
	local counter = new("NumberValue", { Value=tonumber(cfg.Value) or 0 }); local suffix = cfg.Suffix or ""
	connect(counter:GetPropertyChangedSignal("Value"), function() val.Text = tostring(round(counter.Value))..suffix end)
	local function setVal(n) n = tonumber(n) or 0; tween(counter, 0.6, Enum.EasingStyle.Quint, nil, { Value=n }); pulse(vs, 1.15) end
	e.set = setVal; e.get = function() return counter.Value end; register(e)
	return { Set=setVal, Instance=holder }
end

function Tab:PlayerList(cfg)
	local flag = cfg.Flag or "SelectedPlayer"; local selected = nil; Window.Flags[flag] = nil
	local holder, card, e = self:_row(168, cfg.Name or "Players", false); e.kind, e.flag = "playerlist", flag; card.BackgroundTransparency = 0.7
	local head = text({ Text="ИГРОКИ В СЕРВЕРЕ", TextSize=9, Font=Enum.Font.GothamBold, TextColor3=T.Dim, Position=UDim2.fromOffset(12,6), Size=UDim2.new(1,-60,0,14), Parent=card })
	local refreshBtn = new("TextButton", { Text="", AutoButtonColor=false, BackgroundColor3=T.Bg, BackgroundTransparency=0.4, BorderSizePixel=0, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-10,0,5), Size=UDim2.fromOffset(20,18), Parent=card }); corner(refreshBtn, 6)
	local rIcon, rRecolor = icon("refresh", refreshBtn, T.Dim, UDim2.fromOffset(3,2))
	local scroll = new("ScrollingFrame", { BackgroundTransparency=1, BorderSizePixel=0, Position=UDim2.fromOffset(8,26), Size=UDim2.new(1,-16,1,-34), CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarThickness=2, ScrollBarImageColor3=T.White, ScrollBarImageTransparency=0.85, ScrollingDirection=Enum.ScrollingDirection.Y, Parent=card })
	new("UIListLayout", { Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder, Parent=scroll }); pad(scroll, 2, 4, 0, 4)
	local rows = {}
	local function select(plr, row)
		selected = plr; Window.Flags[flag] = plr and plr.Name or nil
		for _, r in pairs(rows) do tween(r.bg, 0.2, nil, nil, { BackgroundTransparency=(r.plr==plr) and 0.35 or 1 }); tween(r.stroke, 0.2, nil, nil, { Transparency=(r.plr==plr) and 0.5 or 1, Color=ACCENT }); tween(r.name, 0.2, nil, nil, { TextColor3=(r.plr==plr) and T.Text or T.Sub }) end
		if cfg.Callback and plr then task.spawn(cfg.Callback, plr) end; changed(e)
	end
	local function addPlayer(plr, i)
		local wrap = new("Frame", { BackgroundTransparency=1, LayoutOrder=i or 1, Size=UDim2.new(1,0,0,30), Parent=scroll })
		local bg = new("TextButton", { Text="", AutoButtonColor=false, BackgroundColor3=T.Card, BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.fromScale(1,1), Parent=wrap }); corner(bg, 7)
		local st = stroke(bg, 1, 1, ACCENT)
		local ha = new("Frame", { BackgroundColor3=T.Bg, BackgroundTransparency=0.4, BorderSizePixel=0, Position=UDim2.fromOffset(5,4), Size=UDim2.fromOffset(22,22), Parent=bg }); corner(ha, 11)
		local img = new("ImageLabel", { BackgroundTransparency=1, ImageTransparency=1, Size=UDim2.fromScale(1,1), Parent=ha }); corner(img, 11); setAvatar(img, plr.UserId, 48)
		local nm = text({ Text=plr.DisplayName, TextSize=10, TextColor3=T.Sub, Position=UDim2.fromOffset(33,3), Size=UDim2.new(1,-40,0,13), Parent=bg })
		text({ Text="@"..plr.Name, TextSize=8, TextColor3=T.Dim, Position=UDim2.fromOffset(33,15), Size=UDim2.new(1,-40,0,12), Parent=bg })
		rows[plr] = { wrap=wrap, bg=bg, stroke=st, name=nm, plr=plr }
		connect(bg.MouseEnter, function() if selected~=plr then tween(bg, 0.15, nil, nil, { BackgroundTransparency=0.7 }) end end)
		connect(bg.MouseLeave, function() if selected~=plr then tween(bg, 0.2, nil, nil, { BackgroundTransparency=1 }) end end)
		connect(bg.MouseButton1Click, function() ripple(bg, ACCENT); select(plr); clickSound(1.5) end)
		bg.Position = UDim2.fromOffset(-10,0); tween(bg, 0.35, Enum.EasingStyle.Quint, nil, { Position=UDim2.fromOffset(0,0) })
	end
	local function rebuild() for _, r in pairs(rows) do r.wrap:Destroy() end; rows={}; for i, plr in ipairs(Players:GetPlayers()) do addPlayer(plr, i) end; head.Text = "ИГРОКИ В СЕРВЕРЕ · "..#Players:GetPlayers() end
	rebuild()
	connect(refreshBtn.MouseEnter, function() rRecolor(T.Text); tween(rIcon, 0.5, Enum.EasingStyle.Quint, nil, { Rotation=180 }) end)
	connect(refreshBtn.MouseLeave, function() rRecolor(T.Dim); tween(rIcon, 0.5, Enum.EasingStyle.Quint, nil, { Rotation=0 }) end)
	connect(refreshBtn.MouseButton1Click, function() rebuild(); clickSound(1.6) end)
	connect(Players.PlayerAdded, function() task.wait(0.2); rebuild() end)
	connect(Players.PlayerRemoving, function() task.wait(0.2); rebuild() end)
	e.get = function() return selected end; e.set = function(plr) if rows[plr] then select(plr) end end
	e.serialize = function() return selected and selected.Name or nil end
	e.deserialize = function(n) local plr = Players:FindFirstChild(tostring(n)); if plr and rows[plr] then select(plr, rows[plr]) end end
	register(e); return { Instance=holder, Get=function() return selected end, Refresh=rebuild }
end

-- ══════════════════════════ ТАБЫ ══════════════════════════
local function applyFilter(tab, query)
	query = string.lower(query or ""); local total = 0
	for _, e in ipairs(tab.rows) do if e.kind~="section" then local m = (query=="") or string.find(e.name or "", query, 1, true)~=nil; e.match = m; if m then total+=1; if e.section then e.section.anyVisible=true end end end end
	for _, s in ipairs(tab.sections) do s.match = (query=="") or s.anyVisible or false; s.anyVisible = false end
	for _, e in ipairs(tab.rows) do applyRowState(e) end
	tab.empty.Visible = (total==0)
	if total==0 then tab.empty.TextTransparency=1; tween(tab.empty, 0.3, nil, nil, { TextTransparency=0 }) end
	if tab==activeTab then searchCount.Text = (query=="") and "" or tostring(total); searchClear.Visible = (query~=""); searchCount.Visible = (query=="") end
	return total
end
Window.ApplyFilter = applyFilter

function Window:Tab(name, iconKind, subtitle)
	local tab = setmetatable({ name=name, rows={}, sections={}, _section=nil }, Tab)
	local index = #self.Tabs; self.Tabs[#self.Tabs+1] = tab
	local btn = new("TextButton", { Name=name, Text="", AutoButtonColor=false, BackgroundTransparency=1, Size=UDim2.new(1,0,0,TAB_H), Position=UDim2.fromOffset(0, index*(TAB_H+TAB_GAP)), ZIndex=2, Parent=tabsBox })
	local ib, recolor = icon(iconKind or "grid", btn, T.Sub, UDim2.fromOffset(10,9))
	local lbl = text({ Text=name, TextSize=11, TextColor3=T.Sub, ZIndex=2, Position=UDim2.fromOffset(32,0), Size=UDim2.new(1,-36,1,0), Parent=btn })
	local ibScale = new("UIScale", { Scale=1, Parent=ib })
	tab.btn, tab.lbl, tab.recolor, tab.ib, tab.ibScale = btn, lbl, recolor, ib, ibScale
	local page = new("CanvasGroup", { Name=name.."Page", BackgroundTransparency=1, GroupTransparency=1, Size=UDim2.fromScale(1,1), Visible=false, Parent=pagesBox })
	local scroll = new("ScrollingFrame", { BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.fromScale(1,1), CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarThickness=3, ScrollBarImageColor3=T.White, ScrollBarImageTransparency=1, ScrollingDirection=Enum.ScrollingDirection.Y, Parent=page })
	pad(scroll, 14, 14, 2, 10); new("UIListLayout", { Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder, Parent=scroll })
	tab.page, tab.scroll, tab.subtitle = page, scroll, subtitle or ""
	local empty = text({ Text="ничего не найдено", TextSize=10, TextColor3=T.Dim, Visible=false, TextXAlignment=Enum.TextXAlignment.Center, Position=UDim2.fromOffset(0,24), Size=UDim2.new(1,0,0,20), Parent=page }); tab.empty = empty
	local sbToken = 0
	local function flashBar() sbToken+=1; local my=sbToken; tween(scroll, 0.2, nil, nil, { ScrollBarImageTransparency=0.65 }); task.delay(1.1, function() if my==sbToken then tween(scroll, 0.5, nil, nil, { ScrollBarImageTransparency=1 }) end end) end
	connect(scroll:GetPropertyChangedSignal("CanvasPosition"), flashBar); connect(scroll.MouseEnter, flashBar)
	connect(btn.MouseEnter, function() if activeTab~=tab then tween(lbl, 0.18, nil, nil, { TextColor3=T.Text }); recolor(T.Text); tween(ibScale, 0.3, Enum.EasingStyle.Back, nil, { Scale=1.18 }) end end)
	connect(btn.MouseLeave, function() if activeTab~=tab then tween(lbl, 0.22, nil, nil, { TextColor3=T.Sub }); recolor(T.Sub); tween(ibScale, 0.35, Enum.EasingStyle.Back, nil, { Scale=1 }) end end)
	connect(btn.MouseButton1Click, function() Window:SelectTab(tab) end)
	if index==0 then task.defer(function() Window:SelectTab(tab, true) end) end
	return tab
end

function Window:SelectTab(tab, instant)
	if activeTab==tab then return end
	local prev = activeTab; local prevIndex, newIndex = 0, 0
	for i,t in ipairs(self.Tabs) do if t==prev then prevIndex=i end; if t==tab then newIndex=i end end
	local dir = (newIndex>=prevIndex) and 1 or -1; activeTab = tab
	for _, t in ipairs(self.Tabs) do local on = (t==tab); tween(t.lbl, 0.22, nil, nil, { TextColor3=on and T.Text or T.Sub }); t.recolor(on and T.Text or T.Sub); tween(t.ibScale, 0.35, Enum.EasingStyle.Back, nil, { Scale=on and 1.1 or 1 }) end
	tween(pill, 0.45, Enum.EasingStyle.Quint, nil, { Position=UDim2.fromOffset(0, (newIndex-1)*(TAB_H+TAB_GAP)) })
	tween(pillBar, 0.4, Enum.EasingStyle.Back, nil, { Size=UDim2.fromOffset(3,19) }); task.delay(0.22, function() tween(pillBar, 0.3, nil, nil, { Size=UDim2.fromOffset(3,15) }) end)
	pageTitle.Text = tab.name; pageSub.Text = tab.subtitle
	pageTitle.Position = UDim2.fromOffset(14, 9+6*dir); pageSub.Position = UDim2.fromOffset(14, 25+6*dir)
	tween(pageTitle, 0.35, Enum.EasingStyle.Quint, nil, { Position=UDim2.fromOffset(14,9) }); tween(pageSub, 0.42, Enum.EasingStyle.Quint, nil, { Position=UDim2.fromOffset(14,25) })
	if prev then tween(prev.page, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { GroupTransparency=1, Position=UDim2.fromOffset(-12*dir,0) }); local p = prev.page; task.delay(0.17, function() if activeTab~=prev then p.Visible=false; p.Position=UDim2.fromOffset(0,0) end end) end
	tab.page.Visible = true; tab.page.GroupTransparency = 1; tab.page.Position = UDim2.fromOffset(instant and 0 or (14*dir), 0)
	tween(tab.page, 0.32, Enum.EasingStyle.Quint, nil, { GroupTransparency=0, Position=UDim2.fromOffset(0,0) })
	tab.scroll.CanvasPosition = Vector2.new(0,0); applyFilter(tab, searchInput.Text)
	if self._open then stagger(tab) end; clickSound(1.45)
end

connect(searchInput:GetPropertyChangedSignal("Text"), function() if activeTab then applyFilter(activeTab, searchInput.Text) end end)
connect(searchInput.Focused, function() tween(searchStroke, 0.2, nil, nil, { Transparency=0.5, Color=ACCENT }); tween(searchBox, 0.3, Enum.EasingStyle.Quint, nil, { Size=UDim2.fromOffset(150,24) }); searchRecolor(ACCENT) end)
connect(searchInput.FocusLost, function() tween(searchStroke, 0.25, nil, nil, { Transparency=0.9, Color=T.White }); if searchInput.Text=="" then tween(searchBox, 0.3, Enum.EasingStyle.Quint, nil, { Size=UDim2.fromOffset(SEARCH_W,24) }) end; searchRecolor(T.Dim) end)
connect(palInput:GetPropertyChangedSignal("Text"), function() if paletteOpen then renderPalette(palInput.Text) end end)

-- ══════════════════════════ ВВОД ══════════════════════════
connect(UserInputService.InputBegan, function(input, processed)
	if listening then listening(input); return end
	if paletteOpen and input.UserInputType==Enum.UserInputType.Keyboard then
		if input.KeyCode==Enum.KeyCode.Escape then closePalette(); return end
		if input.KeyCode==Enum.KeyCode.Down then palSelect(palIndex+1); return end
		if input.KeyCode==Enum.KeyCode.Up then palSelect(palIndex-1); return end
		if input.KeyCode==Enum.KeyCode.Return or input.KeyCode==Enum.KeyCode.KeypadEnter then local it = palItems[palIndex]; if it then task.spawn(it.run) end; return end
	end
	local ctrlDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
	if ctrlDown and input.KeyCode==Enum.KeyCode.K then if paletteOpen then closePalette() else openPalette() end; return end
	if ctrlDown and input.KeyCode==Enum.KeyCode.F then if not Window._open then Window:Open() end; task.defer(function() searchInput:CaptureFocus() end); return end
	if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==CONFIG.ToggleKey then Window:Toggle(); return end
	if input.KeyCode==Enum.KeyCode.Escape and Window._open and not processed then if searchInput.Text~="" then searchInput.Text=""; searchInput:ReleaseFocus() else Window:Close() end; return end
	if processed then return end
	for _, b in ipairs(binds) do
		local k = b.get()
		if k and (input.KeyCode==k or input.UserInputType==k) then
			if b.mode=="hold" then b.state=true; if b.callback then task.spawn(b.callback, true) end
			else b.state=not b.state; if b.callback then task.spawn(b.callback, b.state) end end
			refreshBindHud()
		end
	end
end)
connect(UserInputService.InputEnded, function(input)
	for _, b in ipairs(binds) do local k = b.get(); if k and b.mode=="hold" and b.state and (input.KeyCode==k or input.UserInputType==k) then b.state=false; if b.callback then task.spawn(b.callback, false) end; refreshBindHud() end end
end)

addAction("Открыть / закрыть меню", "действие", function() closePalette(); Window:Toggle() end)
addAction("Окно в центр", "действие", function() closePalette(); moved=false; centerPanel() end)
addAction("Свернуть / развернуть", "действие", function() closePalette(); Window:SetMinimized(not minimized) end)
addAction("Случайный акцент", "тема", function() closePalette(); local c = Color3.fromHSV(math.random(), 0.62, 1); local hh = Color3.toHSV(c); Window:SetAccent(c, Color3.fromHSV((hh+0.12)%1, 0.6, 1)); Window:Notify("Акцент обновлён", toHex(c), "good", 1.8) end)
addAction("Сохранить конфиг", "конфиг", function() closePalette(); Window:SaveConfig("default") end)
addAction("Загрузить конфиг", "конфиг", function() closePalette(); Window:LoadConfig("default") end)
addAction("Сбросить все значения", "опасно", function() closePalette(); Window:ResetDefaults() end)
addAction("Экспорт конфига", "конфиг", function() closePalette(); Window:ExportConfig() end)

-- ══════════════════════════ ДЕМО-НАПОЛНЕНИЕ ══════════════════════════
do
	local main = Window:Tab("Main", "grid", "aim & assist")
	main:Section("aim")
	main:Toggle({ Name="Aim Assist", Flag="aim", Default=true, Key=Enum.KeyCode.Q, Tooltip="Помощь в наведении. Q — быстрый переключатель", Callback=function(v) Window:Notify("Aim Assist", v and "включено" or "выключено", v and "good" or "info", 1.8) end })
	main:Slider({ Name="Aim Smoothness", Flag="smooth", Min=1, Max=100, Default=35, Suffix="%", Depends={ Flag="aim" }, Tooltip="Плавность доводки прицела" })
	main:Dropdown({ Name="Target Part", Flag="part", Options={ "Head", "Torso", "Random" }, Default="Head", Depends={ Flag="aim" } })
	main:Keybind({ Name="Aim Key", Flag="aimkey", Default=Enum.UserInputType.MouseButton2, Mode="hold", Tooltip="Удерживай, чтобы целиться", Callback=function(on) print("[RUFU] aim key:", on) end })
	main:Slider({ Name="Field of View", Flag="fov", Min=40, Max=120, Default=90, Suffix="°", Callback=function(v) local cam = workspace.CurrentCamera; if cam then cam.FieldOfView = v end end })
	main:Section("assist")
	main:Toggle({ Name="Prediction", Flag="pred", Default=true, Depends={ Flag="aim" } })
	main:Slider({ Name="Reaction Delay", Flag="delay", Min=0, Max=250, Step=5, Default=60, Suffix=" ms", Depends={ Flag="aim" } })
end

do
	local visuals = Window:Tab("Visuals", "eye", "world & effects")
	visuals:Section("world")
	visuals:Toggle({ Name="Fullbright", Flag="fb", Default=false, Callback=function(v) Lighting.Brightness = v and 2 or 1; Lighting.GlobalShadows = not v end })
	visuals:Toggle({ Name="No Fog", Flag="fog", Default=false, Callback=function(v) Lighting.FogEnd = v and 1e6 or 100000 end })
	visuals:Slider({ Name="Ambient", Flag="amb", Min=0, Max=100, Default=50, Suffix="%", Callback=function(v) local c = math.floor(v*1.6); Lighting.Ambient = Color3.fromRGB(c,c,c) end })
	visuals:Colorpicker({ Name="Ambient Color", Flag="ambcolor", Default=Color3.fromRGB(120,130,160), Tooltip="Цвет окружающего света", Callback=function(c) Lighting.Ambient = c end })
	visuals:Dropdown({ Name="Post Effects", Flag="fx", Multi=true, Options={ "Bloom", "SunRays", "Blur", "DepthOfField", "ColorCorrection" }, Default={ "Bloom" }, Tooltip="Мульти-выбор: можно включить несколько", Callback=function(list)
		local want = {}; for _, v in ipairs(list) do want[v] = true end
		local map = { Bloom="BloomEffect", SunRays="SunRaysEffect", Blur="BlurEffect", DepthOfField="DepthOfFieldEffect", ColorCorrection="ColorCorrectionEffect" }
		for name, class in pairs(map) do
			local existing = Lighting:FindFirstChild("Rufu_"..name)
			if want[name] and not existing then local fx = Instance.new(class); fx.Name = "Rufu_"..name; if class=="BlurEffect" then fx.Size = 4 end; fx.Parent = Lighting
			elseif not want[name] and existing then existing:Destroy() end
		end
	end })
	visuals:Section("player")
	visuals:Toggle({ Name="Third Person", Flag="tp", Default=false, Callback=function(v) LocalPlayer.CameraMode = v and Enum.CameraMode.Classic or Enum.CameraMode.LockFirstPerson end })
end

do
	local playersTab = Window:Tab("Players", "players", "список и аватарки")
	playersTab:Section("server")
	local onlineStat = playersTab:Stat({ Name="Игроков онлайн", Value=#Players:GetPlayers() })
	playersTab:PlayerList({ Name="Players", Flag="target", Callback=function(plr) Window:Notify("Выбран игрок", plr.DisplayName, "info", 1.8) end })
	playersTab:Button({ Name="Телепорт к игроку", Icon="target", Callback=function()
		local target = Window.Flags.target; local plr = target and Players:FindFirstChild(target)
		local myChar, tChar = LocalPlayer.Character, plr and plr.Character
		if myChar and tChar and myChar.PrimaryPart and tChar.PrimaryPart then myChar:PivotTo(tChar:GetPivot()*CFrame.new(0,0,4)); Window:Notify("Телепорт", plr.DisplayName, "good")
		else Window:Notify("Не получилось", "выбери игрока с персонажем", "warn") end
	end })
	local function updateOnline() onlineStat.Set(#Players:GetPlayers()) end
	connect(Players.PlayerAdded, updateOnline); connect(Players.PlayerRemoving, function() task.wait(0.1); updateOnline() end)
end

do
	local misc = Window:Tab("Misc", "misc", "character & misc")
	misc:Section("character")
	misc:Slider({ Name="Walk Speed", Flag="speed", Min=8, Max=120, Default=16, Callback=function(v) local char = LocalPlayer.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); if hum then hum.WalkSpeed = v end end })
	misc:Slider({ Name="Jump Power", Flag="jump", Min=20, Max=200, Default=50, Callback=function(v) local char = LocalPlayer.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); if hum then hum.UseJumpPower = true; hum.JumpPower = v end end })
	misc:Toggle({ Name="Infinite Jump", Flag="infjump", Default=false, Key=Enum.KeyCode.J })
	connect(UserInputService.JumpRequest, function() if Window.Flags.infjump then local char = LocalPlayer.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end end)
	misc:Button({ Name="Reset Character", Danger=true, Callback=function() local char = LocalPlayer.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); if hum then hum.Health = 0 end; Window:Notify("Персонаж сброшен", nil, "warn") end })
end

do
	local settings = Window:Tab("Settings", "sliders", "interface & motion")
	settings:Section("theme")
	settings:Dropdown({ Name="Accent", Flag="accent", Options={ "Azure", "Violet", "Mint", "Sunset", "Mono" }, Default="Azure", Callback=function(v)
		local map = { Azure={ Color3.fromRGB(96,150,255), Color3.fromRGB(146,122,255) }, Violet={ Color3.fromRGB(160,110,255), Color3.fromRGB(230,120,220) }, Mint={ Color3.fromRGB(70,220,170), Color3.fromRGB(90,200,230) }, Sunset={ Color3.fromRGB(255,140,90), Color3.fromRGB(255,90,130) }, Mono={ Color3.fromRGB(226,230,240), Color3.fromRGB(150,156,172) } }
		local c = map[v]; if c then Window:SetAccent(c[1], c[2]) end
	end })
	settings:Colorpicker({ Name="Custom Accent", Flag="customaccent", Default=CONFIG.Accent, Callback=function(c) local hh = Color3.toHSV(c); Window:SetAccent(c, Color3.fromHSV((hh+0.1)%1, 0.65, 1)) end })
	settings:Slider({ Name="UI Scale", Flag="uiscale", Min=80, Max=130, Default=100, Suffix="%", Callback=function(v) Window:SetScale(v/100) end })
	settings:Slider({ Name="Glass", Flag="glass", Min=0, Max=45, Default=12, Suffix="%", Tooltip="Прозрачность стекла панели", Callback=function(v) Window:SetGlass(v/100) end })
	
	settings:Slider({ Name="World Blur", Flag="blursize", Min=0, Max=24, Default=14, Callback=function(v)
		CONFIG.Blur = v
		tween(blur, 0.25, nil, nil, { Size = Window._open and v or 0 })
	end })

	settings:Section("motion")
	settings:Toggle({ Name="Animations", Flag="motionon", Default=true, Tooltip="Выключи, если нужен максимально быстрый отклик", Callback=function(v) setMotionEnabled(v); Window:Notify(v and "Моушен включён" or "Моушен выключен", nil, "info", 1.6) end })
	settings:Slider({ Name="Motion Speed", Flag="motionspeed", Min=50, Max=200, Default=100, Suffix="%", Depends={ Flag="motionon" }, Callback=function(v) Anim.mul = 100/v end })
	settings:Toggle({ Name="Click Sounds", Flag="sounds", Default=false, Callback=function(v) CONFIG.Sounds = v; if v then clickSound(1.8) end end })
	
	settings:Section("hud")
	settings:Toggle({ Name="Watermark", Flag="wm", Default=true, Callback=function(v) Window:SetWatermark(v) end })
	settings:Toggle({ Name="Keybind List", Flag="bindhud", Default=true, Callback=function(v) CONFIG.BindHud = v; if v then refreshBindHud() else tween(bindHud, 0.3, nil, nil, { GroupTransparency=1 }) end end })
	settings:Keybind({ Name="Menu Key", Flag="menukey", Default=CONFIG.ToggleKey, Callback=function(k) if k then CONFIG.ToggleKey = k; keyHint.Text = string.upper(k.Name) .. " · hide   |   Ctrl+K · palette"; Window:Notify("Клавиша меню", k.Name, "good") end end })
	
	settings:Section("about")
	settings:Paragraph("Rufu UI — чистые фреймы, без внешних ассетов. Ctrl+K — палитра, ПКМ по строке — сброс, двойной клик по шапке — в центр, угол — ресайз.")
	settings:Button({ Name="Test Notification", Icon="info", Callback=function() Window:Notify("Rufu UI", "моушен работает", "good") end })
	settings:Button({ Name="Close Menu", Callback=function() Window:Close() end })
end

do
	local configs = Window:Tab("Config", "save", "save / load / export")
	configs:Section("storage")
	local nameInput = configs:Input({ Name="Имя конфига", Flag="cfgname", Default="default", Placeholder="default" })
	local savedNames = FS.list(); if #savedNames==0 then savedNames = { "default" } end
	local savedList = configs:Dropdown({ Name="Сохранённые", Flag="cfglist", Options=savedNames, Default=savedNames[1] })
	configs:Button({ Name="Сохранить", Icon="save", Callback=function() Window:SaveConfig(nameInput.Get()); local l = FS.list(); if #l==0 then l={ "default" } end; savedList.Refresh(l) end })
	configs:Button({ Name="Загрузить", Icon="folder", Callback=function() Window:LoadConfig(Window.Flags.cfglist or nameInput.Get()) end })
	configs:Button({ Name="Удалить", Danger=true, Callback=function() local n = Window.Flags.cfglist; if n then FS.delete(n); local l = FS.list(); if #l==0 then l={ "default" } end; savedList.Refresh(l); Window:Notify("Конфиг удалён", n, "warn") end end })
	configs:Section("share")
	configs:Button({ Name="Экспорт (буфер / консоль)", Icon="copy", Callback=function() Window:ExportConfig() end })
	local importBox = configs:Input({ Name="Импорт JSON", Flag="cfgimport", Default="", Placeholder="вставь JSON и Enter" })
	configs:Button({ Name="Импортировать", Icon="bolt", Callback=function() Window:ImportConfig(Window.Flags.cfgimport); importBox.Set("") end })
	configs:Section("system")
	configs:Toggle({ Name="Auto Save", Flag="autosave", Default=CONFIG.AutoSave, Tooltip="Автосохранение через 1.5 сек после изменения", Callback=function(v) CONFIG.AutoSave = v end })
	configs:Button({ Name="Сбросить всё", Danger=true, Callback=function() Window:ResetDefaults() end })
	configs:Paragraph(FS.available and "Хранилище: файлы (папка Rufu)." or "Хранилище: память сессии (Studio). Экспорт копирует JSON в буфер, если доступно.")
end

-- ══════════════════════════ СТАРТ ══════════════════════════
baseScale = userScale * responsive(); uiScale.Scale = baseScale
keyHint.Text = string.upper(CONFIG.ToggleKey.Name) .. " · hide   |   Ctrl+K · palette"
centerPanel(); curPos = targetPos; root.Position = UDim2.fromOffset(curPos.X, curPos.Y)
layoutShadows(H, true); startLoop(); refreshBindHud(); updateDeps()
task.delay(0.35, function() tween(watermark, 0.5, Enum.EasingStyle.Quint, nil, { GroupTransparency=CONFIG.Watermark and 0 or 1 }) end)
task.delay(0.6, function()
	if CONFIG.AutoSave and FS.read("autosave") then
		local raw = FS.read("autosave"); local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
		if ok and typeof(data)=="table" then Window:ApplyConfig(data); Window:Notify("Автосохранение загружено", nil, "info", 2.2) end
	end
end)
if CONFIG.OpenOnStart then task.delay(0.4, function() Window:Open() end) end
task.delay(1.1, function() Window:Notify(CONFIG.Title.." UI загружен", CONFIG.ToggleKey.Name.." · меню,  Ctrl+K · палитра", "good", 3.4) end)
print("[RUFU UI] "..CONFIG.Version.." — "..CONFIG.ToggleKey.Name.." открыть, Ctrl+K палитра")
