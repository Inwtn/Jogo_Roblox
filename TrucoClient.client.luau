-- Coloque em StarterPlayer > StarterPlayerScripts.
-- A câmera mostra o personagem e cartas locais sobre a mesa; comandos ficam no rodapé.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("TrucoMineiroEvent")
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("TrucoMineiroGui")
if old then old:Destroy() end
local oldCards = workspace:FindFirstChild("CartasLocaisDoTruco")
if oldCards then oldCards:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "TrucoMineiroGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui
local cardsFolder = Instance.new("Folder")
cardsFolder.Name = "CartasLocaisDoTruco"
cardsFolder.Parent = workspace

local function create(className, parent, properties)
	local object = Instance.new(className)
	for property, value in pairs(properties) do object[property] = value end
	object.Parent = parent
	return object
end

local function round(object)
	create("UICorner", object, { CornerRadius = UDim.new(0, 9) })
end
local function label(parent, text, position, size, textSize, background)
	local item = create("TextLabel", parent, {
		Text = text, Position = position, Size = size,
		BackgroundColor3 = background or Color3.fromRGB(27, 34, 35),
		BackgroundTransparency = background and 0.12 or 1,
		TextColor3 = Color3.fromRGB(253, 238, 206), TextSize = textSize,
		TextWrapped = true, Font = Enum.Font.GothamBold, BorderSizePixel = 0,
	})
	if background then round(item) end
	return item
end
local function button(parent, text, position, size, color)
	local item = create("TextButton", parent, {
		Text = text, Position = position, Size = size,
		BackgroundColor3 = color, TextColor3 = Color3.fromRGB(255, 247, 228),
		TextSize = 16, TextWrapped = true, Font = Enum.Font.GothamBold,
		BorderSizePixel = 0, AutoButtonColor = true,
	})
	round(item)
	return item
end

local top = create("Frame", gui, {
	Size = UDim2.new(0.94, 0, 0, 94), Position = UDim2.new(0.5, 0, 0, 8),
	AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = Color3.fromRGB(23, 30, 30),
	BackgroundTransparency = 0.13, BorderSizePixel = 0,
})
round(top)
top.Visible = false
create("UISizeConstraint", top, { MaxSize = Vector2.new(850, 94) })
local title = label(top, "RUA DAS MANILHAS", UDim2.new(0.02, 0, 0, 5), UDim2.new(0.78, 0, 0, 25), 17)
local score = label(top, "", UDim2.new(0.02, 0, 0, 32), UDim2.new(0.96, 0, 0, 23), 15)
local status = label(top, "", UDim2.new(0.02, 0, 0, 57), UDim2.new(0.96, 0, 0, 31), 14)
local leave = button(top, "LEVANTAR", UDim2.new(0.80, 0, 0, 6),
	UDim2.new(0.18, 0, 0, 27), Color3.fromRGB(112, 63, 53))
leave.TextSize = 12
leave.Activated:Connect(function() remote:FireServer("stand") end)
local hint = label(gui, "Aproxime-se de uma cadeira e aperte E para sentar.",
	UDim2.new(0.5, 0, 0, 13), UDim2.new(0.86, 0, 0, 54), 16, Color3.fromRGB(26, 36, 36))
hint.AnchorPoint = Vector2.new(0.5, 0)
create("UISizeConstraint", hint, { MaxSize = Vector2.new(700, 54) })

local controls = create("Frame", gui, {
	Size = UDim2.new(0.96, 0, 0, 139), Position = UDim2.new(0.5, 0, 1, -8),
	AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = Color3.fromRGB(23, 30, 30),
	BackgroundTransparency = 0.12, BorderSizePixel = 0,
})
round(controls)
controls.Visible = false
create("UISizeConstraint", controls, { MaxSize = Vector2.new(770, 139) })
local handButtons = {}
local SUITS = { C = "♣", H = "♥", S = "♠", D = "♦" }
local NEXT_BET = { [2] = 4, [4] = 6, [6] = 10, [10] = 12 }
local VENUES = {
	truco = { "BOTECO DO ZAP", "BOTECO DO ZAP", "CANTINA DA CANGA", "CANTINA DA CANGA" },
	poker = { "ROYAL DO BLEFE", "ROYAL DO BLEFE", "DAMA DA MEIA-NOITE", "DAMA DA MEIA-NOITE" },
}
local coveredMode = false
local currentState
local function cardText(card)
	if not card then return "" end
	if card.hidden or card.covered then return "?" end
	return card.rank .. (SUITS[card.suit] or "?")
end
for index = 1, 3 do
	local cardIndex = index
	local item = button(controls, "", UDim2.new((index - 1) / 3 + 0.01, 0, 0, 7),
		UDim2.new(0.313, 0, 0, 54), Color3.fromRGB(230, 218, 189))
	item.TextColor3 = Color3.fromRGB(33, 41, 41)
	item.TextSize = 22
	item.Activated:Connect(function()
		if currentState and currentState.kind == "truco" and currentState.phase == "playing"
			and currentState.turnSeat == currentState.seat and currentState.hand[cardIndex] then
			remote:FireServer("play", cardIndex, coveredMode)
			coveredMode = false
		end
	end)
	handButtons[index] = item
end
local actions = {
	button(controls, "", UDim2.new(0.01, 0, 0, 72), UDim2.new(0.23, 0, 0, 55), Color3.fromRGB(56, 119, 82)),
	button(controls, "", UDim2.new(0.26, 0, 0, 72), UDim2.new(0.23, 0, 0, 55), Color3.fromRGB(162, 71, 62)),
	button(controls, "", UDim2.new(0.51, 0, 0, 72), UDim2.new(0.23, 0, 0, 55), Color3.fromRGB(166, 105, 45)),
	button(controls, "", UDim2.new(0.76, 0, 0, 72), UDim2.new(0.23, 0, 0, 55), Color3.fromRGB(100, 90, 66)),
}
local actionNames = {}
for index, item in ipairs(actions) do
	local actionIndex = index
	item.Activated:Connect(function()
		local action = actionNames[actionIndex]
		if action == "cover" then
			coveredMode = not coveredMode
			item.Text = coveredMode and "Coberta: SIM" or "Carta coberta"
		elseif action then
			remote:FireServer(action)
		end
	end)
end
local function setActions(options)
	for index, item in ipairs(actions) do
		local option = options[index]
		item.Visible = option ~= nil
		actionNames[index] = option and option[1] or nil
		if option then item.Text = option[2] end
	end
end

local cameraBound = false
local previousFov = 70
local cameraSeat
local cameraTable
local function stopCamera()
	if cameraBound then
		RunService:UnbindFromRenderStep("TrucoMesaCamera")
		cameraBound = false
	end
	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then camera.CameraSubject = humanoid end
		camera.FieldOfView = previousFov
	end
	cameraSeat = nil
	cameraTable = nil
end
local function updateCamera(state)
	if state.kind ~= "truco" and state.kind ~= "poker" then
		if cameraBound then stopCamera() end
		return nil
	end
	local street = workspace:FindFirstChild("RuaDasManilhas")
	local folder = street and street:FindFirstChild(state.kind == "truco" and "MesasTruco" or "MesasPoker")
	local model = folder and folder:FindFirstChild((state.kind == "truco" and "TrucoMesa" or "PokerMesa") .. state.tableId)
	local seat = model and model:FindFirstChild("Seat" .. state.seat)
	local topPart = model and model:FindFirstChild("Tampo")
	if not seat or not topPart then return model end
	cameraSeat = seat
	cameraTable = topPart
	if not cameraBound then
		local camera = workspace.CurrentCamera
		if camera then previousFov = camera.FieldOfView end
		RunService:BindToRenderStep("TrucoMesaCamera", Enum.RenderPriority.Camera.Value + 1, function()
			local current = workspace.CurrentCamera
			if not current or not cameraSeat or not cameraTable then return end
			local forward = cameraSeat.CFrame.LookVector
			local right = cameraSeat.CFrame.RightVector
			local position = cameraSeat.Position - forward * 3.6 + right * 1.25 + Vector3.new(0, 6.1, 0)
			local focus = cameraTable.Position + Vector3.new(0, 0.75, 0)
			current.CameraType = Enum.CameraType.Scriptable
			current.CFrame = CFrame.lookAt(position, focus)
			current.Focus = CFrame.new(focus)
			current.FieldOfView = 66
		end)
		cameraBound = true
	end
	return model
end

local turnMarker
local function clearCards()
	for _, child in ipairs(cardsFolder:GetChildren()) do child:Destroy() end
	if turnMarker then
		turnMarker:Destroy()
		turnMarker = nil
	end
end
local function visualCard(position, card, name)
	local back = card == nil or card.hidden or card.covered
	local item = create("Part", cardsFolder, {
		Name = name, Size = Vector3.new(1.1, 0.07, 1.55), Position = position,
		Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
		Color = back and Color3.fromRGB(38, 90, 139) or Color3.fromRGB(250, 244, 223),
		Material = Enum.Material.SmoothPlastic,
	})
	local surface = create("SurfaceGui", item, {
		Face = Enum.NormalId.Top, PixelsPerStud = 80, LightInfluence = 0,
	})
	create("TextLabel", surface, {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Text = back and "◆" or cardText(card),
		TextColor3 = back and Color3.fromRGB(223, 212, 164)
			or ((card.suit == "D" or card.suit == "H") and Color3.fromRGB(184, 40, 45)
				or Color3.fromRGB(33, 36, 37)),
		TextScaled = true, Font = Enum.Font.GothamBlack,
	})
end
local function renderCards(state, model)
	clearCards()
	if not model or state.kind ~= "truco" then return end
	local tabletop = model:FindFirstChild("Tampo")
	if not tabletop then return end
	local center = tabletop.Position + Vector3.new(0, 0.48, 0)
	for seatIndex = 1, 4 do
		local seat = model:FindFirstChild("Seat" .. seatIndex)
		if seat then
			local outward = Vector3.new(seat.Position.X - center.X, 0, seat.Position.Z - center.Z).Unit
			local sideways = Vector3.new(-outward.Z, 0, outward.X)
			local count = state.cardCounts[seatIndex] or 0
			for index = 1, count do
				local card
				if seatIndex == state.seat then
					card = state.hand[index]
				elseif state.phase == "decide10" and seatIndex == ((state.seat + 1) % 4) + 1 then
					card = state.partnerHand[index]
				end
				visualCard(center + outward * 2.75 + sideways * ((index - (count + 1) / 2) * 1.25),
					card, "Mao_" .. seatIndex .. "_" .. index)
			end
		end
	end
	for index, entry in ipairs(state.played) do
		local seat = model:FindFirstChild("Seat" .. entry.seat)
		if seat then
			local outward = Vector3.new(seat.Position.X - center.X, 0, seat.Position.Z - center.Z).Unit
			visualCard(center + outward * 0.95 + Vector3.new(0, index * 0.012, 0),
				entry.card, "Jogada_" .. index)
		end
	end
	if state.phase == "playing" and state.turnSeat then
		local turnSeat = model:FindFirstChild("Seat" .. state.turnSeat)
		if turnSeat then
			turnMarker = create("BillboardGui", playerGui, {
				Name = "IndicadorDaVez", Adornee = turnSeat,
				Size = UDim2.fromOffset(150, 38),
				StudsOffsetWorldSpace = Vector3.new(0, 4.7, 0),
				AlwaysOnTop = true, MaxDistance = 70,
			})
			local textLabel = create("TextLabel", turnMarker, {
				Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(237, 174, 71),
				BackgroundTransparency = 0.12, TextColor3 = Color3.fromRGB(42, 31, 24),
				Text = "VEZ DE JOGAR", TextScaled = true, Font = Enum.Font.GothamBlack,
				BorderSizePixel = 0,
			})
			round(textLabel)
		end
	end
end

local function render(state)
	currentState = state
	local model = updateCamera(state)
	renderCards(state, model)
	if state.kind == "lobby" then
		hint.Visible = true
		top.Visible = false
		controls.Visible = false
		hint.Text = "Rua das Manilhas  •  E para sentar  •  " .. table.concat(state.tables or {}, "  |  ")
		return
	end
	hint.Visible = false
	top.Visible = true
	controls.Visible = state.kind == "truco"
	if state.kind == "poker" then
		title.Text = VENUES.poker[state.tableId] .. "  •  PÔQUER " .. state.tableId
		score.Text = "Fichas na mesa • Regras de pôquer em preparação"
		status.Text = "Explore o salão ou clique em Levantar."
		return
	end
	local team = state.seat % 2 == 1 and "AZUL" or "VERMELHA"
	title.Text = VENUES.truco[state.tableId] .. "  •  TRUCO " .. state.tableId .. "  •  " .. team
	score.Text = "Azul " .. state.scores[1] .. "  ×  " .. state.scores[2]
		.. " Vermelha     |     Mão " .. state.handNumber .. "  •  Rodada " .. state.round
		.. "  •  Vale " .. state.handValue
	status.Text = state.status
	local canPlay = state.phase == "playing" and state.turnSeat == state.seat
	for index, item in ipairs(handButtons) do
		local card = state.hand[index]
		item.Visible = card ~= nil
		item.Active = canPlay and card ~= nil
		item.AutoButtonColor = item.Active
		item.BackgroundColor3 = item.Active and Color3.fromRGB(239, 226, 194)
			or Color3.fromRGB(148, 147, 135)
		item.Text = card and ("Jogar " .. cardText(card)) or ""
	end
	local options = {}
	if state.canRespond then
		table.insert(options, { "accept", "Aceitar " .. state.offerValue })
		table.insert(options, { "run", "Correr" })
		if NEXT_BET[state.offerValue] then
			table.insert(options, { "counter", "Pedir " .. NEXT_BET[state.offerValue] })
		end
	elseif state.canDecide then
		table.insert(options, { "play10", "Jogar mão de 10" })
		table.insert(options, { "run10", "Correr" })
	elseif state.canRaise then
		table.insert(options, { "raise", "TRUCO! " .. NEXT_BET[state.handValue] })
	end
	if canPlay and state.round > 1 and state.special ~= "iron" then
		table.insert(options, { "cover", coveredMode and "Coberta: SIM" or "Carta coberta" })
	else
		coveredMode = false
	end
	setActions(options)
end

remote.OnClientEvent:Connect(function(kind, state)
	if kind == "state" then render(state) end
end)
player.CharacterAdded:Connect(function()
	task.delay(0.5, function() remote:FireServer("ready") end)
end)
remote:FireServer("ready")
