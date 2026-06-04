local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- --- COMPONENTES DO MOTOR (V9) ---
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

-- --- FLAGS DE ATIVAÇÃO ---
local Flags = {
    AutoFarm = false,
    AutoQuest = false,
    AutoM1 = false,
    AutoSkills = false,
    FruitRadar = false,
    GodMode = false,
    SpeedHack = false
}

local Config = {
    Enemy = "Nenhum",
    Weapon = "Nenhum",
    TargetNPC = "Nenhum",
    HitboxSize = 25,
    SpeedValue = 16
}

local Memory = { Enemies = {}, Quests = {}, Shops = {}, Extras = {} }

-- --- RECURSO EXCLUSIVO: ESTABILIZADOR ANTI-KICK (ANTI-AFK) ---
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(0.5)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- --- MOTOR DE MAPEAMENTO KEYBREW ---
local function ExecuteDataScan()
    for cat, _ in pairs(Memory) do Memory[cat] = {} end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") and obj.Name ~= LocalPlayer.Name then
            local tag = string.lower(obj.Name)
            local hum = obj:FindFirstChildOfClass("Humanoid")
            
            if string.find(tag, "shop") or string.find(tag, "dealer") or string.find(tag, "vendedor") or string.find(tag, "gacha") then
                if not table.find(Memory.Shops, obj.Name) then table.insert(Memory.Shops, obj.Name) end
            elseif string.find(tag, "quest") or string.find(tag, "giver") or string.find(tag, "missao") then
                if not table.find(Memory.Quests, obj.Name) then table.insert(Memory.Quests, obj.Name) end
            elseif hum and hum.MaxHealth > 0 then
                if not table.find(Memory.Enemies, obj.Name) then table.insert(Memory.Enemies, obj.Name) end
            else
                if not table.find(Memory.Extras, obj.Name) then table.insert(Memory.Extras, obj.Name) end
            end
        end
    end
    for cat, list in pairs(Memory) do if #list == 0 then table.insert(Memory[cat], "Nenhum") end end
end

-- Inventário Filtrado para Armas/Frutas
local function GetCleanBackpack()
    local list = {}
    if LocalPlayer:FindFirstChild("Backpack") then
        for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do table.insert(list, v.Name) end
    end
    if LocalPlayer.Character then
        for _, v in ipairs(LocalPlayer.Character:GetChildren()) do
            if v:IsA("Tool") and not table.find(list, v.Name) then table.insert(list, v.Name) end
        end
    end
    return #list > 0 and list or {"Nenhum Item"}
end

-- --- SISTEMA DE MOVIMENTAÇÃO POR CONSTANTE DE TWEEN ---
local function KeyBrewTween(targetCFrame)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local range = (hrp.Position - targetCFrame.Position).Magnitude
    local dynamicSpeed = 280 -- Velocidade sincronizada do KeyBrew para não tomar Ban
    
    local tweenSettings = TweenInfo.new(range / dynamicSpeed, Enum.EasingStyle.Linear)
    local action = TweenService:Create(hrp, tweenSettings, {CFrame = targetCFrame})
    action:Play()
    return action
end

ExecuteDataScan()

-- --- JANELA RAYFIELD SLICK DESIGN ---
local Window = Rayfield:CreateWindow({
   Name = "KeyBrew Premium | V9 EXPERT HUB",
   LoadingTitle = "Injetando Estrutura KeyBrew...",
   LoadingSubtitle = "Otimizado para Delta Mobile",
   Theme = "Default",
   ConfigurationSaving = { Enabled = false }
})

local TabMain = Window:CreateTab("⚔️ Auto Farm Engine", 4483362534)
local TabTeleports = Window:CreateTab("📍 Teleports", 4370345144)
local TabItems = Window:CreateTab("🍎 Coletor", 4370345144)
local TabMisc = Window:CreateTab("⚙️ Ajustes", 4483362458)

-- --- ABA PRINCIPAL: COMBATE ---
TabMain:CreateSection("Definição de Alvos")
local DropMob = TabMain:CreateDropdown({ Name = "Selecione o Monstro", Options = Memory.Enemies, CurrentOption = {"Selecione"}, Callback = function(O) Config.Enemy = O[1] end })
local DropItem = TabMain:CreateDropdown({ Name = "Selecione a Arma/Fruta", Options = GetCleanBackpack(), CurrentOption = {"Selecione"}, Callback = function(O) Config.Weapon = O[1] end })

TabMain:CreateButton({ 
    Name = "🔄 Atualizar Dados do Mapa (Refresh)", 
    Callback = function() 
        ExecuteDataScan() 
        DropMob:Refresh(Memory.Enemies, true) 
        DropItem:Refresh(GetCleanBackpack(), true) 
    end 
})

TabMain:CreateSection("Customização do Alcance")
TabMain:CreateSlider({ Name = "Tamanho da Hitbox (Mobs)", Range = {15, 100}, Increment = 1, CurrentValue = 25, Callback = function(v) Config.HitboxSize = v end })

TabMain:CreateSection("Controles Principais (On / Off)")
TabMain:CreateToggle({ Name = "Ativar Autofarm Inteligente", CurrentValue = false, Callback = function(v) Flags.AutoFarm = v end })
TabMain:CreateToggle({ Name = "Ativar Auto Quest Correspondente", CurrentValue = false, Callback = function(v) Flags.AutoQuest = v end })
TabMain:CreateToggle({ Name = "Ativar Auto Clique M1", CurrentValue = false, Callback = function(v) Flags.AutoM1 = v end })
TabMain:CreateToggle({ Name = "Ativar Uso de Habilidades (Skills)", CurrentValue = false, Callback = function(v) Flags.AutoSkills = v end })


-- --- ABA DE TELEPORTES ---
TabTeleports:CreateSection("NPCs Importantes")
local TargetQuest = TabTeleports:CreateDropdown({ Name = "Provedores de Missões", Options = Memory.Quests, CurrentOption = {"Nenhum"}, Callback = function(O) Config.TargetNPC = O[1] end })
local TargetShop = TabTeleports:CreateDropdown({ Name = "Lojas e Gachas", Options = Memory.Shops, CurrentOption = {"Nenhum"}, Callback = function(O) Config.TargetNPC = O[1] end })

TabTeleports:CreateButton({
    Name = "⚡ Ir até o NPC Selecionado",
    Callback = function()
        if Config.TargetNPC ~= "Nenhum" then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == Config.TargetNPC and obj:FindFirstChild("HumanoidRootPart") then
                    KeyBrewTween(obj.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4))
                    break
                end
            end
        end
    end
})


-- --- ABA DE COLETORES ---
TabItems:CreateSection("Rastreamento de Itens no Chão")
TabItems:CreateToggle({ Name = "Auto Puxar Frutas Espalhadas (Magnet)", CurrentValue = false, Callback = function(v) Flags.FruitRadar = v end })


-- --- ABA EXTRA ---
TabMisc:CreateSection("Atributos do Jogador")
TabMisc:CreateToggle({ Name = "Ativar God Mode (No Damage)", CurrentValue = false, Callback = function(v) Flags.GodMode = v end })
TabMisc:CreateToggle({ Name = "Ativar Modificador de Velocidade", CurrentValue = false, Callback = function(v) Flags.SpeedHack = v end })
TabMisc:CreateSlider({ Name = "Velocidade", Range = {16, 250}, Increment = 1, CurrentValue = 16, Callback = function(v) Config.SpeedValue = v end })


-- ================================================================
-- --- LOOPS DE EXECUÇÃO MULTITHREADING (NATIVOS DO PROCESSO) ---
-- ================================================================

-- Loop Físico: Posicionamento Baseado na Lógica KeyBrew
RunService.Heartbeat:Connect(function()
    -- Ajuste de Velocidade
    if Flags.SpeedHack and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = Config.SpeedValue
    end
    
    -- Mecanismo Safe Position (Fica acima do mob batendo para baixo)
    if Flags.AutoFarm and Config.Enemy ~= "Nenhum" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local rootPart = LocalPlayer.Character.HumanoidRootPart
        for _, mob in ipairs(workspace:GetDescendants()) do
            if mob:IsA("Model") and mob.Name == Config.Enemy and mob:FindFirstChild("HumanoidRootPart") then
                local hum = mob:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    -- Fixa a rotação para baixo e suspende a gravidade do player
                    rootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                    mob.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                    break
                end
            end
        end
    end
end)

-- God Mode Nativo (Desativa colisão física com ataques de Npcs)
RunService.Stepped:Connect(function()
    if Flags.GodMode and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- Multiplicador Quântico de Hitbox
task.spawn(function()
    while task.wait(0.4) do
        if Flags.AutoFarm and Config.Enemy ~= "Nenhum" then
            for _, mob in ipairs(workspace:GetDescendants()) do
                if mob:IsA("Model") and mob.Name == Config.Enemy and mob:FindFirstChild("HumanoidRootPart") then
                    local hrp = mob.HumanoidRootPart
                    hrp.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                    hrp.Transparency = 0.8
                    hrp.CanCollide = false
                end
            end
        end
    end
end)

-- Auto Equipador Reativo
task.spawn(function()
    while task.wait(0.5) do
        if Flags.AutoFarm and Config.Weapon ~= "Nenhum" and Config.Weapon ~= "Nenhum Item" then
            if LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild(Config.Weapon) then
                LocalPlayer.Backpack:FindFirstChild(Config.Weapon).Parent = LocalPlayer.Character
            end
        end
    end
end)

-- Auto Clicker Físico por Tela
task.spawn(function()
    while task.wait(0.1) do
        if Flags.AutoM1 and Flags.AutoFarm and LocalPlayer.Character then
            if LocalPlayer.Character:FindFirstChildOfClass("Tool") then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(850, 420))
            end
        end
    end
end)

-- Forçador de Habilidades (Skills) via Triggers do Legend Piece
task.spawn(function()
    while task.wait(0.3) do
        if Flags.AutoSkills and Flags.AutoFarm and LocalPlayer.Character then
            local currentTool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if currentTool then
                local keys = {"Z", "X", "C", "V", "E", "Q"}
                local direction = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -10)
                
                for _, element in ipairs(currentTool:GetDescendants()) do
                    if element:IsA("RemoteEvent") or element:IsA("RemoteFunction") then
                        for _, key in ipairs(keys) do
                            pcall(function()
                                if element:IsA("RemoteEvent") then
                                    element:FireServer(key, direction.Position)
                                    element:FireServer("Skill", key)
                                    element:FireServer(key)
                                else
                                    element:InvokeServer(key, direction.Position)
                                end
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- Receptor de Missões KeyBrew Remotes
task.spawn(function()
    while task.wait(2) do
        if Flags.AutoQuest and Config.Enemy ~= "Nenhum" then
            -- Dispara diretamente nas rotas oficiais extraídas do loader do KeyBrew
            for _, service in ipairs({ReplicatedStorage, workspace}) do
                for _, child in ipairs(service:GetDescendants()) do
                    if child:IsA("RemoteEvent") and (string.find(string.lower(child.Name), "quest") or string.find(string.lower(child.Name), "mission") or string.find(string.lower(child.Name), "communicate")) then
                        pcall(function() 
                            child:FireServer("AcceptQuest", Config.Enemy)
                            child:FireServer(Config.Enemy) 
                        end)
                    end
                end
            end
        end
    end
end)

-- Atração Magnética de Frutas
task.spawn(function()
    while task.wait(1) do
        if Flags.FruitRadar then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and (string.find(string.lower(obj.Name), "fruit") or string.find(string.lower(obj.Name), "fruta") or obj:FindFirstChild("FruitCharacter")) then
                    local corePart = obj:FindFirstChildOfClass("BasePart") or obj:FindFirstChild("Handle")
                    if corePart then
                        KeyBrewTween(corePart.CFrame)
                        break
                    end
                end
            end
        end
    end
end)

Rayfield:LoadConfiguration()
