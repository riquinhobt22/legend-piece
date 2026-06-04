local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- --- SERVIÇOS E CONFIGURAÇÃO ---
local LocalPlayer = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

-- --- CONTROLADORES MASTER (ON/OFF) ---
local WalkSpeedEnabled, WalkSpeedValue = false, 16
local JumpPowerEnabled, JumpPowerValue = false, 50
local InfiniteJumpEnabled = false

-- Combate, Hitbox e Auto-Farm
local AutoFarmEnabled = false
local AutoQuestEnabled = false
local AutoAttackEnabled = false
local SpamFruitSkillsEnabled = false
local SelectedWeapon = ""
local SelectedEnemy = "Nenhum"
local HitboxSizeValue = 15 -- Tamanho padrão da hitbox estendida

-- Rastreadores e Teleportes
local SelectedTeleportNPC = "Nenhum"
local SpawnedFruitsList = {}

local NPC_Categories = {
    ["Combate / Bosses"] = {},
    ["Missões de Level (Givers)"] = {},
    ["Lojas / Vendedores"] = {},
    ["Quests Especiais / Outros"] = {}
}

-- --- FUNÇÃO DE TELEPORTE SEGURO ---
local function SecureTeleport(targetCFrame)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame
    end
end

-- --- VARREDURA FÍSICA COMPLETA DE NPCS ---
local function ScanAllNPCs()
    for cat, _ in pairs(NPC_Categories) do NPC_Categories[cat] = {} end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") and obj.Name ~= LocalPlayer.Name then
            local nameLower = string.lower(obj.Name)
            local hum = obj:FindFirstChildOfClass("Humanoid")
            
            if string.find(nameLower, "dealer") or string.find(nameLower, "seller") or string.find(nameLower, "shop") or string.find(nameLower, "vendedor") or string.find(nameLower, "gacha") or string.find(nameLower, "boat") or string.find(nameLower, "ship") then
                if not table.find(NPC_Categories["Lojas / Vendedores"], obj.Name) then table.insert(NPC_Categories["Lojas / Vendedores"], obj.Name) end
            elseif string.find(nameLower, "quest") or string.find(nameLower, "giver") or string.find(nameLower, "missao") then
                if not table.find(NPC_Categories["Missões de Level (Givers)"], obj.Name) then table.insert(NPC_Categories["Missões de Level (Givers)"], obj.Name) end
            elseif obj:FindFirstChild("ProximityPrompt") or obj:FindFirstChild("ClickDetector") or string.find(nameLower, "master") or string.find(nameLower, "donate") or string.find(nameLower, "all") then
                if not table.find(NPC_Categories["Quests Especiais / Outros"], obj.Name) then table.insert(NPC_Categories["Quests Especiais / Outros"], obj.Name) end
            elseif hum and hum.MaxHealth > 0 then
                if not table.find(NPC_Categories["Combate / Bosses"], obj.Name) then table.insert(NPC_Categories["Combate / Bosses"], obj.Name) end
            end
        end
    end
    for cat, lista in pairs(NPC_Categories) do if #lista == 0 then table.insert(NPC_Categories[cat], "Nenhum Detectado") end end
end

-- Lista as armas/frutas do inventário
local function GetLegendWeapons()
    local items = {}
    if LocalPlayer:FindFirstChild("Backpack") then
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do table.insert(items, tool.Name) end
    end
    if LocalPlayer.Character then
        for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") and not table.find(items, tool.Name) then table.insert(items, tool.Name) end
        end
    end
    if #items == 0 then table.insert(items, "Nenhum equipado") end
    return items
end

-- Escanear frutas no chão
local function ScanMapForFruits()
    SpawnedFruitsList = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (string.find(string.lower(obj.Name), "fruit") or obj:FindFirstChild("FruitCharacter") or string.find(string.lower(obj.Name), "fruta")) then
            local part = obj:FindFirstChildOfClass("BasePart") or obj:FindFirstChild("Handle")
            if part then table.insert(SpawnedFruitsList, {Name = obj.Name, Position = part.CFrame}) end
        end
    end
    return SpawnedFruitsList
end

-- --- CRIAR INTERFACE RAYFIELD ---
local Window = Rayfield:CreateWindow({
   Name = "Legend Piece Hub | V5 Repair Engine",
   LoadingTitle = "Injetando Modificadores de Hitbox e Auto-Skills...",
   LoadingSubtitle = "Otimizado para Correções Mobile e Delta",
   Theme = "Default",
   ConfigurationSaving = { Enabled = false }
})

ScanAllNPCs()

-- --- SISTEMAS DE LOOP COM CORREÇÕES ---

-- Loop Físico (Velocidade e Trava de Câmera)
RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if WalkSpeedEnabled then hum.WalkSpeed = WalkSpeedValue else hum.WalkSpeed = 16 end
        if JumpPowerEnabled then hum.JumpPower = JumpPowerValue hum.UseJumpPower = true end
    end
end)

-- Pulo Infinito
UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

-- SISTEMA DINÂMICO DE AUMENTO DE HITBOX (M1 & SKILLS ACERTAREM SEMPRE)
task.spawn(function()
    while task.wait(0.5) do
        if AutoFarmEnabled and SelectedEnemy ~= "Nenhum" then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == SelectedEnemy and obj:FindFirstChild("HumanoidRootPart") then
                    local hrp = obj.HumanoidRootPart
                    -- Expande a área física do monstro para que qualquer ataque corporal ou skill pegue à distância
                    hrp.Size = Vector3.new(HitboxSizeValue, HitboxSizeValue, HitboxSizeValue)
                    hrp.Transparency = 0.8 -- Fica levemente visível para você saber que a hitbox está ativa
                    hrp.CanCollide = false
                end
            end
        end
    end
end)

-- Mecanismo Inteligente de Auto-Equip
task.spawn(function()
    while task.wait(0.4) do
        if AutoFarmEnabled and SelectedWeapon ~= "" and SelectedWeapon ~= "Nenhum equipado" then
            if LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Character then
                local tool = LocalPlayer.Backpack:FindFirstChild(SelectedWeapon)
                if tool then tool.Parent = LocalPlayer.Character end
            end
        end
    end
end)

-- Auto M1 Clicker Remasterizado
task.spawn(function()
    while task.wait(0.1) do 
        if AutoAttackEnabled and LocalPlayer.Character then
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then 
                tool:Activate()
                -- Dispara múltiplos tipos de remotes de infraestrutura conhecidos de ataque
                for _, remote in ipairs(tool:GetDescendants()) do
                    if remote:IsA("RemoteEvent") and (string.find(string.lower(remote.Name), "attack") or string.find(string.lower(remote.Name), "click") or string.find(string.lower(remote.Name), "main")) then
                        remote:FireServer("Attack", "LeftClick")
                        remote:FireServer()
                    end
                end
            end
        end
    end
end)

-- NOVO MOTOR DE AUTO SKILLS UNIVERSAL (FRUTAS E WEAPONS)
task.spawn(function()
    while task.wait(0.3) do
        if SpamFruitSkillsEnabled and LocalPlayer.Character then
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                -- Lista exaustiva de inputs aceitos pelas estruturas do jogo
                local skillTriggers = {"Z", "X", "C", "V", "Q", "E", "Skill1", "Skill2", "Skill3", "Skill4"}
                local targetCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -10)
                
                for _, child in ipairs(tool:GetDescendants()) do
                    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                        for _, key in ipairs(skillTriggers) do
                            pcall(function()
                                if child:IsA("RemoteEvent") then
                                    -- Testa os formatos mais comuns de envio de dados para registrar a skill
                                    child:FireServer(key, targetCFrame.Position)
                                    child:FireServer("Skill", key, targetCFrame.Position)
                                    child:FireServer(key)
                                else
                                    child:InvokeServer(key, targetCFrame.Position)
                                end
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- Auto Aceitar Quests de Level Up
task.spawn(function()
    while task.wait(2) do
        if AutoQuestEnabled and SelectedEnemy ~= "Nenhum" then
            for _, npc in ipairs(workspace:GetDescendants()) do
                if npc:IsA("Model") and (string.find(string.lower(npc.Name), "quest") or string.find(string.lower(npc.Name), "giver")) then
                    local remote = npc:FindFirstChild("QuestRemote") or npc:FindFirstChild("Remote") or game:GetService("ReplicatedStorage"):FindFirstChild("QuestSystem")
                    if remote and remote:IsA("RemoteEvent") then 
                        remote:FireServer("AcceptQuest", SelectedEnemy)
                        remote:FireServer(SelectedEnemy)
                    end
                end
            end
        end
    end
end)

-- Auto Farm: Trazer Monstros para Frente
task.spawn(function()
    while task.wait(0.2) do
        if AutoFarmEnabled and SelectedEnemy ~= "Nenhum" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myHrp = LocalPlayer.Character.HumanoidRootPart
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == SelectedEnemy and obj:FindFirstChild("HumanoidRootPart") then
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        obj.HumanoidRootPart.CFrame = myHrp.CFrame * CFrame.new(0, 0, -4)
                        obj.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                    end
                end
            end
        end
    end
end)


-- --- CRIAÇÃO DAS ABAS ---
local TabFarm = Window:CreateTab("Auto Farm & Ataque", 4483362534)
local TabTeleport = Window:CreateTab("Auto Teleport NPC", 4370345144)
local TabFruit = Window:CreateTab("Fruit Teleport", 4370345144)
local TabPlayer = Window:CreateTab("Configurações", 4483362458)

-- --- ABA 1: COMBATE, HITBOX E FARM ---
TabFarm:CreateSection("Configuração do Alvo")
local EnemyDropdown = TabFarm:CreateDropdown({ Name = "Selecione o NPC/Boss para Farmar", Options = NPC_Categories["Combate / Bosses"], CurrentOption = {"Selecione"}, MultipleOptions = false, Callback = function(O) SelectedEnemy = O[1] end })
local WeaponDropdown = TabFarm:CreateDropdown({ Name = "Selecione a Arma/Fruta", Options = GetLegendWeapons(), CurrentOption = {"Selecione"}, MultipleOptions = false, Callback = function(O) SelectedWeapon = O[1] end })

TabFarm:CreateButton({ Name = "🔄 Recarregar Mobs e Inventário", Callback = function() ScanAllNPCs() EnemyDropdown:Refresh(NPC_Categories["Combate / Bosses"], true) WeaponDropdown:Refresh(GetLegendWeapons(), true) end })

TabFarm:CreateSection("Ajuste de Alcance (Hitbox)")
TabFarm:CreateSlider({ Name = "Tamanho da Hitbox dos Monstros", Range = {5, 50}, Increment = 1, CurrentValue = 15, Callback = function(v) HitboxSizeValue = v end })

TabFarm:CreateSection("Motores de Automação (ON/OFF)")
TabFarm:CreateToggle({ Name = "Ligar Auto Farm (Puxar Mobs)", CurrentValue = false, Callback = function(v) AutoFarmEnabled = v end })
TabFarm:CreateToggle({ Name = "Ligar Auto Quest (Aceitar Missão)", CurrentValue = false, Callback = function(v) AutoQuestEnabled = v end })
TabFarm:CreateToggle({ Name = "Ligar Auto Clicker M1", CurrentValue = false, Callback = function(v) AutoAttackEnabled = v end })
TabFarm:CreateToggle({ Name = "Ligar Auto Skill (Frutas e Armas)", CurrentValue = false, Callback = function(v) SpamFruitSkillsEnabled = v end })


-- --- ABA 2: AUTO TELEPORT NPC (SEPARADO) ---
TabTeleport:CreateSection("Filtros de Destino")
local DropGivers = TabTeleport:CreateDropdown({ Name = "NPCs de Missões de Level (Givers)", Options = NPC_Categories["Missões de Level (Givers)"], CurrentOption = {"Nenhum"}, MultipleOptions = false, Callback = function(O) SelectedTeleportNPC = O[1] end })
local DropShops = TabTeleport:CreateDropdown({ Name = "Lojas e Vendedores", Options = NPC_Categories["Lojas / Vendedores"], CurrentOption = {"Nenhum"}, MultipleOptions = false, Callback = function(O) SelectedTeleportNPC = O[1] end })
local DropSpecial = TabTeleport:CreateDropdown({ Name = "Quests Especiais e Outros NPCs", Options = NPC_Categories["Quests Especiais / Outros"], CurrentOption = {"Nenhum"}, MultipleOptions = false, Callback = function(O) SelectedTeleportNPC = O[1] end })

TabTeleport:CreateButton({ 
    Name = "🔄 Atualizar Todos os NPCs do Jogo", 
    Callback = function() 
        ScanAllNPCs() 
        DropGivers:Refresh(NPC_Categories["Missões de Level (Givers)"], true)
        DropShops:Refresh(NPC_Categories["Lojas / Vendedores"], true)
        DropSpecial:Refresh(NPC_Categories["Quests Especiais / Outros"], true)
    end 
})

TabTeleport:CreateSection("Ações")
TabTeleport:CreateButton({
    Name = "⚡ Executar Teleporte para NPC Selecionado",
    Callback = function()
        if SelectedTeleportNPC ~= "Nenhum" and SelectedTeleportNPC ~= "Nenhum Detectado" then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == SelectedTeleportNPC and obj:FindFirstChild("HumanoidRootPart") then
                    SecureTeleport(obj.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3))
                    break
                end
            end
        end
    end
})


-- --- ABA 3: FRUIT TELEPORT (RETORNADO) ---
TabFruit:CreateSection("Rastreador Físico de Frutas")
TabFruit:CreateButton({
    Name = "🔍 Verificar se existem Frutas no Servidor",
    Callback = function()
        local fruits = ScanMapForFruits()
        if #fruits > 0 then
            for _, f in ipairs(fruits) do Rayfield:Notify({ Name = "Rastreador", Content = "Fruta encontrada: " .. f.Name, Duration = 4 }) end
        else
            Rayfield:Notify({ Name = "Rastreador", Content = "Nenhuma fruta dropada ou spawnada no chão.", Duration = 4 })
        end
    end
})

TabFruit:CreateButton({
    Name = "🍎 Teleportar Instantaneamente para a Fruta",
    Callback = function()
        local fruits = ScanMapForFruits()
        if #fruits > 0 then 
            SecureTeleport(fruits[1].Position) 
        else
            Rayfield:Notify({ Name = "Aviso", Content = "Não existem frutas ativas para teleportar.", Duration = 3 })
        end
    end
})


-- --- ABA 4: CONFIGURAÇÕES GERAIS ---
TabPlayer:CreateSection("Modificações do Boneco")
TabPlayer:CreateToggle({ Name = "Modificar Velocidade", CurrentValue = false, Callback = function(v) WalkSpeedEnabled = v end })
TabPlayer:CreateSlider({ Name = "Velocidade", Range = {16, 200}, Increment = 1, CurrentValue = 16, Callback = function(v) WalkSpeedValue = v end })
TabPlayer:CreateToggle({ Name = "Pulo Infinito", CurrentValue = false, Callback = function(v) InfiniteJumpEnabled = v end })

Rayfield:LoadConfiguration()
