local url = "https://download1530.mediafire.com/0j2lehdufnggWU_Bmi3bnSZHvA7RV1gG5c985NGrR3VBsnjVdZLe7PxnGWpckTbcw3tDMA7UJD2FUFxCwMlTuzKGeQXhOWigZg7iL_bA8Chzpx5QCQll3oFqoTFmEH6LEBSlcHBTR6KF6hbvJiojVYy9WGjQ2wWQX9AC3g-iabAV_SQ/my285cf4ntz9jml/Animations.rbxm"

local data = game:HttpGet(url)
writefile("Animations.rbxm", data)

local obj = game:GetObjects(getcustomasset("Animations.rbxm"))[1]
obj.Parent = workspace
--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local mouse = plr:GetMouse()

--// ================= REANIMATOR PRO =================
-- Criando o personagem visual (Client-Side)
char.Archivable = true
local fake = char:Clone()
fake.Name = "Reanimated_Visual"
fake.Parent = workspace

-- Limpeza de scripts e sons para evitar lag e double-audio
for _, v in pairs(fake:GetDescendants()) do
	if v:IsA("LuaSourceContainer") or v:IsA("Sound") then v:Destroy() end
end

local realHum = char:WaitForChild("Humanoid")
local fakeHum = fake:WaitForChild("Humanoid")
local realRoot = char:WaitForChild("HumanoidRootPart")
local fakeRoot = fake:WaitForChild("HumanoidRootPart")

-- Esconder o original e remover colisões
for _, v in pairs(char:GetDescendants()) do
	if v:IsA("BasePart") then
		v.Transparency = 1
		v.CanCollide = false
	end
end

-- Função de alinhamento robusta (CFrame Lerp para suavidade)
local function align(p0, p1)
	local att0 = Instance.new("Attachment", p0)
	local att1 = Instance.new("Attachment", p1)

	local ap = Instance.new("AlignPosition", p0)
	ap.Attachment0, ap.Attachment1 = att0, att1
	ap.MaxForce, ap.Responsiveness = 9e9, 200
	ap.RigidityEnabled = true -- Melhora a precisão do movimento

	local ao = Instance.new("AlignOrientation", p0)
	ao.Attachment0, ao.Attachment1 = att0, att1
	ao.MaxTorque, ao.Responsiveness = 9e9, 200
end
--// ================= BREAK JOINTS SAFE =================
local function SafeBreakJoints(character)
	for _, v in pairs(character:GetDescendants()) do
		-- Destruímos apenas Motor6Ds, Welds e SeatWelds
		-- Isso solta as peças mas NÃO reseta o HP do Humanoid
		if v:IsA("Motor6D") or v:IsA("Weld") or v:IsA("Snap") then
			v:Destroy()
		end
	end
end

-- Em vez de char:BreakJoints(), use:
SafeBreakJoints(char)

-- IMPORTANTE: Para o Humanoid não morrer por estar "despedaçado"
realHum.RequiresNeck = false 
realHum.BreakJointsOnDeath = false
for _, part in pairs(fake:GetChildren()) do
	if part:IsA("BasePart") then
		local target = char:FindFirstChild(part.Name)
		if target then align(part, target) end
	end
end

workspace.CurrentCamera.CameraSubject = fakeHum
fakeHum:ChangeState(Enum.HumanoidStateType.Physics)

--// ================= FLING SYSTEM (M1 ONLY) =================
--// ================= FLING SYSTEM (VERSÃO ESTÁVEL) =================
local Flinging = false

RunService.Heartbeat:Connect(function()
	if not realRoot or not fakeRoot then return end

	if Flinging then
		-- Em vez de 999999, usamos um valor alto mas que o motor do Roblox aguenta
		local flingForce = 50000 

		realRoot.Velocity = Vector3.new(0, 50, 0) -- Levitação leve para não prender no chão
		realRoot.RotVelocity = Vector3.new(flingForce, flingForce, flingForce)

		-- O segredo: mover o ROOT REAL para a frente do FAKE, mas com um pequeno offset
		-- Isso evita que você se auto-arremesse
		local targetCFrame = fakeRoot.CFrame * CFrame.new(0, 0, -3) 
		realRoot.CFrame = targetCFrame
	else
		-- Quando não está atacando, o root invisível fica "descansando" 
		-- embaixo do mapa ou longe de colisões para não bugar
		realRoot.Velocity = Vector3.new(0, 0, 0)
		realRoot.RotVelocity = Vector3.new(0, 0, 0)

		-- Mantém o real seguindo o fake mas SEM colisão ativa
		realRoot.CFrame = fakeRoot.CFrame * CFrame.new(0, -10, 0) 
	end
end)

--// ANTI-FLING PRÓPRIO (Execute isso uma vez no início)
for _, v in pairs(char:GetDescendants()) do
	if v:IsA("BasePart") then
		v.CanTouch = true -- Precisa tocar nos outros para dar fling
		v.CanCollide = false -- NÃO pode colidir com o mundo (chão/paredes)
	end
end

for _, v in pairs(fake:GetDescendants()) do
	if v:IsA("BasePart") then
		v.CanCollide = true -- O visual sim colide com o mundo
	end
end
--// ================= ANIMAÇÕES & PRIORIDADES =================
local function loadAnim(name, priority)
	local folder = workspace:WaitForChild("Animations")
	local kfs = folder:FindFirstChild(name)
	if not kfs then return nil end

	local anim = Instance.new("Animation")
	anim.AnimationId = game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(kfs)

	local track = fakeHum:LoadAnimation(anim)
	track.Priority = priority
	return track
end

local Anim = {
	Idle    = loadAnim("Idle", Enum.AnimationPriority.Idle),
	Walk    = loadAnim("Walk", Enum.AnimationPriority.Movement),
	Run     = loadAnim("Run", Enum.AnimationPriority.Movement),
	Slash   = loadAnim("Slash", Enum.AnimationPriority.Action), -- Prioridade alta
	Corrupt = loadAnim("Corrupt Energy", Enum.AnimationPriority.Action4), -- Máxima
	Digital = loadAnim("Digital Footprint", Enum.AnimationPriority.Action2),
	Kill    = loadAnim("Kill", Enum.AnimationPriority.Action3),
	Stunned = loadAnim("Stunned", Enum.AnimationPriority.Action4)
}

--// ================= STATE SYSTEM =================
local State = { Attacking = false, Stunned = false, Current = "Idle" }

local function play(animName, duration)
	if State.Stunned or not Anim[animName] then return end

	State.Attacking = true
	Anim[animName]:Play(0.2) -- Fade in de 0.2s

	task.delay(duration, function()
		State.Attacking = false
		Anim[animName]:Stop(0.3)
	end)
end

-- M1 com Fling integrado
local function M1()
	if State.Attacking then return end

	Flinging = true
	play("Slash", 0.5)

	task.delay(0.5, function()
		Flinging = false
	end)
end

--// ================= CICLO DE MOVIMENTO =================
RunService.RenderStepped:Connect(function()
	local vel = realRoot.Velocity.Magnitude

	-- Lógica para não sobrepor animações de ataque
	if not State.Attacking and not State.Stunned then
		if vel < 2 then
			if not Anim.Idle.IsPlaying then Anim.Idle:Play(0.3) end
			Anim.Walk:Stop(0.3)
			Anim.Run:Stop(0.3)
		elseif vel < 18 then
			if not Anim.Walk.IsPlaying then Anim.Walk:Play(0.3) end
			Anim.Idle:Stop(0.3)
			Anim.Run:Stop(0.3)
		else
			if not Anim.Run.IsPlaying then Anim.Run:Play(0.3) end
			Anim.Idle:Stop(0.3)
			Anim.Walk:Stop(0.3)
		end
	end
end)

--// ================= INPUTS =================
UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		M1()
	elseif input.KeyCode == Enum.KeyCode.Q then
		play("Corrupt", 1.2)
	elseif input.KeyCode == Enum.KeyCode.E then
		play("Digital", 1)
	elseif input.KeyCode == Enum.KeyCode.R then
		play("Kill", 1.5)
	elseif input.KeyCode == Enum.KeyCode.T then
		State.Stunned = true
		play("Stunned", 2)
		task.delay(2, function() State.Stunned = false end)
	end
end)