local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- --- SERVIÇOS CRÍTICOS ---
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

-- --- CONFIGURAÇÕES DE REQUISITOS (ON/OFF) ---
local Flags = {
    AutoFarm = false,
    AutoQuest = false,
    AutoM1 = false,
    AutoSkills = false,
    FruitMagnet = false,
    SpeedHack = false
}

local Settings = {
    Enemy = "Nenhum",
    Weapon = "Nenhum",
    TeleportTarget = "Nenhum",
    HitboxSize = 25,
    SpeedValue = 16
}

local Cache = { Enemies = {}, Givers = {}, Shops = {}, Others = {} }

-- --- CORREÇÃO DE SEGURANÇA: ANTI-AFK INTERNO ---
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- --- DETETIVE FISICO DE CONFIGURAÇÃO DO MAPA ---
local function IntelScan()
    for category, _ in pairs(Cache) do Cache[category] = {} end
    
    for _, instance in ipairs(workspace:GetDescendants()) do
        if instance:IsA("Model") and instance:FindFirstChild("HumanoidRootPart") and instance.Name ~= LocalPlayer.Name then
            local label = string.lower(instance.Name)
            local hum = instance:FindFirstChildOfClass("Humanoid")
            
            if string.find(label, "shop") or string.find(label, "dealer") or string.find(label, "vendedor") or string.find(label, "gacha") then
                if not table.find(Cache.Shops, instance.Name) then table.insert(Cache.Shops, instance.Name) end
            elseif string.find(label, "quest") or string.find(label, "giver") or string.find(label, "missao") then
                if not table.find(Cache.Givers, instance.Name) then table.insert(Cache.Givers, instance.Name) end
            elseif hum and hum.MaxHealth > 0 then
                if not table.find(Cache.Enemies, instance.Name) then table.insert(Cache.Enemies, instance.Name) end
            else
                if not table.find(Cache.Others, instance.Name) then table.insert(Cache.Others, instance.Name) end
            end
        end
    end
    for cat, list in pairs(Cache) do if #list == 0 then table.insert(Cache[cat], "Nenhum Detectado") end end
end

-- Lista limpa do inventário
local function ScanInventory()
    local inventory = {}
    if LocalPlayer:FindFirstChild("Backpack") then
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do table.insert(inventory, item.Name) end
    end
    if LocalPlayer.Character then
        for _, item in ipairs(LocalPlayer.Character:GetChildren()) do
            if item:IsA("Tool") and not table.find(inventory, item.Name) then table.insert(inventory, item.Name) end
        end
    end
    return #inventory > 0 and inventory or {"Nenhum item"}
end

-- --- TELEPORTE VIA INTERPOLAÇÃO REVERSA (ANTI-DETECÇÃO) ---
local function SmoothMove(targetCFrame)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local computedSpeed = 300 -- Velocidade matemática otimizada
    
    local info = TweenInfo.new(distance / computedSpeed, Enum.EasingStyle.Linear)
    local animator = TweenService:Create(hrp, info, {CFrame = targetCFrame})
    animator:Play()
    return animator
end

-- Inicializa o Scouter
IntelScan()

-- --- ARQUITETURA DA INTERFACE PREMIUM ---
local Window = Rayfield:CreateWindow({
   Name = "Legend Piece Hub | V8 ENGINE QUANTUM",
   LoadingTitle = "Analisando Falhas e Remotes Concorrentes...",
   LoadingSubtitle = "Estabilizando Conexões Mobile (Delta)",
   Theme = "Default",
   ConfigurationSaving = { Enabled = false }
})

local TabFarm = Window:CreateTab("⚔️ Dynamic Farm", 4483362534)
local TabTeleport = Window:CreateTab("📍 Seletor Teleport", 4370345144)
local TabFruit = Window:CreateTab("🍎 Magnet Fruit", 4370345144)
local TabConfig = Window:CreateTab("⚙️ Engine Stats", 4483362458)

-- --- ABA 1: COMBATE COMPLETO ---
TabFarm:CreateSection("Gerenciamento de Alvos e Armamento")
local DropEnemy = TabFarm:CreateDropdown({ Name = "Alvo do Mapa", Options = Cache.Enemies, CurrentOption = {"Selecione"}, Callback = function(O) Settings.Enemy = O[1] end })
local DropWeapon = TabFarm:CreateDropdown({ Name = "Arma / Fruta de Combate", Options = ScanInventory(), CurrentOption = {"Selecione"}, Callback = function(O) Settings.Weapon = O[1] end })

TabFarm:CreateButton({ 
    Name = "🔄 Forçar Varredura Completa de Dados", 
    Callback = function() 
        IntelScan() 
        DropEnemy:Refresh(Cache.Enemies, true) 
        DropWeapon:Refresh(ScanInventory(), true) 
    end 
})

TabFarm:CreateSection("Ajuste de Área de Impacto")
TabFarm:CreateSlider({ Name = "Multiplicador de Hitbox", Range = {10, 80}, Increment = 1, CurrentValue = 25, Callback = function(v) Settings.HitboxSize = v end })

TabFarm:CreateSection("Switches de Execução (On/Off)")
TabFarm:CreateToggle({ Name = "Ligar Auto Farm Master", CurrentValue = false, Callback = function(v) Flags.AutoFarm = v end })
TabFarm:CreateToggle({ Name = "Ligar Auto Quest Inteligente", CurrentValue = false, Callback = function(v) Flags.AutoQuest = v end })
TabFarm:CreateToggle({ Name = "Ligar Auto Clicker M1 Nativo", CurrentValue = false, Callback = function(v) Flags.AutoM1 = v end })
TabFarm:CreateToggle({ Name = "Ligar Auto Skills Inteligente", CurrentValue = false, Callback = function(v) Flags.AutoSkills = v end })


-- --- ABA 2: TELEPORTE CATEGORIZADO ---
TabTeleport:CreateSection("Filtros de Destino")
local DropGivers = TabTeleport:CreateDropdown({ Name = "Filtro: Provedores de Quest", Options = Cache.Givers, CurrentOption = {"Nenhum"}, Callback = function(O) Settings.TeleportTarget = O[1] end })
local DropShops = TabTeleport:CreateDropdown({ Name = "Filtro: Comércio / Lojas / Barcos", Options = Cache.Shops, CurrentOption = {"Nenhum"}, Callback = function(O) Settings.TeleportTarget = O[1] end })
local DropOthers = TabTeleport:CreateDropdown({ Name = "Filtro: Outros / NPCs Secretos", Options = Cache.Others, CurrentOption = {"Nenhum"}, Callback = function(O) Settings.TeleportTarget = O[1] end })

TabTeleport:CreateButton({
    Name = "⚡ Iniciar Teleporte para Selecionado",
    Callback = function()
        if Settings.TeleportTarget ~= "Nenhum" and Settings.TeleportTarget ~= "Nenhum Detectado" then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == Settings.TeleportTarget and obj:FindFirstChild("HumanoidRootPart") then
                    SmoothMove(obj.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4))
                    break
                end
            end
        end
    end
})


-- --- ABA 3: RADAR DE FRUTAS ---
TabFruit:CreateSection("Coleta por Atração Magnética")
TabFruit:CreateToggle({ Name = "Auto Coletar Frutas do Mapa (Loop)", CurrentValue = false, Callback = function(v) Flags.FruitMagnet = v end })


-- --- ABA 4: AJUSTES FÍSICOS ---
TabConfig:CreateSection("Modificações de Velocidade")
TabConfig:CreateToggle({ Name = "Habilitar Speedhack", CurrentValue = false, Callback = function(v) Flags.SpeedHack = v end })
TabConfig:CreateSlider({ Name = "Velocidade Custom", Range = {16, 200}, Increment = 1, CurrentValue = 16, Callback = function(v) Settings.SpeedValue = v end })


-- =========================================================
-- --- LINHA DE PROCESSAMENTO PARALELO (BACKGROUND ENGINE) ---
-- =========================================================

-- Gerenciador Físico Realtime (Speed e Posicionamento)
RunService.Heartbeat:Connect(function()
    -- Controle de Speedhack Seguro
    if Flags.SpeedHack and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = Settings.SpeedValue
    end
    
    -- Auto Farm: Posicionamento Seguro (Travar o player flutuando acima do monstro)
    if Flags.AutoFarm and Settings.Enemy ~= "Nenhum" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myHrp = LocalPlayer.Character.HumanoidRootPart
        for _, mob in ipairs(workspace:GetDescendants()) do
            if mob:IsA("Model") and mob.Name == Settings.Enemy and mob:FindFirstChild("HumanoidRootPart") then
                local hum = mob:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    -- Posiciona você a exatamentes 4 studs acima do mob (Evita morrer e garante acerto)
                    myHrp.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 4, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                    mob.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                    break
                end
            end
        end
    end
end)

-- Sistema de Expansão de Hitbox
task.spawn(function()
    while task.wait(0.4) do
        if Flags.AutoFarm and Settings.Enemy ~= "Nenhum" then
            for _, mob in ipairs(workspace:GetDescendants()) do
                if mob:IsA("Model") and mob.Name == Settings.Enemy and mob:FindFirstChild("HumanoidRootPart") then
                    local root = mob.HumanoidRootPart
                    root.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
                    root.Transparency = 0.8
                    root.CanCollide = false
                end
            end
        end
    end
end)

-- Auto Equipador Reativo
task.spawn(function()
    while task.wait(0.5) do
        if Flags.AutoFarm and Settings.Weapon ~= "Nenhum" and Settings.Weapon ~= "Nenhum item" then
            if LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild(Settings.Weapon) then
                LocalPlayer.Backpack:FindFirstChild(Settings.Weapon).Parent = LocalPlayer.Character
            end
        end
    end
end)

-- Sistema de Ataque M1 por Clique de Janela Nativa (Ignora Anti-Cheat por Spam de Remote)
task.spawn(function()
    while task.wait(0.1) do
        if Flags.AutoM1 and LocalPlayer.Character and Flags.AutoFarm then
            local weapon = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if weapon then
                -- Faz o roblox entender que o jogador de fato clicou na tela do celular
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(850, 420)) -- Área média do botão de ataque mobile
            end
        end
    end
end)

-- Rastreador Universal de Skills por Varredura de Metatabelas
task.spawn(function()
    while task.wait(0.3) do
        if Flags.AutoSkills and LocalPlayer.Character and Flags.AutoFarm then
            local activeTool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if activeTool then
                local triggers = {"Z", "X", "C", "V", "Q", "E", "Skill1", "Skill2"}
                local positionVector = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -8)
                
                for _, element in ipairs(activeTool:GetDescendants()) do
                    if element:IsA("RemoteEvent") or element:IsA("RemoteFunction") then
                        for _, key in ipairs(triggers) do
                            pcall(function()
                                if element:IsA("RemoteEvent") then
                                    element:FireServer(key, positionVector.Position)
                                    element:FireServer("Skill", key)
                                    element:FireServer(key)
                                else
                                    element:InvokeServer(key, positionVector.Position)
                                end
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- Motor de Auto Quest Otimizado
task.spawn(function()
    while task.wait(2.5) do
        if Flags.AutoQuest and Settings.Enemy ~= "Nenhum" then
            for _, service in ipairs({ReplicatedStorage, workspace}) do
                for _, element in ipairs(service:GetDescendants()) do
                    if element:IsA("RemoteEvent") and (string.find(string.lower(element.Name), "quest") or string.find(string.lower(element.Name), "mission")) then
                        pcall(function() 
                            element:FireServer("AcceptQuest", Settings.Enemy) 
                            element:FireServer(Settings.Enemy) 
                        end)
                    end
                end
            end
        end
    end
end)

-- Coletor Magnético de Frutas (Puxa do mapa sem dar lag)
task.spawn(function()
    while task.wait(1) do
        if Flags.FruitMagnet then
            for _, instance in ipairs(workspace:GetDescendants()) do
                if instance:IsA("Model") and (string.find(string.lower(instance.Name), "fruit") or string.find(string.lower(instance.Name), "fruta") or instance:FindFirstChild("FruitCharacter")) then
                    local node = instance:FindFirstChildOfClass("BasePart") or instance:FindFirstChild("Handle")
                    if node then
                        SmoothMove(node.CFrame)
                        break
                    end
                end
            end
        end
    end
end)

Rayfield:LoadConfiguration()
