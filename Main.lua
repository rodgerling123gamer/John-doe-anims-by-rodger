--// ANIMATOR NOVO
local AnimationModuleThing = loadstring([[local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--// SIGNAL
local Signal = {}
Signal.__index = Signal

function Signal.new(name)
	return setmetatable({
		_name = name,
		_connections = {},
		_waiting = {}
	}, Signal)
end

function Signal:Connect(fn)
	local conn = {fn = fn, Connected = true}
	self._connections[conn] = true

	function conn:Disconnect()
		conn.Connected = false
		self._connections[conn] = nil
	end

	return conn
end

function Signal:Fire(...)
	for conn in pairs(self._connections) do
		if conn.Connected then
			task.spawn(conn.fn, ...)
		end
	end
	for _, thread in ipairs(self._waiting) do
		task.spawn(thread, ...)
	end
	table.clear(self._waiting)
end

function Signal:Wait()
	local thread = coroutine.running()
	table.insert(self._waiting, thread)
	return coroutine.yield()
end

--// EASING
local easingCache = {}

local function getAlpha(a, style, dir)
	local key = style*10 + dir
	local f = easingCache[key]
	
	if not f then
		f = function(x)
			return TweenService:GetValue(x, Enum.EasingStyle[style.Name], dir)
		end
		easingCache[key] = f
	end
	return f(a)
end

--// ANIMATION TRACK
local AnimationTrack = {}
AnimationTrack.__index = AnimationTrack

function AnimationTrack.new(animator, seq)
	local self = setmetatable({}, AnimationTrack)

	self._animator = animator
	self._keyframes = {}
	self._markers = {}
	self._length = 0
	self._playing = false
	self._time = 0
	self._speed = 1
	self._looped = seq.Loop
	self.Priority = seq.Priority

	self.KeyframeReached = Signal.new("KeyframeReached")
	self.MarkerReached = {}

	-- parse
	for _, kf in ipairs(seq:GetChildren()) do
		self._length = math.max(self._length, kf.Time)

		for _, marker in ipairs(kf:GetMarkers()) do
			self._markers[marker.Name] = kf.Time
		end

		local root = kf:FindFirstChild("HumanoidRootPart")
		if root then
			for _, pose in ipairs(root:GetDescendants()) do
				if pose:IsA("Pose") then
					local list = self._keyframes[pose.Name]
					if not list then
						list = {}
						self._keyframes[pose.Name] = list
					end

					list[#list+1] = {
						t = kf.Time,
						cf = pose.CFrame,
						es = pose.EasingStyle,
						ed = pose.EasingDirection
					}
				end
			end
		end
	end

	-- sort
	for _, list in pairs(self._keyframes) do
		table.sort(list, function(a,b) return a.t < b.t end)
	end

	return self
end

function AnimationTrack:Play(fade, weight, speed)
	self._playing = true
	self._time = 0
	self._speed = speed or 1
	self._fade = fade or 0.1
	self._start = os.clock()
end

function AnimationTrack:Stop(fade)
	self._playing = false
end

function AnimationTrack:_step(dt)
	if not self._playing then return end

	self._time += dt * self._speed

	if self._time > self._length then
		if self._looped then
			self._time %= self._length
		else
			self:Stop()
			return
		end
	end

	local transforms = {}

	for joint, frames in pairs(self._keyframes) do
		local last, next

		for i=1,#frames do
			if frames[i].t <= self._time then
				last = frames[i]
				next = frames[i+1]
			end
		end

		if not last then continue end

		if not next then
			transforms[joint] = last.cf
		else
			local alpha = (self._time - last.t)/(next.t - last.t)
			local easingStyle = Enum.EasingStyle[next.es.Name]
local easingDirection = Enum.EasingDirection[next.ed.Name]

alpha = TweenService:GetValue(alpha, easingStyle, easingDirection)
			transforms[joint] = last.cf:Lerp(next.cf, alpha)
		end
	end

	return transforms
end

--// ANIMATOR
local Animator = {}
Animator.__index = Animator

function Animator.new(humanoid)
	local self = setmetatable({}, Animator)

	self._humanoid = humanoid
	self._tracks = {}
	self._joints = {}

	for _, m in ipairs(humanoid.Parent:GetDescendants()) do
		if m:IsA("Motor6D") and m.Part1 then
			self._joints[m.Part1.Name] = m
		end
	end

	local last = os.clock()

	RunService.Stepped:Connect(function()
		local now = os.clock()
		local dt = now - last
		last = now

		local final = {}

		for _, track in ipairs(self._tracks) do
			local t = track:_step(dt)
			if t then
				for j, cf in pairs(t) do
					final[j] = cf
				end
			end
		end

		for j, motor in pairs(self._joints) do
			if final[j] then
				motor.Transform = final[j]
			end
		end
	end)

	return self
end

function Animator:LoadAnimation(seq)
	local t = AnimationTrack.new(self, seq)
	table.insert(self._tracks, t)
	return t
end

return Animator]])()
local AnimationModule = AnimationModuleThing
--// DOWNLOAD DOS ASSETS
local url = "https://raw.githubusercontent.com/rodgerling123gamer/John-doe-anims-by-rodger/main/Animationsnew.rbxm"
local data = game:HttpGet(url)
writefile("Animations.rbxm", data)
local character =  game.Players.LocalPlayer.Character

local map = {
	UpperTorso = "dsdsd",
	LowerTorso = "Torso",

	LeftUpperArm = "Left Arm",
	LeftLowerArm = "dsdsd",
	LeftHand = "dsdsd",

	RightUpperArm = "Right Arm",
	RightLowerArm = "dsdsd",
	RightHand = "Rdsdsd",

	LeftUpperLeg = "Left Leg",
	LeftLowerLeg = "dsdsd",
	LeftFoot = "dsdsd",

	RightUpperLeg = "Right Leg",
	RightLowerLeg = "dsdsd",
	RightFoot = "dsdsd",

}

for _, obj in ipairs(character:GetDescendants()) do
	if obj:IsA("BasePart") then

		local newName = map[obj.Name]
		if newName then
			obj.Name = newName
		end
	end
end
local animFolder = game:GetObjects(getcustomasset("Animations.rbxm"))[1]
animFolder.Parent = game:GetService("ReplicatedStorage")

--// SERVICES
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Sounds = {CorruptEnergy = "rbxassetid://136257819515665", Ahh = "rbxassetid://76307607611996", S = "rbxassetid://111895645170572"}
local lp = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local realRoot = char:WaitForChild("HumanoidRootPart")

--// --// SERVICES
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local lp = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()

--// CONFIGURAÇÕES VITAIS
local Flinging = false
local VelocityVector = Vector3.new(0, -30.05, 0) -- Força a posse da rede (Network Owner)

--// FUNÇÃO DE ALINHAMENTO COMPLEXO (PFR - Physics Force Replication)--// CONFIGURAÇÕES DE REANIMAÇÃO
char.Archivable = true
local fakeChar = char:Clone()
fakeChar.Name = "Reanimate_Visual"
fakeChar.Parent = workspace

-- Limpeza do FakeChar
for _, v in pairs(fakeChar:GetDescendants()) do
	if v:IsA("BasePart") then 
		v.CanCollide = false
	elseif v:IsA("LocalScript") or v:IsA("Script") then
		v:Destroy()
	end
end

--// O PULO DO GATO: DESTRUIR JUNTAS SEM MORRER
-- Desativamos o estado de morte ANTES de mexer nas juntas
char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

--// CONFIGURAÇÕES DE REANIMAÇÃO
char.Archivable = true
local fakeChar = char:Clone()
fakeChar.Name = "Reanimate_Visual"
fakeChar.Parent = workspace

-- Limpeza do FakeChar
for _, v in pairs(fakeChar:GetDescendants()) do
	if v:IsA("BasePart") then 
		v.CanCollide = false
	elseif v:IsA("LocalScript") or v:IsA("Script") then
		v:Destroy()
	end
end

--// O PULO DO GATO: DESTRUIR JUNTAS SEM MORRER
-- Desativamos o estado de morte ANTES de mexer nas juntas
char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

for _, v in pairs(char:GetDescendants()) do
	if v:IsA("Motor6D") or v:IsA("Weld") then
		-- Em vez de apenas .Enabled = false, vamos remover a conexão 
		-- mas manter o objeto se necessário. Para Reanimators, destruir é mais seguro:
		v:Destroy() 
	end
end

--// ALINHAMENTO DAS PARTES (FÍSICA)
local function Align(Part0, Part1)
	Part0.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
	Part0.CanCollide = false
	Part0.Massless = true

	local att0 = Instance.new("Attachment", Part0)
	local att1 = Instance.new("Attachment", Part1)

	local AP = Instance.new("AlignPosition", Part0)
	AP.Attachment0 = att0
	AP.Attachment1 = att1
	AP.RigidityEnabled = true
	AP.ReactionForceEnabled = false
	AP.ApplyAtCenterOfMass = true

	local AO = Instance.new("AlignOrientation", Part0)
	AO.Attachment0 = att0
	AO.Attachment1 = att1
	AO.RigidityEnabled = true
	AO.ReactionTorqueEnabled = false
end

-- Linkando o corpo real ao corpo falso (que será animado)
for _, part in pairs(fakeChar:GetChildren()) do
	if part:IsA("BasePart") and char:FindFirstChild(part.Name) then
		Align(char[part.Name], part)
	end
end

fakeChar.Parent = workspace
workspace.CurrentCamera.CameraSubject = fakeChar:FindFirstChild("Humanoid")

--// SISTEMA DE ESTABILIDADE DE REDE (ANTI-LAG)
-- Isso evita que as partes do corpo real sumam ou fiquem paradas no ar para outros players
local function NetworkFix()
	for _, v in pairs(char:GetChildren()) do
		if v:IsA("BasePart") then
			v.Velocity = VelocityVector
			v.RotVelocity = Vector3.new(0, 0, 0)
		end
	end
end
--// LOOP DE REPLICAÇÃO E FLING
RunService.Heartbeat:Connect(function()
	NetworkFix()

	local realRoot = char:FindFirstChild("HumanoidRootPart")
	local fakeRoot = fakeChar:FindFirstChild("HumanoidRootPart")

	if realRoot and fakeRoot then
		if Flinging then
			-- Modo de Ataque: O Root real gira violentamente e segue o mouse ou frente do fake
			realRoot.CFrame = fakeRoot.CFrame * CFrame.new(0, 0, -2)
			realRoot.Velocity = Vector3.new(50000, 50000, 50000)
			realRoot.RotVelocity = Vector3.new(50000, 50000, 50000)
		else
			-- Modo Passivo: O corpo real fica escondido logo abaixo do chão (Evita colisões indesejadas)
			-- Mas ainda perto o suficiente para o servidor validar sua posição
			realRoot.CFrame = fakeRoot.CFrame * CFrame.new(0, -10, 0)
		end
	end
end)

--// DESATIVAR MORTE (Opcional, mas recomendado para Reanimators)
char.Humanoid.Health = 100
char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

--// FINALIZAÇÃO
lp.Character = fakeChar
print("Reanimator Complexo Ativado.")

--// Variáveis Globais para seu script de animação usar:
_G.Reanimator_FakeChar = fakeChar
_G.Reanimator_SetFling = function(state) Flinging = state end
_G.AutoStart = false -- for ui
-- Para integrar com seu script anterior:
-- O seu Animator agora deve usar o _G.Reanimator_FakeChar.Humanoid
--// ================= NOVO ANIMATOR =================
local Animator = AnimationModule.new(fakeChar:WaitForChild("Humanoid"))

local function createTrack(name, looped)
	local anim = animFolder:FindFirstChild(name)
	if not anim then return nil end

	local track = Animator:LoadAnimation(anim)
	track.Looped = looped or false

	return track
end

local Anim = {
	Idle = createTrack("Idle", true),
	Walk = createTrack("Walk", true),
	Run  = createTrack("Run", true),
	Slash = createTrack("Slash", false),
	Digital = createTrack("Digital Footprint", false),
	Stunned = createTrack("Stunned", false),
	Corrupt = createTrack("Corrupt Energy", false),
	Kill = createTrack("Kill", false),
	Intro = createTrack("GoonBreak", false) -- dont ask me the name
}

--// ================= ESTADOS =================
local Flinging = false
local State = { Attacking = false }local RunService = game:GetService("RunService")

local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local function CreateHitbox(character, config)
	config = config or {}

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}

	local hitHumanoids = {}
	local timePassed = 0
	local duration = config.Time or 0.2

	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		timePassed += dt
		if timePassed >= duration then
			connection:Disconnect()
			if config.OnEnd then
				config.OnEnd()
			end
			return
		end

		-- cria UMA NOVA hitbox por frame
		local hitbox = Instance.new("Part")
		hitbox.Size = config.Size or Vector3.new(4,5,4)
		hitbox.Transparency = config.Debug and 0.65 or 1
		hitbox.Color = Color3.new(1,0.25,0.25)
		hitbox.Anchored = true
		hitbox.CanCollide = false
		hitbox.CanQuery = true
		hitbox.Material = config.Debug and "ForceField" or "Plastic"
		hitbox.CanTouch = false
		hitbox.Name = "ClientHitbox"

		local cf = config.CFrame or (root.CFrame * (config.Offset or CFrame.new(0,0,-3)))
		hitbox.CFrame = fakeChar.Goonparr.CFrame * config.Offset--cf + (config.Predict and root.Velocity/12.5 or Vector3.zero)

		hitbox.Parent = workspace

		-- debris (igual você pediu)
		Debris:AddItem(hitbox, 1.5)

		-- detectar hits
		local parts = workspace:GetPartsInPart(hitbox, params)

		for _, part in ipairs(parts) do
			local hum = part.Parent:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				if not hitHumanoids[hum] then
					hitHumanoids[hum] = true

					if config.OnHit then
						hitbox.Color = Color3.new(0.5, 1, 0.5)
						config.OnHit(hum, part)
					end

					if not config.HitMultiple then
						connection:Disconnect()
						return
					end
				end
			end
		end
	end)
end
--// LOOP DE FÍSICA
RunService.Heartbeat:Connect(function()
	if Flinging then
		realRoot.Velocity = Vector3.new(0, 5000, 0)
		realRoot.RotVelocity = Vector3.new(5000, 5000, 5000)
		realRoot.CFrame = fakeChar.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)
	else
		realRoot.CFrame = fakeChar.HumanoidRootPart.CFrame * CFrame.new(0, -8, 0)
	end
end)

--// CONTROLE DE MOVIMENTO
local sprinting = false
RunService.RenderStepped:Connect(function()
	local speed = fakeChar.HumanoidRootPart.Velocity.Magnitude

	if not State.Attacking then
		if speed < 2 then
			if not Anim.Idle._playing then
				Anim.Idle:Play(0.4)
			end
			Anim.Walk:Stop(0.4)
		else
			if not sprinting then
				if not Anim.Walk._playing then
					Anim.Walk:Play(0.4)
					Anim.Run:Stop(0.4)
				end
			else
				if not Anim.Run._playing then
					Anim.Run:Play(0.4)
					Anim.Walk:Stop(0.4)
				end
			end
			Anim.Idle:Stop(0.4)
		end
	end
end)
local function CreateHitbox2(basePart, config)
	config = config or {}
	if not basePart then return end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {basePart}

	local hitHumanoids = {}
	local timePassed = 0
	local duration = config.Time or 0.2

	local connection
	connection = game:GetService("RunService").RenderStepped:Connect(function(dt)
		timePassed += dt
		if timePassed >= duration then
			connection:Disconnect()
			if config.OnEnd then
				config.OnEnd()
			end
			return
		end

		-- cria hitbox
		local hitbox = Instance.new("Part")
		hitbox.Size = config.Size or Vector3.new(4,5,4)
		hitbox.Transparency = config.Debug and 0.65 or 1
		hitbox.Color = Color3.new(1,0.25,0.25)
		hitbox.Anchored = true
		hitbox.CanCollide = false
		hitbox.CanQuery = true
		hitbox.Material = config.Debug and Enum.Material.ForceField or Enum.Material.Plastic
		hitbox.CanTouch = false
		hitbox.Name = "ClientHitbox"

		-- usa a PART diretamente
		local cf = basePart.CFrame * (config.Offset or CFrame.new())
		hitbox.CFrame = cf

		hitbox.Parent = workspace
		game:GetService("Debris"):AddItem(hitbox, 1.5)

		-- detectar hits
		local parts = workspace:GetPartsInPart(hitbox, params)

		for _, part in ipairs(parts) do
			local hum = part.Parent:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				if not hitHumanoids[hum] then
					hitHumanoids[hum] = true

					if config.OnHit then
						hitbox.Color = Color3.new(0.5, 1, 0.5)
						config.OnHit(hum, part)
					end

					if not config.HitMultiple then
						connection:Disconnect()
						return
					end
				end
			end
		end
	end)
end
local function corruptenergyability()
	local sound = Instance.new("Sound", fakeChar.PrimaryPart)
	sound.SoundId = Sounds.CorruptEnergy
	sound.PlaybackSpeed = 1.12
	sound:Play()
	task.delay(1.8, function()
		local spikes = {}
		local lastcframe = fakeChar.Goonparr.CFrame
		local lastDirection = lastcframe.LookVector

		local MAX_ANGLE = math.rad(35)

		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {fakeChar, spikes}
		rayParams.FilterType = Enum.RaycastFilterType.Blacklist

		local function clampDirection(newDir, oldDir)
			local dot = math.clamp(newDir:Dot(oldDir), -1, 1)
			local angle = math.acos(dot)

			if angle <= MAX_ANGLE then
				return newDir
			end

			local axis = oldDir:Cross(newDir)
			if axis.Magnitude == 0 then
				return oldDir
			end

			axis = axis.Unit
			local limitedCF = CFrame.fromAxisAngle(axis, MAX_ANGLE)
			return (limitedCF:VectorToWorldSpace(oldDir)).Unit
		end

		local function getGroundCFrame(pos)
			local origin = pos + Vector3.new(0, 10, 0)
			local direction = Vector3.new(0, -50, 0)

			local result = workspace:Raycast(origin, direction, rayParams)

			if result then
				return CFrame.new(result.Position)
			else
				return CFrame.new(pos)
			end
		end

		local function createspike(cf)
	lastcframe = cf

	local spike = Instance.new("Part")
	spike.Parent = workspace
	spike.CanCollide = false
	spike.Anchored = true
	spike.CFrame = cf + Vector3.new(0, -10.1, 0)
	spike.Size = Vector3.new(3, 10, 3)
	spike.Transparency = 1

	-- Parte visual separada
	local visual = Instance.new("Part")
	visual.Parent = workspace
	visual.Anchored = true
	visual.CanCollide = false
	visual.CFrame = spike.CFrame
	visual.Size = Vector3.new(4.549, 9.987, 4.297)
	visual.Color = Color3.fromRGB(17, 17, 17)
	visual.Material = Enum.Material.Slate

	-- Mesh como detalhe
	local mesh1 = Instance.new("SpecialMesh")
mesh1.Parent = visual
mesh1.MeshId = "rbxassetid://75260737063005"
mesh1.Scale = Vector3.new(1,1,1)

local mesh2 = Instance.new("SpecialMesh")
mesh2.Parent = visual
mesh2.MeshId = "rbxassetid://75260737063005"
mesh2.Scale = Vector3.new(-1,1,1) -- inverte

	table.insert(spikes, spike)

	-- Tween subida (ambos juntos)
	local tween = game.TweenService:Create(
		spike,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{CFrame = cf}
	)

	local tweenVisual = game.TweenService:Create(
		visual,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{CFrame = cf * CFrame.new(Vector3.new(0, -10/3, 0))}
	)

	tween:Play()
	tweenVisual:Play()

	CreateHitbox2(visual, {
		Size = Vector3.new(4,10.5,4),
		Time = 0.35,
		Offset = CFrame.new(0, 0, 0),
		Debug = true,
		OnHit = function(hum)
			print("acertou:", hum.Parent.Name)
		end
	})

	task.delay(11.1, function()
		local downCF = cf + Vector3.new(0, -10.1, 0)

		local tween2 = game.TweenService:Create(
			spike,
			TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{CFrame = downCF}
		)

		local tweenVisual2 = game.TweenService:Create(
			visual,
			TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{CFrame = downCF * CFrame.new(Vector3.new(0, -10/2.875, 0))}
		)

		tween2:Play()
		tweenVisual2:Play()
	end)
end

		spawn(function()
			for i = 1, 29 do
				task.wait(0.065)

				local currentDir = fakeChar.Goonparr.CFrame.LookVector
				local limitedDir = clampDirection(currentDir, lastDirection)

				lastDirection = limitedDir

				local nextPos = lastcframe.Position + limitedDir * 4.5
				local groundCF = getGroundCFrame(nextPos) + Vector3.new(0, 13.5/2, 0)

				lastcframe = groundCF
				createspike(lastcframe)
			end
		end)
	end)
end
--// INPUT
local module = loadstring(game:HttpGet("https://raw.githubusercontent.com/rodgerling123gamer/John-doe-anims-by-rodger/refs/heads/main/AnimatorKFS"))()
local AbilitySystem = module.AbilitySystem
AbilitySystem.RegisterAbility({
			Name = "Corrupt Energy",
			Icon = "rbxassetid://96590285148227",
			Cooldown = 5,
			Keybind = "Q",
			LayoutOrder = 1,
			Callback = function(ability) 
		        	Anim.Corrupt:Play()
		          corruptenergyability()
		    end
		})
--	Anim.Digital:Play()
AbilitySystem.RegisterAbility({
			Name = "Digital footprint",
			Icon = "rbxassetid://96590285148227",
			Cooldown = 5,
			Keybind = "E",
			LayoutOrder = 1,
			Callback = function(ability) 
		        	Anim.Digital:Play()
		    end
		})
AbilitySystem.Initialize()
UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 and not State.Attacking then
		State.Attacking = true
		Flinging = true

		Anim.Slash:Play()
		--	local sound = Instance.new("Sound", fakeChar.PrimaryPart)
		--		sound.SoundId = Sounds.S
		--	sound:Play()
		task.delay(0.3, function(parameters)
			CreateHitbox(fakeChar, {
				Size = Vector3.new(4.125,6.25,6.75),
				Offset = CFrame.new(0,0,-1.5),
				Time = 0.35,
				Debug = true,
				Predict = true,
				HitMultiple = false,

				OnHit = function(humanoid)
					print("ACERTOU:", humanoid.Parent.Name)

					-- exemplo de dano fake (cliente)
					humanoid.Health -= 10
				end
			})
		end)

		task.wait(0.6)

		-- Anim.Slash:Stop(0.1)
		Flinging = false
		State.Attacking = false
	end
	if input.KeyCode == Enum.KeyCode.R then
		State.Attacking = true
		--Flinging = true

		Anim.Stunned:Play()

		task.wait(0.6)

		-- Anim.Slash:Stop(0.1)
		-- Flinging = false
		State.Attacking = false
	end
	if input.KeyCode == Enum.KeyCode.T then
		State.Attacking = true
		--Flinging = true
		local sound = Instance.new("Sound", fakeChar.PrimaryPart)
		sound.SoundId = Sounds.Ahh
		sound:Play()
		Anim.Kill:Play()

		task.wait(0.6)

		-- Anim.Slash:Stop(0.1)
		-- Flinging = false
		State.Attacking = false
	end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		sprinting = true
		fakeChar.Humanoid.WalkSpeed = 28.5
	elseif input.KeyCode == Enum.KeyCode.Y then -- bro i forgot about the kill anim
		Anim.Intro:Play()
	end
end)
UIS.InputEnded:Connect(function(input, gpe)
	if gpe then return end

	if input.KeyCode == Enum.KeyCode.LeftShift then

		sprinting = false
		fakeChar.Humanoid.WalkSpeed = 12
	elseif input.KeyCode == Enum.KeyCode.Y then
		Anim.Intro:Stop()
	end
end	)
local player = game.Players.LocalPlayer
local char2 = fakeChar
local root = fakeChar:WaitForChild("HumanoidRootPart")

local p = Instance.new("Part")
p.Name = "Goonparr"
p.Anchored = true
p.CanCollide = false
p.Size = Vector3.new(2,2,2)
p.Parent = char2

local minPing = math.huge
local smoothPing = 0

spawn(function()
	while task.wait() do
		if not root then continue end

		-- ping em ms
		local rawPing = math.clamp(player:GetNetworkPing() * 1000, 1, 1100)

		-- mínimo REAL (nunca sobe sozinho)
		minPing = math.min(minPing, rawPing)

		-- suavização baseada no mínimo
		smoothPing = smoothPing + (minPing - smoothPing) * 0.1

		-- converter pra segundos
		local pingSec = smoothPing / 1000

		-- predição
		local predictedCF =
			root.CFrame +
			(root.Velocity * pingSec)

		local normalvel = root.Velocity/(18 - math.clamp(predictedCF.Position.Magnitude/8, 0, 5))
		task.delay(pingSec, function()
			if root and root.Parent then
				p.CFrame = predictedCF + normalvel
			end
		end)
	end
end)--// ================= TRAIL SYSTEM (10 PARTES) =================

local TrailSystem = {}
TrailSystem.Enabled = true

local TrailParts = {}
local MAX_PARTS = 10

local basePart = fakeChar:WaitForChild("Goonparr") -- usa seu preditor

-- config visual
local TRAIL_LIFETIME = 0.35
local TRAIL_COLOR = Color3.fromRGB(20, 20, 20)
local TRAIL_MATERIAL = Enum.Material.ForceField

-- criar pool (10 partes)
for i = 1, MAX_PARTS do
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(2,2,2)
	part.Material = TRAIL_MATERIAL
	part.Color = TRAIL_COLOR
	part.Name = "TrailPart_"..i
	part.Parent = workspace

	TrailParts[i] = {
		Part = part,
		LastCF = CFrame.new(),
		Active = false
	}
end

local index = 1

-- spawn de trail
local function spawnTrail(cf)
	local data = TrailParts[index]
	index = index % MAX_PARTS + 1

	local part = data.Part
	data.Active = true

	part.CFrame = cf
	part.Transparency = 0.25
	part.Size = Vector3.new(2.5,2.5,2.5)

	-- fade out suave
	task.spawn(function()
		local t = 0
		while t < TRAIL_LIFETIME do
			t += task.wait()
			part.Transparency = 0.25 + (t / TRAIL_LIFETIME)
		end
		part.Transparency = 1
		data.Active = false
	end)
end

-- loop principal
RunService.RenderStepped:Connect(function()
	if not TrailSystem.Enabled then return end
	if not basePart then return end

	spawnTrail(basePart.CFrame)
end)

-- API
function TrailSystem:SetEnabled(state)
	self.Enabled = state
end

function TrailSystem:SetColor(color)
	for _, v in pairs(TrailParts) do
		v.Part.Color = color
	end
end

function TrailSystem:SetMaterial(mat)
	for _, v in pairs(TrailParts) do
		v.Part.Material = mat
	end
end

_G.TrailSystem = TrailSystem
--// NETWORK
lp.Character = fakeChar
char.Humanoid:Destroy()
