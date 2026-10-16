-- Coloque em ServerScriptService junto do TrucoServer.
-- A rua e os bares são construídos quando o servidor inicia.

local Lighting = game:GetService("Lighting")

local existing = workspace:FindFirstChild("RuaDasManilhas")
local street = existing or Instance.new("Model")
street.Name = "RuaDasManilhas"
street.Parent = workspace

local WOOD = Color3.fromRGB(111, 67, 40)
local DARK_WOOD = Color3.fromRGB(57, 35, 29)
local CREAM = Color3.fromRGB(239, 219, 174)
local GOLD = Color3.fromRGB(255, 196, 94)
local GREEN = Color3.fromRGB(22, 100, 65)
local RED = Color3.fromRGB(106, 36, 55)

local function part(parent, name, size, position, color, material)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.Position = position
	item.Anchored = true
	item.Color = color
	item.Material = material or Enum.Material.SmoothPlastic
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

local function sign(parent, name, text, size, position, face, color)
	local board = part(parent, name, size, position, DARK_WOOD, Enum.Material.Wood)
	local surface = Instance.new("SurfaceGui")
	surface.Name = "Letreiro"
	surface.Face = face
	surface.PixelsPerStud = 38
	surface.LightInfluence = 0
	surface.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or GOLD
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = surface
	return board
end

local function chair(model, kind, id, index, center, offset)
	local position = center + offset
	local seat = Instance.new("Seat")
	seat.Name = "Seat" .. index
	seat.Size = Vector3.new(2.7, 0.55, 2.7)
	seat.CFrame = CFrame.lookAt(position, Vector3.new(center.X, position.Y, center.Z))
	seat.Anchored = true
	seat.Color = kind == "Truco" and (index % 2 == 1
		and Color3.fromRGB(49, 103, 154) or Color3.fromRGB(154, 63, 61)) or DARK_WOOD
	seat.Material = Enum.Material.Wood
	seat.TopSurface = Enum.SurfaceType.Smooth
	seat.BottomSurface = Enum.SurfaceType.Smooth
	seat:SetAttribute("TableId", id)
	seat:SetAttribute("SeatIndex", index)
	seat:SetAttribute("GameKind", kind)
	seat.Parent = model

	local outward = Vector3.new(offset.X, 0, offset.Z).Unit
	local back = part(model, "Encosto" .. index, Vector3.new(2.9, 2.2, 0.35),
		position + outward * 1.25 + Vector3.new(0, 1.15, 0), WOOD, Enum.Material.Wood)
	back.CFrame = CFrame.lookAt(back.Position, center + Vector3.new(0, 1.15, 0))
	part(model, "PeCadeira" .. index, Vector3.new(0.75, 1.1, 0.75),
		position - Vector3.new(0, 0.82, 0), DARK_WOOD, Enum.Material.Wood)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Sentar"
	prompt.ActionText = "Sentar"
	prompt.ObjectText = kind == "Truco"
		and ("Truco " .. id .. " | Dupla " .. (index % 2 == 1 and "Azul" or "Vermelha"))
		or ("Pôquer " .. id .. " | em breve")
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat
	return seat
end

local function chipStack(model, name, x, z, color, count)
	for level = 1, count do
		local chip = part(model, name .. level, Vector3.new(0.15, 0.8, 0.8),
			Vector3.new(x, 4.12 + (level - 1) * 0.14, z), color, Enum.Material.SmoothPlastic)
		chip.Shape = Enum.PartType.Cylinder
		chip.CFrame = chip.CFrame * CFrame.Angles(0, 0, math.rad(90))
		chip.CanCollide = false
	end
end

local function makeTable(folder, kind, id, x, z)
	local model = Instance.new("Model")
	model.Name = kind .. "Mesa" .. id
	model:SetAttribute("TableId", id)
	model:SetAttribute("GameKind", kind)
	model.Parent = folder
	local center = Vector3.new(x, 1.55, z)
	part(model, "Tampo", Vector3.new(8.8, 0.55, 8.8), Vector3.new(x, 3.65, z), WOOD, Enum.Material.Wood)
	part(model, "Feltro", Vector3.new(7.6, 0.08, 7.6), Vector3.new(x, 3.97, z),
		kind == "Truco" and GREEN or RED, Enum.Material.Fabric)
	part(model, "PeMesa", Vector3.new(1.5, 2.8, 1.5), Vector3.new(x, 2.15, z), DARK_WOOD, Enum.Material.Wood)
	part(model, "BaseMesa", Vector3.new(4, 0.3, 4), Vector3.new(x, 0.9, z), DARK_WOOD, Enum.Material.Wood)
	local offsets = {
		Vector3.new(0, 0, -6.3), Vector3.new(6.3, 0, 0),
		Vector3.new(0, 0, 6.3), Vector3.new(-6.3, 0, 0),
	}
	for index, offset in ipairs(offsets) do
		chair(model, kind, id, index, center, offset)
	end
	if kind == "Poker" then
		local colors = {
			Color3.fromRGB(219, 60, 65), Color3.fromRGB(51, 112, 192),
			Color3.fromRGB(231, 218, 184), Color3.fromRGB(49, 46, 48),
		}
		for index, color in ipairs(colors) do
			local dx = index % 2 == 0 and 2.4 or -2.4
			local dz = index <= 2 and -2.4 or 2.4
			chipStack(model, "Fichas" .. index .. "_", x + dx, z + dz, color, 6 + index)
		end
		for index = 1, 3 do
			local card = part(model, "CartaDecorativa" .. index, Vector3.new(1.1, 0.05, 1.55),
				Vector3.new(x + (index - 2) * 1.4, 4.05, z), CREAM)
			card.CanCollide = false
			local surface = Instance.new("SurfaceGui")
			surface.Face = Enum.NormalId.Top
			surface.PixelsPerStud = 70
			surface.Parent = card
			local mark = Instance.new("TextLabel")
			mark.Size = UDim2.fromScale(1, 1)
			mark.BackgroundTransparency = 1
			mark.Text = "♠"
			mark.TextColor3 = RED
			mark.TextScaled = true
			mark.Font = Enum.Font.GothamBlack
			mark.Parent = surface
		end
	end
	local lamp = part(model, "Luminaria", Vector3.new(2.1, 0.4, 2.1),
		Vector3.new(x, 11.3, z), GOLD, Enum.Material.Neon)
	lamp.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = GOLD
	light.Range = 19
	light.Brightness = 1.2
	light.Parent = lamp
	return model
end

local function makeVenue(parent, name, subtitle, x, z, facing, accent, kind, firstId)
	local venue = Instance.new("Model")
	venue.Name = name:gsub(" ", "")
	venue.Parent = parent
	local floor = part(venue, "Piso", Vector3.new(51, 0.8, 46),
		Vector3.new(x, 0.55, z), Color3.fromRGB(101, 69, 49), Enum.Material.WoodPlanks)
	floor.CanCollide = true
	part(venue, "ParedeFundo", Vector3.new(51, 14, 1),
		Vector3.new(x, 7.6, z + 23), accent, Enum.Material.Brick)
	part(venue, "ParedeFrente", Vector3.new(51, 14, 1),
		Vector3.new(x, 7.6, z - 23), accent, Enum.Material.Brick)
	local outerX = x - facing * 25.5
	local doorX = x + facing * 25.5
	part(venue, "PassarelaDaEntrada", Vector3.new(8, 0.8, 19),
		Vector3.new(doorX + facing * 3.5, 0.55, z),
		Color3.fromRGB(154, 141, 122), Enum.Material.Concrete)
	part(venue, "ParedeExterna", Vector3.new(1, 14, 46),
		Vector3.new(outerX, 7.6, z), accent, Enum.Material.Brick)
	for _, dz in ipairs({ -16.5, 16.5 }) do
		part(venue, "ParedeDaEntrada", Vector3.new(1, 14, 13),
			Vector3.new(doorX, 7.6, z + dz), accent, Enum.Material.Brick)
	end
	part(venue, "ArcoDaPorta", Vector3.new(1, 3, 20),
		Vector3.new(doorX, 13.1, z), DARK_WOOD, Enum.Material.Wood)
	sign(venue, "LetreiroPrincipal", name .. " | " .. subtitle,
		Vector3.new(0.7, 3.5, 29), Vector3.new(doorX + facing * 0.5, 11.1, z),
		facing == 1 and Enum.NormalId.Right or Enum.NormalId.Left, GOLD)
	local counterX = x - facing * 18
	part(venue, "Balcao", Vector3.new(3, 3.3, 28),
		Vector3.new(counterX, 2.7, z), DARK_WOOD, Enum.Material.Wood)
	part(venue, "TampoBalcao", Vector3.new(4, 0.35, 30),
		Vector3.new(counterX, 4.5, z), WOOD, Enum.Material.Wood)
	for i = 1, 7 do
		local bottle = part(venue, "Garrafa" .. i, Vector3.new(0.7, 1.5, 0.7),
			Vector3.new(counterX, 5.45, z - 12 + (i - 1) * 4),
			i % 2 == 0 and Color3.fromRGB(49, 122, 94) or Color3.fromRGB(153, 73, 44), Enum.Material.Glass)
		bottle.CanCollide = false
	end
	local lightStrip = part(venue, "LuzDaFachada", Vector3.new(0.3, 0.3, 29),
		Vector3.new(doorX + facing * 0.65, 8.7, z), GOLD, Enum.Material.Neon)
	lightStrip.CanCollide = false
	if kind == "Poker" then
		part(venue, "TapeteDoClube", Vector3.new(8, 0.06, 9),
			Vector3.new(doorX + facing * 3.5, 0.99, z), RED, Enum.Material.Fabric)
		for _, dz in ipairs({ -11, 11 }) do
			part(venue, "ColunaDourada", Vector3.new(0.7, 8.5, 0.7),
				Vector3.new(doorX + facing * 1.2, 5.2, z + dz), GOLD, Enum.Material.Metal)
		end
	else
		for i = 1, 5 do
			local bulb = part(venue, "LampadaBoteco" .. i, Vector3.new(0.45, 0.45, 0.45),
				Vector3.new(doorX + facing * 0.9, 8.6, z - 12 + (i - 1) * 6),
				GOLD, Enum.Material.Neon)
			bulb.Shape = Enum.PartType.Ball
			bulb.CanCollide = false
		end
	end
	local folder = kind == "Truco" and street.MesasTruco or street.MesasPoker
	local tableX = x + facing * 4
	makeTable(folder, kind, firstId, tableX, z - 11)
	makeTable(folder, kind, firstId + 1, tableX, z + 11)
	return venue
end

if not existing then
	local trucoFolder = Instance.new("Folder")
	trucoFolder.Name = "MesasTruco"
	trucoFolder.Parent = street
	local pokerFolder = Instance.new("Folder")
	pokerFolder.Name = "MesasPoker"
	pokerFolder.Parent = street

	part(street, "Asfalto", Vector3.new(38, 0.8, 215),
		Vector3.new(0, 0.35, 0), Color3.fromRGB(43, 45, 48), Enum.Material.Asphalt)
	for _, x in ipairs({ -23, 23 }) do
		part(street, "Calcada", Vector3.new(9, 0.8, 215),
			Vector3.new(x, 0.55, 0), Color3.fromRGB(154, 141, 122), Enum.Material.Concrete)
	end
	for z = -98, 98, 16 do
		part(street, "FaixaCentral", Vector3.new(0.45, 0.04, 7),
			Vector3.new(0, 0.78, z), Color3.fromRGB(244, 199, 104), Enum.Material.Neon)
	end
	for _, z in ipairs({ -78, -8, 78 }) do
		for _, x in ipairs({ -24, 24 }) do
			part(street, "Poste", Vector3.new(0.55, 11, 0.55),
				Vector3.new(x, 6.1, z), DARK_WOOD, Enum.Material.Metal)
			local glow = part(street, "LuzRua", Vector3.new(1.8, 0.5, 1.8),
				Vector3.new(x, 11.8, z), GOLD, Enum.Material.Neon)
			glow.CanCollide = false
			local point = Instance.new("PointLight")
			point.Color = GOLD
			point.Range = 30
			point.Brightness = 1.7
			point.Parent = glow
		end
	end
	part(street, "VaralDeLuzes", Vector3.new(38, 0.08, 0.08),
		Vector3.new(0, 12, 0), DARK_WOOD, Enum.Material.Metal)
	for x = -16, 16, 4 do
		local bulb = part(street, "LuzDoVaral", Vector3.new(0.6, 0.6, 0.6),
			Vector3.new(x, 11.7, 0), GOLD, Enum.Material.Neon)
		bulb.Shape = Enum.PartType.Ball
		bulb.CanCollide = false
	end
	sign(street, "PlacaDaRua", "RUA DAS MANILHAS",
		Vector3.new(22, 3, 0.6), Vector3.new(0, 12, 89), Enum.NormalId.Back, GOLD)
	part(street, "SuporteDaPlaca", Vector3.new(0.7, 11, 0.7),
		Vector3.new(0, 6, 89), DARK_WOOD, Enum.Material.Metal)

	makeVenue(street, "Boteco do Zap", "TRUCO", -59, 47, 1,
		Color3.fromRGB(102, 64, 49), "Truco", 1)
	makeVenue(street, "Cantina da Canga", "TRUCO", -59, -47, 1,
		Color3.fromRGB(111, 80, 48), "Truco", 3)
	makeVenue(street, "Royal do Blefe", "PÔQUER EM BREVE", 59, 47, -1,
		Color3.fromRGB(70, 49, 79), "Poker", 1)
	makeVenue(street, "Dama da Meia-Noite", "PÔQUER EM BREVE", 59, -47, -1,
		Color3.fromRGB(55, 67, 91), "Poker", 3)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "EntradaDaRua"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 1.45, 102)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = street
	for _, child in ipairs(workspace:GetChildren()) do
		if child:IsA("SpawnLocation") then child.Enabled = false end
	end
	spawn.Enabled = true

	Lighting.ClockTime = 19
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(93, 78, 74)
	Lighting.OutdoorAmbient = Color3.fromRGB(67, 70, 81)
end

-- Também funciona com uma rua já salva e personalizada no Studio.
for _, descendant in ipairs(street:GetDescendants()) do
	if descendant:IsA("Seat") then
		local seat = descendant
		local prompt = seat:FindFirstChild("Sentar")
		if not prompt then
			prompt = Instance.new("ProximityPrompt")
			prompt.Name = "Sentar"
			prompt.ActionText = "Sentar"
			prompt.ObjectText = seat:GetAttribute("GameKind") or "Mesa"
			prompt.MaxActivationDistance = 8
			prompt.RequiresLineOfSight = false
			prompt.Parent = seat
		end
		local function updatePrompt()
			prompt.Enabled = seat.Occupant == nil
		end
		seat:GetPropertyChangedSignal("Occupant"):Connect(updatePrompt)
		updatePrompt()
		prompt.Triggered:Connect(function(player)
			if seat.Occupant then return end
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not humanoid or not root or humanoid.Health <= 0 then return end
			if (root.Position - seat.Position).Magnitude > 11 then return end
			seat:Sit(humanoid)
		end)
	end
end
