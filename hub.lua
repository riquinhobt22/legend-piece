local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- --- CONFIGURAÇÃO DE SERVIÇOS ---
local LocalPlayer = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

-- --- VARIÁVEIS DE CONTROLE HUB ---
local WalkSpeedEnabled = false
local WalkSpeedValue = 16
local JumpPowerEnabled = false
local JumpPowerValue = 50
local InfiniteJumpEnabled = false
local FlyEnabled = false
local FlySpeed = 50

-- Variáveis de Combate e Auto-Farm
local AutoAttackEnabled = false
local SpamFruitSkillsEnabled = false
local SelectedWeapon = ""
local SkillSpamDelay = 0.5
local SelectedEnemy = "Nenhum selecionado"
local AutoFarmEnabled = false
local AutoQuestEnabled = false
local FastModeEnabled = false
local NoCameraShake = true

-- Variáveis do Rastreador (Novas)
local FruitTimerString = "Calculando..."
local SpawnedFruitsList = {}

-- --- FUNÇÕES AUXILIARES ---

local function GetLegendWeapons()
    local items = {}
    if LocalPlayer:FindFirstChild("Backpack") then
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and not table.find(items, tool.Name) then table.insert(items, tool.Name) end
        end
    end
    if LocalPlayer.Character then
        for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") and not table.find(items, tool.Name) then table.insert(items, tool.Name) end
        end
    end
    if #items == 0 then table.insert(items, "Nenhum item equipado") end
    return items
end

local function GetEnemiesList()
    local enemies = {}
    local folders = {workspace:FindFirstChild("NPCs"), workspace:FindFirstChild("Enemies"), workspace:FindFirstChild("Mobs"), workspace}
    for _, folder in ipairs(folders) do
        if folder then
            for _, obj in ipairs(folder:GetChildren()) do
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                    if obj.Name ~= LocalPlayer.Name and not table.find(enemies, obj.Name) then
                        table.insert(enemies, obj.Name)
                    end
                end
            end
        end
    end
    if #enemies == 0 then table.insert(enemies, "Nenhum NPC encontrado") end
    return enemies
end

-- Teleporte seguro usando CFrame (Não causa queda no mobile)
local function SecureTeleport(targetCFrame)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame
    end
end

-- Escaneia se existem frutas jogadas ou spawnadas pelo mapa
local function ScanMapForFruits()
    SpawnedFruitsList = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        -- Filtra modelos que contêm "Fruit" ou "Fruta" no nome e têm uma parte física
        if obj:IsA("Model") and (string.find(string.lower(obj.Name), "fruit") or obj:FindFirstChild("FruitCharacter")) then
            if obj:FindFirstChildOfClass("BasePart") or obj:FindFirstChild("Handle") then
                local part = obj:FindFirstChildOfClass("BasePart") or obj:FindFirstChild("Handle")
                table.insert(SpawnedFruitsList, {Name = obj.Name, Instance = obj, Position = part.CFrame})
            end
        end
    end
    return SpawnedFruitsList
end

-- --- CRIAR INTERFACE RAYFIELD ---
local Window = Rayfield:CreateWindow({
   Name = "Legend Piece Hub | Complete Edition",
   LoadingTitle = "Carregando Módulos de Rastreamento...",
   LoadingSubtitle = "Edição Definitiva Mobile",
   Theme = "Default",
   ConfigurationSaving = { Enabled = false }
})

-- --- LOOPS GERAIS ---

-- Loop de Movimentação Humana e Câmera
RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if WalkSpeedEnabled then hum.WalkSpeed = WalkSpeedValue end
        if JumpPowerEnabled then hum.JumpPower = JumpPowerValue hum.UseJumpPower = true end
    end
    if NoCameraShake and workspace.CurrentCamera then
        for _, effect in ipairs(workspace.CurrentCamera:GetChildren()) do
            if effect:IsA("ColorCorrectionEffect") or effect:IsA("BlurEffect") then effect:Destroy() end
        end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(0, 0, 0)
        end
    end
end)

-- Geppo
UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

-- Auto-Equip
task.spawn(function()
    while task.wait(0.5) do
        if SelectedWeapon ~= "" and SelectedWeapon ~= "Nenhum item equipado" then
            if LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Character then
                local tool = LocalPlayer.Backpack:FindFirstChild(SelectedWeapon)
                if tool and not LocalPlayer.Character:FindFirstChild(SelectedWeapon) then
                    tool.Parent = LocalPlayer.Character
                end
            end
        end
    end
end)

-- Auto M1 Clicker
task.spawn(function()
    while task.wait(0.1) do 
        if (AutoAttackEnabled or AutoFarmEnabled) and LocalPlayer.Character then
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then 
                tool:Activate()
                local remote = tool:FindFirstChild("Remote") or tool:FindFirstChild("Attack") or tool:FindFirstChild("MainRemote")
                if remote and remote:IsA("RemoteEvent") then remote:FireServer("Attack", "LeftClick") end
            end
        end
    end
end)

-- Spam Skills
task.spawn(function()
    while true do
        task.wait(SkillSpamDelay)
        if (SpamFruitSkillsEnabled or AutoFarmEnabled) and LocalPlayer.Character then
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                local skillKeys = {"Z", "X", "C", "V", "Q", "E"}
                for _, remote in ipairs(tool:GetDescendants()) do
                    if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                        local targetPos = LocalPlayer.Character.HumanoidRootPart.CFrame + (LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector * 10)
                        for _, key in ipairs(skillKeys) do
                            pcall(function()
                                if remote:IsA("RemoteEvent") then
                                    remote:FireServer(key, targetPos.Position)
                                    remote:FireServer("Skill", key, targetPos.Position)
                                end
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- Auto Quest
task.spawn(function()
    while task.wait(1) do
        if AutoQuestEnabled and SelectedEnemy ~= "Nenhum selecionado" and SelectedEnemy ~= "Nenhum NPC encontrado" then
            local hasQuest = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("QuestUI")
            if not hasQuest or (LocalPlayer.PlayerGui:FindFirstChild("QuestUI") and not LocalPlayer.PlayerGui.QuestUI.Enabled) then
                for _, npc in ipairs(workspace:GetDescendants()) do
                    if npc:IsA("Model") and (string.find(string.lower(npc.Name), "quest") or string.find(string.lower(npc.Name), "giver")) then
                        local questRemote = npc:FindFirstChild("QuestRemote") or npc:FindFirstChild("Remote") or game:GetService("ReplicatedStorage"):FindFirstChild("QuestSystem")
                        if questRemote and questRemote:IsA("RemoteEvent") then
                            questRemote:FireServer("AcceptQuest", SelectedEnemy)
                            questRemote:FireServer(SelectedEnemy)
                        end
                    end
                end
            end
        end
    end
end)

-- Auto-Farm Bring Mobs
task.spawn(function()
    while task.wait(0.2) do
        if AutoFarmEnabled and SelectedEnemy ~= "Nenhum selecionado" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myHrp = LocalPlayer.Character.HumanoidRootPart
            local folders = {workspace:FindFirstChild("NPCs"), workspace:FindFirstChild("Enemies"), workspace:FindFirstChild("Mobs"), workspace}
            for _, folder in ipairs(folders) do
                if folder then
                    for _, obj in ipairs(folder:GetChildren()) do
                        if obj:IsA("Model") and obj.Name == SelectedEnemy and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                            if obj.Humanoid.Health > 0 then
                                local enemyHrp = obj.HumanoidRootPart
                                enemyHrp.CFrame = myHrp.CFrame * CFrame.new(0, 0, -5)
                                enemyHrp.Velocity = Vector3.new(0,0,0)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- --- NOVO LOOP: RELÓGIO DE SPAWN DE FRUTAS (SIMULADO BASEADO NO SERVIDOR) ---
local serverStartTime = os.time()
task.spawn(function()
    while task.wait(1) do
        -- Ciclo do Legend Piece: Nasce uma fruta a cada 60 minutos (3600 segundos)
        local elapsed = (os.time() - serverStartTime) % 3600
        local timeLeft = 3600 - elapsed
        local minutes = math.floor(timeLeft / 60)
        local seconds = timeLeft % 60
        FruitTimerString = string.format("%02d Minutos e %02d Segundos", minutes, seconds)
    end
end)

-- FastMode Suave
task.spawn(function()
    while true do
        task.wait(2.5)
        if FastModeEnabled then
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            local descendants = workspace:GetDescendants()
            local count = 0
            for i = 1, #descendants do
                if not FastModeEnabled then break end
                local obj = descendants[i]
                if obj and obj.Parent then
                    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Explosion") then
                        if obj:IsA("Explosion") then obj.Visible = false else obj.Enabled = false end
                    elseif obj:IsA("MeshPart") or obj:IsA("Part") then
                        if obj.Material ~= Enum.Material.SmoothPlastic then obj.Material = Enum.Material.SmoothPlastic end
                    elseif obj:IsA("Texture") or obj:IsA("Decal") then
                        obj:Destroy()
                    end
                end
                count = count + 1
                if count >= 150 then count = 0 task.wait(0.02) end
            end
        end
    end
end)


-- --- ABAS DA INTERFACE ---
local TabFarm = Window:CreateTab("Auto Farm & Quests", 4483362534)
local TabTrack = Window:CreateTab("Rastreador & NPCs", 4370345144) -- Nova Aba
local TabPlayer = Window:CreateTab("Navegação", 4483362458)
local TabPerformance = Window:CreateTab("Performance Mobile", 4483364419)

-- --- ABA: AUTO FARM & QUESTS ---
TabFarm:CreateSection("1. Configuração do Alvo")
local EnemyDropdown = TabFarm:CreateDropdown({ Name = "Escolha o NPC / BOSS para Farmar", Options = GetEnemiesList(), CurrentOption = {"Selecione um alvo"}, MultipleOptions = false, Flag = "SelectedEnemyFlag", Callback = function(Option) SelectedEnemy = Option[1] end })
TabFarm:CreateButton({ Name = "🔄 Atualizar Lista de NPCs da Ilha", Callback = function() EnemyDropdown:Refresh(GetEnemiesList(), true) end })
local WeaponDropdown = TabFarm:CreateDropdown({ Name = "Selecione seu Item de Ataque", Options = GetLegendWeapons(), CurrentOption = {"Selecione um item"}, MultipleOptions = false, Flag = "WeaponFarm", Callback = function(O) SelectedWeapon = O[1] end })
TabFarm:CreateButton({ Name = "🔄 Atualizar Mochila", Callback = function() WeaponDropdown:Refresh(GetLegendWeapons(), true) end })
TabFarm:CreateSection("2. Ativação dos Motores")
TabFarm:CreateToggle({ Name = "⚔️ INICIAR AUTO FARM SELETIVO", CurrentValue = false, Flag = "StartAutoFarm", Callback = function(v) AutoFarmEnabled = v end })
TabFarm:CreateToggle({ Name = "📜 ACEITAR QUEST AUTOMATICAMENTE", CurrentValue = false, Flag = "StartAutoQuest", Callback = function(v) AutoQuestEnabled = v end })
TabFarm:CreateSection("Ataques Manuais")
TabFarm:CreateToggle({ Name = "Auto Clicker M1", CurrentValue = false, Flag = "LP_M1_T", Callback = function(v) AutoAttackEnabled = v end })
TabFarm:CreateToggle({ Name = "Spam Skills", CurrentValue = false, Flag = "LP_Skills_T", Callback = function(v) SpamFruitSkillsEnabled = v end })
TabFarm:CreateSlider({ Name = "Velocidade do Spam Skill", Range = {1, 10}, Increment = 1, CurrentValue = 5, Flag = "LP_SpamDelay", Callback = function(v) SkillSpamDelay = v / 10 end })

-- --- NOVA ABA: RASTREADOR & NPCS ---
TabTrack:CreateSection("🕒 Ciclo de Spawn das Frutas")
TabTrack:CreateButton({
    Name = "Verificar Tempo para Próximo Spawn",
    Callback = function()
        Rayfield:Notify({
            Name = "Tempo Estimado",
            Content = "Faltam aprox: " .. FruitTimerString .. " para uma fruta brotar no servidor.",
            Duration = 5,
        })
    end
})

TabTrack:CreateSection("🍎 Localizador de Frutas no Chão")
TabTrack:CreateButton({
    Name = "🔍 Escanear Mapa Procurando Fruta",
    Callback = function()
        local fruits = ScanMapForFruits()
        if #fruits > 0 then
            for _, f in ipairs(fruits) do
                Rayfield:Notify({
                    Name = "FRUTA ENCONTRADA!",
                    Content = "Nome: " .. f.Name .. " | Clique abaixo para teleportar.",
                    Duration = 6,
                })
            end
        else
            Rayfield:Notify({
                Name = "Rastreador",
                Content = "Nenhuma fruta spawnada no chão deste servidor no momento.",
                Duration = 4,
            })
        end
    end
})

TabTrack:CreateButton({
    Name = "⚡ Teleportar para Fruta Spawnada (Se houver)",
    Callback = function()
        local fruits = ScanMapForFruits()
        if #fruits > 0 then
            SecureTeleport(fruits[1].Position)
            Rayfield:Notify({ Name = "Sucesso", Content = "Teleportado para: " .. fruits[1].Name, Duration = 3 })
        else
            Rayfield:Notify({ Name = "Erro", Content = "Nenhuma fruta ativa encontrada para teleportar.", Duration = 3 })
        end
    end
})

TabTrack:CreateSection("🏪 NPCs de Utilidades (Vendedores e Histórias)")
-- Teleportes diretos para interações importantes que não dão level up
TabTrack:CreateButton({ Name = "📍 Vendedor de Frutas (Fruit Dealer)", Callback = function()
    for _, v in ipairs(workspace:GetDescendants()) do 
        if v:IsA("Model") and (string.find(string.lower(v.Name), "dealer") or string.find(string.lower(v.Name), "fruta")) then 
            SecureTeleport(v:GetModelCFrame()) break 
        end 
    end
end })

TabTrack:CreateButton({ Name = "📍 Vendedor de Estilo de Luta / Espadas", Callback = function()
    for _, v in ipairs(workspace:GetDescendants()) do 
        if v:IsA("Model") and (string.find(string.lower(v.Name), "master") or string.find(string.lower(v.Name), "seller")) then 
            SecureTeleport(v:GetModelCFrame()) break 
        end 
    end
end })

TabTrack:CreateButton({ Name = "📍 NPC Vendedor de Barcos (Boat Seller)", Callback = function()
    for _, v in ipairs(workspace:GetDescendants()) do 
        if v:IsA("Model") and string.find(string.lower(v.Name), "boat") then 
            SecureTeleport(v:GetModelCFrame()) break 
        end 
    end
end })


-- --- ABA: NAVEGAÇÃO ---
TabPlayer:CreateSection("Atributos do Pirata")
TabPlayer:CreateToggle({ Name = "Modificar Velocidade", CurrentValue = false, Flag = "LP_WS_T", Callback = function(v) WalkSpeedEnabled = v end })
TabPlayer:CreateSlider({ Name = "Velocidade", Range = {16, 250}, Increment = 1, CurrentValue = 16, Flag = "LP_WS_S", Callback = function(v) WalkSpeedValue = v end })
TabPlayer:CreateToggle({ Name = "Geppo / Pulo Infinito", CurrentValue = false, Flag = "LP_InfJ_T", Callback = function(v) InfiniteJumpEnabled = v end })
TabPlayer:CreateToggle({ Name = "Ativar Modo Vôo (Fly)", CurrentValue = false, Flag = "LP_Fly_T", Callback = function(v) FlyEnabled = v if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0) end end })
TabPlayer:CreateSlider({ Name = "Velocidade de Vôo", Range = {20, 300}, Increment = 5, CurrentValue = 70, Flag = "LP_FlySpd_S", Callback = function(v) FlySpeed = v end })

-- --- ABA: PERFORMANCE MOBILE ---
TabPerformance:CreateSection("Otimização")
TabPerformance:CreateToggle({ Name = "🚀 ATIVAR ULTRA FASTMODE (SUAVE)", CurrentValue = false, Flag = "LP_FastMode_V2", Callback = function(v) FastModeEnabled = v end })
TabPerformance:CreateToggle({ Name = "Remover Tremores (No Camera Shake)", CurrentValue = true, Flag = "LP_Shake", Callback = function(v) NoCameraShake = v end })

Rayfield:LoadConfiguration()
