-- Coloque este Script em ServerScriptService junto do BarBuilder.
-- Cada mesa de truco tem sua própria partida; sentar define o assento e a dupla.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remote = ReplicatedStorage:FindFirstChild("TrucoMineiroEvent")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "TrucoMineiroEvent"
	remote.Parent = ReplicatedStorage
end

local bar = workspace:WaitForChild("RuaDasManilhas", 30)
assert(bar, "Coloque BarBuilder.server.luau em ServerScriptService para criar a rua.")
local trucoFolder = bar:WaitForChild("MesasTruco", 30)
local pokerFolder = bar:WaitForChild("MesasPoker", 30)
assert(trucoFolder and pokerFolder, "O bar precisa das pastas MesasTruco e MesasPoker.")

local random = Random.new()
local RANKS = { "4", "5", "6", "7", "Q", "J", "K", "A", "2", "3" }
local SUITS = { "D", "S", "H", "C" }
local BET_VALUES = { 2, 4, 6, 10, 12 }
local rankStrength = {}
for index, rank in ipairs(RANKS) do
	rankStrength[rank] = index
end

local sessions = {}
for id = 1, 4 do
	local model = trucoFolder:WaitForChild("TrucoMesa" .. id, 30)
	assert(model, "Mesa de truco " .. id .. " não encontrada no bar.")
	local seatParts = {}
	for seat = 1, 4 do
		seatParts[seat] = model:WaitForChild("Seat" .. seat, 30)
		assert(seatParts[seat], "Cadeira " .. seat .. " não encontrada na mesa " .. id)
	end
	sessions[id] = {
		id = id,
		seatParts = seatParts,
		players = {},
		scores = { 0, 0 },
		phase = "waiting",
		handNumber = 0,
		generation = 0,
		status = "Aguardando quatro jogadores nesta mesa...",
	}
end

local function seatedPlayer(seatPart)
	local humanoid = seatPart.Occupant
	return humanoid and Players:GetPlayerFromCharacter(humanoid.Parent) or nil
end

local function teamOf(seat)
	return (seat % 2 == 1) and 1 or 2
end

local function otherTeam(team)
	return (team == 1) and 2 or 1
end

local function nextSeat(seat)
	return (seat % 4) + 1
end

local function seatOf(session, player)
	for seat = 1, 4 do
		if session.players[seat] == player and seatedPlayer(session.seatParts[seat]) == player then
			return seat
		end
	end
	return nil
end

local function fullTable(session)
	for seat = 1, 4 do
		if not session.players[seat] or seatedPlayer(session.seatParts[seat]) ~= session.players[seat] then
			return false
		end
	end
	return true
end

local function cardStrength(card)
	if card.rank == "7" and card.suit == "D" then return 11 end
	if card.rank == "A" and card.suit == "S" then return 12 end
	if card.rank == "7" and card.suit == "H" then return 13 end
	if card.rank == "4" and card.suit == "C" then return 14 end
	return rankStrength[card.rank]
end

local function nextBet(value)
	for index, amount in ipairs(BET_VALUES) do
		if amount == value then return BET_VALUES[index + 1] end
	end
	return nil
end

local function makeDeck()
	local deck = {}
	for _, suit in ipairs(SUITS) do
		for _, rank in ipairs(RANKS) do
			table.insert(deck, { rank = rank, suit = suit })
		end
	end
	for index = #deck, 2, -1 do
		local swap = random:NextInteger(1, index)
		deck[index], deck[swap] = deck[swap], deck[index]
	end
	return deck
end

local function publicCard(card, covered)
	if covered then return { covered = true } end
	return { rank = card.rank, suit = card.suit }
end

local function canRaise(session, seat)
	return session.phase == "playing"
		and session.turnSeat == seat
		and session.special == nil
		and nextBet(session.handValue) ~= nil
		and (session.lastRaiseTeam == nil or session.lastRaiseTeam ~= teamOf(seat))
end

local function trucoState(session, player, seat)
	local names = {}
	local counts = {}
	for index = 1, 4 do
		local occupant = session.players[index]
		names[index] = occupant and occupant.DisplayName or "Vago"
		counts[index] = session.hands and session.hands[index] and #session.hands[index] or 0
	end

	local hand = {}
	if session.hands and session.hands[seat] then
		for _, card in ipairs(session.hands[seat]) do
			if session.special == "iron" then
				table.insert(hand, { hidden = true })
			else
				table.insert(hand, publicCard(card, false))
			end
		end
	end

	local partnerHand = {}
	if session.phase == "decide10" and teamOf(seat) == session.decisionTeam then
		local partnerSeat = nextSeat(nextSeat(seat))
		for _, card in ipairs(session.hands[partnerSeat]) do
			table.insert(partnerHand, publicCard(card, false))
		end
	end

	local played = {}
	for _, entry in ipairs(session.played or {}) do
		table.insert(played, {
			seat = entry.seat,
			card = publicCard(entry.card, entry.covered),
		})
	end

	return {
		kind = "truco",
		seated = true,
		tableId = session.id,
		phase = session.phase,
		status = session.status,
		seat = seat,
		seatNames = names,
		cardCounts = counts,
		scores = { session.scores[1], session.scores[2] },
		handNumber = session.handNumber,
		round = session.round or 0,
		roundResults = session.roundResults or {},
		handValue = session.handValue or 2,
		offerValue = session.offerValue,
		offerSeat = session.offerSeat,
		turnSeat = session.turnSeat,
		decisionTeam = session.decisionTeam,
		special = session.special,
		canRaise = canRaise(session, seat),
		canRespond = session.phase == "offer" and session.responseSeat == seat,
		canDecide = session.phase == "decide10" and teamOf(seat) == session.decisionTeam,
		hand = hand,
		partnerHand = partnerHand,
		played = played,
	}
end

local function findTrucoSeat(player)
	for _, session in ipairs(sessions) do
		local seat = seatOf(session, player)
		if seat then return session, seat end
	end
	return nil, nil
end

local function findPokerSeat(player)
	for id = 1, 4 do
		local model = pokerFolder:FindFirstChild("PokerMesa" .. id)
		if model then
			for seat = 1, 4 do
				local seatPart = model:FindFirstChild("Seat" .. seat)
				if seatPart and seatedPlayer(seatPart) == player then return id, seat end
			end
		end
	end
	return nil
end

local function stateFor(player)
	local session, seat = findTrucoSeat(player)
	if session then return trucoState(session, player, seat) end
	local pokerId, pokerSeat = findPokerSeat(player)
	if pokerId then
		return {
			kind = "poker", seated = true, tableId = pokerId, seat = pokerSeat,
			status = "Mesa de pôquer " .. pokerId .. ": jogo em preparação. Pule para levantar.",
		}
	end
	local tables = {}
	for _, current in ipairs(sessions) do
		local count = 0
		for index = 1, 4 do
			if seatedPlayer(current.seatParts[index]) then count += 1 end
		end
		table.insert(tables, "Truco " .. current.id .. "  " .. count .. "/4")
	end
	return {
		kind = "lobby", seated = false,
		status = "Bem-vindo ao bar! Aproxime-se de uma cadeira e aperte E para sentar.",
		tables = tables,
	}
end

local function sendState(player)
	if player.Parent == Players then
		remote:FireClient(player, "state", stateFor(player))
	end
end

local function broadcastAll()
	for _, player in ipairs(Players:GetPlayers()) do
		sendState(player)
	end
end

local startHand
local endHand

local function resolveRound(session)
	local best = -1
	local bestEntries = {}
	for _, entry in ipairs(session.played) do
		local strength = entry.covered and -1 or cardStrength(entry.card)
		if strength > best then
			best = strength
			bestEntries = { entry }
		elseif strength == best then
			table.insert(bestEntries, entry)
		end
	end

	local winner = 0
	if best >= 0 then
		winner = teamOf(bestEntries[1].seat)
		for _, entry in ipairs(bestEntries) do
			if teamOf(entry.seat) ~= winner then
				winner = 0
				break
			end
		end
	end
	local nextLead = winner == 0 and session.played[1].seat
		or bestEntries[#bestEntries].seat
	table.insert(session.roundResults, winner)
	local first = session.roundResults[1]
	local second = session.roundResults[2]
	local handWinner = nil
	if session.round == 2 then
		if first ~= 0 and (second == first or second == 0) then
			handWinner = first
		elseif first == 0 and second ~= 0 then
			handWinner = second
		end
	elseif session.round == 3 then
		local third = session.roundResults[3]
		if first == 0 and second == 0 then
			handWinner = third
		elseif third == 0 then
			handWinner = first ~= 0 and first or second
		else
			handWinner = third
		end
	end

	session.phase = "roundPause"
	session.status = winner == 0 and "Rodada empatada!" or ("Rodada da Dupla " .. winner .. "!")
	broadcastAll()
	local generation = session.generation
	task.delay(2, function()
		if generation ~= session.generation or session.phase ~= "roundPause" then return end
		if handWinner ~= nil then
			if handWinner == 0 then
				endHand(session, nil, 0, "Mão empatada. Ninguém pontuou.")
			else
				endHand(session, handWinner, session.handValue, "Dupla " .. handWinner .. " venceu a mão!")
			end
		else
			session.round += 1
			session.played = {}
			session.turnSeat = nextLead
			session.phase = "playing"
			session.status = "Rodada " .. session.round .. ": vez de " .. session.players[nextLead].DisplayName
			broadcastAll()
		end
	end)
end

endHand = function(session, team, points, message)
	if team then session.scores[team] += points end
	session.status = message
	session.phase = "handPause"
	if team and session.scores[team] >= 12 then
		session.phase = "finished"
		session.status = "Dupla " .. team .. " venceu a partida! Nova partida em 8 segundos."
	end
	broadcastAll()
	local generation = session.generation
	task.delay(session.phase == "finished" and 8 or 3, function()
		if generation ~= session.generation or not fullTable(session) then return end
		if session.phase == "finished" then
			session.scores = { 0, 0 }
			session.handNumber = 0
			session.previousLead = nil
		end
		if session.phase == "finished" or session.phase == "handPause" then
			startHand(session)
		end
	end)
end

startHand = function(session)
	if not fullTable(session) then return end
	session.generation += 1
	session.handNumber += 1
	session.previousLead = session.previousLead and nextSeat(session.previousLead)
		or random:NextInteger(1, 4)
	session.turnSeat = session.previousLead
	session.round = 1
	session.roundResults = {}
	session.played = {}
	session.hands = { {}, {}, {}, {} }
	session.handValue = 2
	session.lastRaiseTeam = nil
	session.offerSeat = nil
	session.offerValue = nil
	session.responseSeat = nil
	session.decisionTeam = nil
	session.special = nil
	local deck = makeDeck()
	for _ = 1, 3 do
		for offset = 0, 3 do
			local seat = ((session.previousLead + offset - 1) % 4) + 1
			table.insert(session.hands[seat], table.remove(deck))
		end
	end
	if session.scores[1] >= 10 and session.scores[2] >= 10 then
		session.special = "iron"
	elseif session.scores[1] >= 10 or session.scores[2] >= 10 then
		session.special = "ten"
		session.decisionTeam = session.scores[1] >= 10 and 1 or 2
		session.handValue = 4
	end
	if session.special == "ten" then
		session.phase = "decide10"
		session.status = "Mão de 10: Dupla " .. session.decisionTeam .. " decide jogar ou correr."
	else
		session.phase = "playing"
		session.status = session.special == "iron" and "Mão de ferro! Cartas ocultas."
			or ("Vez de " .. session.players[session.turnSeat].DisplayName)
	end
	broadcastAll()
end

local function resetMatch(session, excludedPlayer)
	session.generation += 1
	session.players = {}
	for seat = 1, 4 do
		local player = seatedPlayer(session.seatParts[seat])
		if player ~= excludedPlayer then session.players[seat] = player end
	end
	session.scores = { 0, 0 }
	session.handNumber = 0
	session.previousLead = nil
	session.hands = nil
	session.played = nil
	session.roundResults = nil
	session.round = nil
	session.phase = "waiting"
	session.status = "Aguardando quatro jogadores nesta mesa..."
	if fullTable(session) then
		startHand(session)
	else
		broadcastAll()
	end
end

remote.OnServerEvent:Connect(function(player, action, value, covered)
	if action == "ready" then
		sendState(player)
		return
	end
	local session, seat = findTrucoSeat(player)
	if type(action) ~= "string" then return end
	if action == "stand" then
		local humanoid
		if session then
			humanoid = session.seatParts[seat].Occupant
		else
			local pokerId, pokerSeat = findPokerSeat(player)
			local model = pokerId and pokerFolder:FindFirstChild("PokerMesa" .. pokerId)
			local seatPart = model and model:FindFirstChild("Seat" .. pokerSeat)
			humanoid = seatPart and seatPart.Occupant
		end
		if humanoid then
			humanoid.Sit = false
			humanoid.Jump = true
		end
		return
	end
	if not session then return end
	if action == "play" then
		if session.phase ~= "playing" or session.turnSeat ~= seat then return end
		if type(value) ~= "number" or value % 1 ~= 0 then return end
		local hand = session.hands[seat]
		if value < 1 or value > #hand then return end
		local isCovered = covered == true and session.round > 1 and session.special ~= "iron"
		local card = table.remove(hand, value)
		table.insert(session.played, { seat = seat, card = card, covered = isCovered })
		if #session.played == 4 then
			resolveRound(session)
		else
			session.turnSeat = nextSeat(seat)
			session.status = "Vez de " .. session.players[session.turnSeat].DisplayName
			broadcastAll()
		end
	elseif action == "raise" then
		if not canRaise(session, seat) then return end
		session.offerSeat = seat
		session.offerValue = nextBet(session.handValue)
		session.responseSeat = nextSeat(seat)
		session.phase = "offer"
		session.status = player.DisplayName .. " pediu " .. session.offerValue .. "!"
		broadcastAll()
	elseif action == "accept" or action == "run" or action == "counter" then
		if session.phase ~= "offer" or session.responseSeat ~= seat then return end
		if action == "run" then
			endHand(session, teamOf(session.offerSeat), session.handValue,
				"Dupla " .. teamOf(seat) .. " correu. Dupla " .. teamOf(session.offerSeat)
				.. " ganhou " .. session.handValue .. " pontos.")
		elseif action == "accept" then
			session.handValue = session.offerValue
			session.lastRaiseTeam = teamOf(session.offerSeat)
			session.offerSeat = nil
			session.offerValue = nil
			session.responseSeat = nil
			session.phase = "playing"
			session.status = "Pedido aceito! Vez de " .. session.players[session.turnSeat].DisplayName
			broadcastAll()
		elseif nextBet(session.offerValue) then
			session.handValue = session.offerValue
			session.offerValue = nextBet(session.offerValue)
			session.responseSeat = session.offerSeat
			session.offerSeat = seat
			session.status = player.DisplayName .. " aumentou para " .. session.offerValue .. "!"
			broadcastAll()
		end
	elseif action == "play10" or action == "run10" then
		if session.phase ~= "decide10" or teamOf(seat) ~= session.decisionTeam then return end
		if action == "run10" then
			endHand(session, otherTeam(session.decisionTeam), 2,
				"Dupla " .. session.decisionTeam .. " correu da mão de 10.")
		else
			session.phase = "playing"
			session.status = "Mão de 10 valendo 4! Vez de " .. session.players[session.turnSeat].DisplayName
			broadcastAll()
		end
	end
end)

for _, session in ipairs(sessions) do
	local currentSession = session
	for _, seatPart in ipairs(currentSession.seatParts) do
		seatPart:GetPropertyChangedSignal("Occupant"):Connect(function()
			resetMatch(currentSession)
		end)
	end
	resetMatch(currentSession)
end

for _, tableModel in ipairs(pokerFolder:GetChildren()) do
	for _, child in ipairs(tableModel:GetChildren()) do
		if child:IsA("Seat") then
			child:GetPropertyChangedSignal("Occupant"):Connect(broadcastAll)
		end
	end
end

Players.PlayerAdded:Connect(sendState)
Players.PlayerRemoving:Connect(function(player)
	for _, session in ipairs(sessions) do
		for seat = 1, 4 do
			if session.players[seat] == player then
				resetMatch(session, player)
				break
			end
		end
	end
end)
