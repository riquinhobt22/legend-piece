local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- --- CONFIGURAÇÕES DE INFRAESTRUTURA ---
local LocalPlayer = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- --- ESTADOS MASTER (ON/OFF) ---
local _G = {
    AutoFarm = false,
    AutoQuest = false,
    AutoM1 = false,
    AutoSkills = false,
    HitboxMultiplier = false,
    FruitTeleportLoop = false,
    WalkSpeedEnabled = false
}

-- Valores de Configuração
local SelectedEnemy = "Nenhum"
local SelectedWeapon = "Nenhum"
local SelectedNPC = "Nenhum"
local HitboxSize = 20
local WalkSpeedValue = 16

-- Tabelas de Armazenamento Dinâmico
local DataBase = {
    Enemies = {},
    QuestGivers = {},
    Shops = {},
    MiscNPCs = {}
}

-- --- ENGINE 1: VARREDURA INTELIGENTE DE MAPA ---
local function CoreMapScan()
    -- Reseta tabelas para evitar duplicidade
    for k, v in pairs(DataBase) do DataBase[k] = {} end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") and obj.Name ~= LocalPlayer.Name then
            local nameLower = string.lower(obj.Name)
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            
            -- Classificação por Inteligência de Nome e Componentes
            if string.find(nameLower, "dealer") or string.find(nameLower, "shop") or string.find(nameLower, "vendedor") or string.find(nameLower, "gacha") or string.find(nameLower, "boat") then
                if not table.find(DataBase.Shops, obj.Name) then table.insert(DataBase.Shops, obj.Name) end
            elseif string.find(nameLower, "quest") or string.find(nameLower, "giver") or string.find(nameLower, "missao") then
                if not table.find(DataBase.QuestGivers, obj.Name) then table.insert(DataBase.QuestGivers, obj.Name) end
            elseif humanoid and humanoid.MaxHealth > 0 then
                if not table.find(DataBase.Enemies, obj.Name) then table.insert(DataBase.Enemies, obj.Name) end
            else
                if not table.find(DataBase.MiscNPCs, obj.Name) then table.insert(DataBase.MiscNPCs, obj.Name) end
            end
        end
    end
    
    -- Garante que o dropdown não quebre se o mapa estiver vazio
    for k, v in pairs(DataBase) do if #v == 0 then table.insert(DataBase[k], "Nenhum Detectado") end end
end

-- Lista inventário atualizado
local function GetInventoryTools()
    local tools = {}
    if LocalPlayer:FindFirstChild("Backpack") then
        for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do table.insert(tools, t.Name) end
    end
    if LocalPlayer.Character then
        for _, t in ipairs(LocalPlayer.Character:GetChildren()) do
            if t:IsA("Tool") and not table.find(tools, t.Name) then table.insert(tools, t.Name) end
        end
    end
    return #tools > 0 and tools or {"Nenhum equipado"}
end

-- --- ENGINE 2: SISTEMA DE MOVIMENTAÇÃO E TWEEN ---
local function SecureTween(targetCFrame)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local speed = 250 -- Velocidade segura para evitar Anti-Cheat
    
    local tweenInfo = TweenInfo.new(distance / speed, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    return tween
end

-- --- EXECUÇÃO DA INTERFACE ---
CoreMapScan()

local Window = Rayfield:CreateWindow({
   Name = "Legend Piece Hub | V7 SUPREME ENGINE",
   LoadingTitle = "Analisando Dados do Servidor...",
   LoadingSubtitle = "Arquitetura Universal Ativada",
   Theme = "Default",
   ConfigurationSaving = { Enabled = false }
})

-- --- CRIAÇÃO DAS ABAS ---
local TabFarm = Window:CreateTab("⚔️ Auto Farm & Combate", 4483362534)
local TabTeleport = Window:CreateTab("📍 Auto Teleport NPC", 4370345144)
local TabFruit = Window:CreateTab("🍎 Fruit Teleport", 4370345144)
local TabPlayer = Window:CreateTab("⚙️ Configurações", 4483362458)

-- --- ABA 1: COMBATE E FARM ---
TabFarm:CreateSection("Seleção de Alvos")
local DropEnemy = TabFarm:CreateDropdown({ Name = "Selecione o Inimigo/Boss", Options = DataBase.Enemies, CurrentOption = {"Selecione"}, Callback = function(O) SelectedEnemy = O[1] end })
local DropWeapon = TabFarm:CreateDropdown({ Name = "Equipar Arma ou Fruta", Options = GetInventoryTools(), CurrentOption = {"Selecione"}, Callback = function(O) SelectedWeapon = O[1] end })

TabFarm:CreateButton({ 
    Name = "🔄 Recarregar Dados do Jogo", 
    Callback = function() 
        CoreMapScan() 
        DropEnemy:Refresh(DataBase.Enemies, true) 
        DropWeapon:Refresh(GetInventoryTools(), true) 
    end 
})

TabFarm:CreateSection("Customização de Ataque")
TabFarm:CreateSlider({ Name = "Aumentar Hitbox (Alcance)", Range = {10, 60}, Increment = 1, CurrentValue = 20, Callback = function(v) HitboxSize = v end })

TabFarm:CreateSection("Ativadores (On / Off)")
TabFarm:CreateToggle({ Name = "Ativar Auto Farm (Trazer Mobs)", CurrentValue = false, Callback = function(v) _G.AutoFarm = v end })
TabFarm:CreateToggle({ Name = "Ativar Auto Quest Correspondente", CurrentValue = false, Callback = function(v) _G.AutoQuest = v end })
TabFarm:CreateToggle({ Name = "Ativar Auto Clicker M1", CurrentValue = false, Callback = function(v) _G.AutoM1 = v end })
TabFarm:CreateToggle({ Name = "Ativar Auto Uso de Skills (Armas e Frutas)", CurrentValue = false, Callback = function(v) _G.AutoSkills = v end })


-- --- ABA 2: TELEPORTE DE NPCS (ORGANIZADO) ---
TabTeleport:CreateSection("Categorias de Destino")
local DropGivers = TabTeleport:CreateDropdown({ Name = "NPCs de Missões (Givers)", Options = DataBase.QuestGivers, CurrentOption = {"Nenhum"}, Callback = function(O) SelectedNPC = O[1] end })
local DropShops = TabTeleport:CreateDropdown({ Name = "Lojas / Gacha / Barcos", Options = DataBase.Shops, CurrentOption = {"Nenhum"}, Callback = function(O) SelectedNPC = O[1] end })
local DropMisc = TabTeleport:CreateDropdown({ Name = "Outros NPCs do Mapa", Options = DataBase.MiscNPCs, CurrentOption = {"Nenhum"}, Callback = function(O) SelectedNPC = O[1] end })

TabTeleport:CreateButton({
    Name = "⚡ Executar Teleporte Instantâneo",
    Callback = function()
        if SelectedNPC ~= "Nenhum" and SelectedNPC ~= "Nenhum Detectado" then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == SelectedNPC and obj:FindFirstChild("HumanoidRootPart") then
                    SecureTween(obj.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3))
                    break
                end
            end
        end
    end
})


-- --- ABA 3: FRUIT TELEPORT ---
TabFruit:CreateSection("Coletor Automático de Frutas Spawadas")
TabFruit:CreateToggle({
    Name = "Loop Auto-Coletar Frutas do Chão (On/Off)",
    CurrentValue = false,
    Callback = function(v)
        _G.FruitTeleportLoop = v
    end
})


-- --- ABA 4: CONFIGURAÇÕES DO PERSONAGEM ---
TabPlayer:CreateSection("Atributos")
TabPlayer:CreateToggle({ Name = "Modificar Velocidade (On/Off)", CurrentValue = false, Callback = function(v) _G.WalkSpeedEnabled = v end })
TabPlayer:CreateSlider({ Name = "Ajustar Velocidade", Range = {16, 150}, Increment = 1, CurrentValue = 16, Callback = function(v) WalkSpeedValue = v end })


-- ==========================================
-- --- LOOPS DE AUTOMAÇÃO CRÍTICOS (BACKGROUND) ---
-- ==========================================

-- Loop de Movimentação Humana (Speed)
RunService.RenderStepped:Connect(function()
    if _G.WalkSpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = WalkSpeedValue
    end
end)

-- Auto Equipar Arma/Fruta selecionada
task.spawn(function()
    while task.wait(0.5) do
        if _G.AutoFarm and SelectedWeapon ~= "Nenhum" and SelectedWeapon ~= "Nenhum equipado" then
            if LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild(SelectedWeapon) then
                LocalPlayer.Backpack:FindFirstChild(SelectedWeapon).Parent = LocalPlayer.Character
            end
        end
    end
end)

-- Multiplicador Quântico de Hitbox (Faz os ataques corporais e skills acertarem)
task.spawn(function()
    while task.wait(0.3) do
        if _G.AutoFarm and SelectedEnemy ~= "Nenhum" then
            for _, mob in ipairs(workspace:GetDescendants()) do
                if mob:IsA("Model") and mob.Name == SelectedEnemy and mob:FindFirstChild("HumanoidRootPart") then
                    local root = mob.HumanoidRootPart
                    root.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                    root.Transparency = 0.75
                    root.CanCollide = false
                end
            end
        end
    end
end)

-- Puxador de Mobs (Agrupa os monstros na sua frente para otimizar o farm)
task.spawn(function()
    while task.wait(0.2) do
        if _G.AutoFarm and SelectedEnemy ~= "Nenhum" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local pRoot = LocalPlayer.Character.HumanoidRootPart
            for _, mob in ipairs(workspace:GetDescendants()) do
                if mob:IsA("Model") and mob.Name == SelectedEnemy and mob:FindFirstChild("HumanoidRootPart") then
                    local mHum = mob:FindFirstChildOfClass("Humanoid")
                    if mHum and mHum.Health > 0 then
                        mob.HumanoidRootPart.CFrame = pRoot.CFrame * CFrame.new(0, 0, -5)
                        mob.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                    end
                end
            end
        end
    end
end)

-- Clique M1 Automático Avançado
task.spawn(function()
    while task.wait(0.1) do
        if _G.AutoM1 and LocalPlayer.Character then
            local activeTool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if activeTool then
                activeTool:Activate()
                -- Varre os canais internos da própria arma em busca do gatilho de ataque primário
                for _, child in ipairs(activeTool:GetDescendants()) do
                    if child:IsA("RemoteEvent") then
                        child:FireServer()
                        child:FireServer("Attack")
                    end
                end
            end
        end
    end
end)

-- Motor Decodificador de Skills (Varre e força o uso de habilidades de Frutas/Armas)
task.spawn(function()
    while task.wait(0.4) do
        if _G.AutoSkills and LocalPlayer.Character then
            local activeTool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if activeTool then
                -- Alfabeto de chaves padrão de jogos de One Piece no Roblox
                local universalTriggers = {"Z", "X", "C", "V", "Q", "E"}
                local mockPosition = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -10)
                
                for _, remote in ipairs(activeTool:GetDescendants()) do
                    if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                        for _, key in ipairs(universalTriggers) do
                            pcall(function()
                                if remote:IsA("RemoteEvent") then
                                    remote:FireServer(key)
                                    remote:FireServer(key, mockPosition.Position)
                                    remote:FireServer("Skill", key)
                                else
                                    remote:InvokeServer(key)
                                end
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- Auto Quest Inteligente
task.spawn(function()
    while task.wait(2) do
        if _G.AutoQuest and SelectedEnemy ~= "Nenhum" then
            -- Procura remotes globais de missões no sistema do jogo
            for _, service in ipairs({ReplicatedStorage, game:GetService("HttpService")}) do
                for _, obj in ipairs(service:GetDescendants()) do
                    if obj:IsA("RemoteEvent") and (string.find(string.lower(obj.Name), "quest") or string.find(string.lower(obj.Name), "mission")) then
                        pcall(function() obj:FireServer("AcceptQuest", SelectedEnemy) obj:FireServer(SelectedEnemy) end)
                    end
                end
            end
        end
    end
end)

-- Loop Caçador do Fruit Teleport
task.spawn(function()
    while task.wait(1) do
        if _G.FruitTeleportLoop then
            for _, item in ipairs(workspace:GetDescendants()) do
                if item:IsA("Model") and (string.find(string.lower(item.Name), "fruit") or string.find(string.lower(item.Name), "fruta") or item:FindFirstChild("FruitCharacter")) then
                    local part = item:FindFirstChildOfClass("BasePart") or item:FindFirstChild("Handle")
                    if part then
                        SecureTween(part.CFrame)
                        break
                    end
                end
            end
        end
    end
end)

Rayfield:LoadConfiguration()
