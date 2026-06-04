local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- --- CONFIGURAÇÃO DE SERVIÇOS ---
local LocalPlayer = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

-- --- VARIÁVEIS DE CONTROLE HUB (TODAS COM ON/OFF) ---
local WalkSpeedEnabled = false
local WalkSpeedValue = 16
local JumpPowerEnabled = false
local JumpPowerValue = 50
local InfiniteJumpEnabled = false
local FlyEnabled = false
local FlySpeed = 50

local AutoFarmEnabled = false
local AutoQuestEnabled = false
local AutoAttackEnabled = false
local SpamFruitSkillsEnabled = false
local SelectedWeapon = ""
local SkillSpamDelay = 0.5
local SelectedEnemy = "Nenhum"

local FastModeEnabled = false
local NoCameraShake = true

-- Listas Dinâmicas de Teleporte
local SelectedTeleportNPC = "Nenhum"
local NPC_Categories = {
    ["Combate / Bosses"] = {},
    ["Missões de Level (Givers)"] = {},
    ["Lojas / Vendedores"] = {},
    ["Quests Especiais / Outros"] = {}
}

-- --- FUNÇÃO AUXILIAR DE TELEPORTE SEGURO ---
local function SecureTeleport(targetCFrame)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame
    end
end

-- --- SCANNER SUPREMO DE NPCS (SEPARA POR CATEGORIA NA HORA) ---
local function ScanAllNPCs()
    -- Limpa as tabelas antes de escanear
    for cat, _ in pairs(NPC_Categories) do NPC_Categories[cat] = {} end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") and obj.Name ~= LocalPlayer.Name then
            local nameLower = string.lower(obj.Name)
            local hum = obj:FindFirstChildOfClass("Humanoid")
            
            -- 1. Lojas e Vendedores (Contém palavras de comércio ou caixas de diálogo sem vida)
            if string.find(nameLower, "dealer") or string.find(nameLower, "seller") or string.find(nameLower, "shop") or string.find(nameLower, "vendedor") or string.find(nameLower, "gacha") or string.find(nameLower, "boat") or string.find(nameLower, "ship") then
                if not table.find(NPC_Categories["Lojas / Vendedores"], obj.Name) then
                    table.insert(NPC_Categories["Lojas / Vendedores"], obj.Name)
                end
            
            -- 2. Quest Givers de Level Up (Contém palavras padrão de missões iniciais)
            elseif string.find(nameLower, "quest") or string.find(nameLower, "giver") or string.find(nameLower, "missao") then
                if not table.find(NPC_Categories["Missões de Level (Givers)"], obj.Name) then
                    table.insert(NPC_Categories["Missões de Level (Givers)"], obj.Name)
                end
                
            -- 3. Quests Especiais, Segredos ou NPCs de Doação/Interação
            elseif obj:FindFirstChild("ProximityPrompt") or obj:FindFirstChild("ClickDetector") or string.find(nameLower, "master") or string.find(nameLower, "lore") or string.find(nameLower, "donate") then
                if not table.find(NPC_Categories["Quests Especiais / Outros"], obj.Name) then
                    table.insert(NPC_Categories["Quests Especiais / Outros"], obj.Name)
                end
                
            -- 4. Inimigos Combativeis e Bosses (Tem vida configurada alta e não se encaixam acima)
            elseif hum and hum.MaxHealth > 0 then
                if not table.find(NPC_Categories["Combate / Bosses"], obj.Name) then
                    table.insert(NPC_Categories["Combate / Bosses"], obj.Name)
                end
            end
        end
    end
    
    -- Garante que nenhuma lista fique vazia para não quebrar a interface
    for cat, lista in pairs(NPC_Categories) do
        if #lista == 0 then table.insert(NPC_Categories[cat], "Nenhum nesta ilha") end
    end
end

-- Pega as armas da mochila
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
    if #items == 0 then table.insert(items, "Nenhum item equipado") end
    return items
end

-- --- CRIAR INTERFACE RAYFIELD ---
local Window = Rayfield:CreateWindow({
   Name = "Legend Piece Hub | Ultimate Control",
   LoadingTitle = "Iniciando Hub Simplificado...",
   LoadingSubtitle = "Controles Unificados de Teleporte",
   Theme = "Default",
   ConfigurationSaving = { Enabled = false }
})

-- Executa o primeiro scan ao ligar
ScanAllNPCs()

-- --- MÓDULOS DE ATIVAÇÃO (LOOPS LIGAR/DESLIGAR) ---

-- Loop de Velocidade e Modificadores Físicos
RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if WalkSpeedEnabled then hum.WalkSpeed = WalkSpeedValue else hum.WalkSpeed = 16 end
        if JumpPowerEnabled then hum.JumpPower = JumpPowerValue hum.UseJumpPower = true end
    end
    if NoCameraShake and workspace.CurrentCamera then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(0, 0, 0)
        end
    end
end)

-- Pulo Infinito
UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

-- Auto Equipar Arma
task.spawn(function()
    while task.wait(0.5) do
        if AutoFarmEnabled and SelectedWeapon ~= "" and SelectedWeapon ~= "Nenhum item equipado" then
            if LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Character then
                local tool = LocalPlayer.Backpack:FindFirstChild(SelectedWeapon)
                if tool and not LocalPlayer.Character:FindFirstChild(SelectedWeapon) then tool.Parent = LocalPlayer.Character end
            end
        end
    end
end)

-- Auto Clicker M1 (On/Off)
task.spawn(function()
    while task.wait(0.1) do 
        if AutoAttackEnabled and LocalPlayer.Character then
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then 
                tool:Activate()
                local remote = tool:FindFirstChild("Remote") or tool:FindFirstChild("Attack") or tool:FindFirstChild("MainRemote")
                if remote and remote:IsA("RemoteEvent") then remote:FireServer("Attack", "LeftClick") end
            end
        end
    end
end)

-- Spam Skills Inteligente (On/Off)
task.spawn(function()
    while true do
        task.wait(SkillSpamDelay)
        if SpamFruitSkillsEnabled and LocalPlayer.Character then
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                local skillKeys = {"Z", "X", "C", "V", "Q", "E"}
                for _, remote in ipairs(tool:GetDescendants()) do
                    if remote:IsA("RemoteEvent") then
                        local targetPos = LocalPlayer.Character.HumanoidRootPart.CFrame + (LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector * 10)
                        for _, key in ipairs(skillKeys) do
                            pcall(function() remote:FireServer(key, targetPos.Position) end)
                        end
                    end
                end
            end
        end
    end
end)

-- Auto Coleta de Quests de Level Up (On/Off)
task.spawn(function()
    while task.wait(1.5) do
        if AutoQuestEnabled and SelectedEnemy ~= "Nenhum" then
            local hasQuest = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("QuestUI")
            if not hasQuest or (LocalPlayer.PlayerGui:FindFirstChild("QuestUI") and not LocalPlayer.PlayerGui.QuestUI.Enabled) then
                for _, npc in ipairs(workspace:GetDescendants()) do
                    if npc:IsA("Model") and (string.find(string.lower(npc.Name), "quest") or string.find(string.lower(npc.Name), "giver")) then
                        local remote = npc:FindFirstChild("QuestRemote") or npc:FindFirstChild("Remote") or game:GetService("ReplicatedStorage"):FindFirstChild("QuestSystem")
                        if remote and remote:IsA("RemoteEvent") then remote:FireServer("AcceptQuest", SelectedEnemy) end
                    end
                end
            end
        end
    end
end)

-- Auto Farm Seletivo por Teleporte de Monstros (On/Off)
task.spawn(function()
    while task.wait(0.2) do
        if AutoFarmEnabled and SelectedEnemy ~= "Nenhum" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myHrp = LocalPlayer.Character.HumanoidRootPart
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == SelectedEnemy and obj:FindFirstChild("HumanoidRootPart") then
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        obj.HumanoidRootPart.CFrame = myHrp.CFrame * CFrame.new(0, 0, -5)
                        obj.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                    end
                end
            end
        end
    end
end)


-- --- CRIAÇÃO DAS ABAS ---
local TabFarm = Window:CreateTab("Combate & Auto Farm", 4483362534)
local TabTeleport = Window:CreateTab("Menu de Teleportes", 4370345144)
local TabPlayer = Window:CreateTab("Ajustes Personagem", 4483362458)

-- --- ABA 1: COMBATE & AUTO FARM ---
TabFarm:CreateSection("Painel de Configuração")

local EnemyDropdown = TabFarm:CreateDropdown({ Name = "Alvo do Auto Farm", Options = NPC_Categories["Combate / Bosses"], CurrentOption = {"Selecione"}, MultipleOptions = false, Callback = function(O) SelectedEnemy = O[1] end })
local WeaponDropdown = TabFarm:CreateDropdown({ Name = "Arma Equipada", Options = GetLegendWeapons(), CurrentOption = {"Selecione"}, MultipleOptions = false, Callback = function(O) SelectedWeapon = O[1] end })

TabFarm:CreateButton({ Name = "🔄 Recarregar Mobs e Mochila", Callback = function() ScanAllNPCs() EnemyDropdown:Refresh(NPC_Categories["Combate / Bosses"], true) WeaponDropdown:Refresh(GetLegendWeapons(), true) end })

TabFarm:CreateSection("Motores de Automação (ON / OFF)")
TabFarm:CreateToggle({ Name = "Iniciar Auto Farm (Puxar Mobs)", CurrentValue = false, Callback = function(v) AutoFarmEnabled = v end })
TabFarm:CreateToggle({ Name = "Aceitar Missão Automaticamente", CurrentValue = false, Callback = function(v) AutoQuestEnabled = v end })
TabFarm:CreateToggle({ Name = "Auto Clicker M1 (Ataque Básico)", CurrentValue = false, Callback = function(v) AutoAttackEnabled = v end })
TabFarm:CreateToggle({ Name = "Spammar Habilidades/Skills", CurrentValue = false, Callback = function(v) SpamFruitSkillsEnabled = v end })
TabFarm:CreateSlider({ Name = "Delay das Skills (Segundos)", Range = {1, 10}, Increment = 1, CurrentValue = 5, Callback = function(v) SkillSpamDelay = v / 10 end })


-- --- ABA 2: MENU DE TELEPORTES CRITÍCOS (SISTEMA SELETIVO) ---
TabTeleport:CreateSection("Escolha seu Destino por Categoria")

-- Dropdowns Dinâmicos atualizados pelo scanner
local DropGivers = TabTeleport:CreateDropdown({ Name = "NPCs de Missões de Level", Options = NPC_Categories["Missões de Level (Givers)"], CurrentOption = {"Nenhum"}, MultipleOptions = false, Callback = function(O) SelectedTeleportNPC = O[1] end })
local DropShops = TabTeleport:CreateDropdown({ Name = "Lojas e Vendedores", Options = NPC_Categories["Lojas / Vendedores"], CurrentOption = {"Nenhum"}, MultipleOptions = false, Callback = function(O) SelectedTeleportNPC = O[1] end })
local DropSpecial = TabTeleport:CreateDropdown({ Name = "Quests Especiais / Doações / Outros", Options = NPC_Categories["Quests Especiais / Outros"], CurrentOption = {"Nenhum"}, MultipleOptions = false, Callback = function(O) SelectedTeleportNPC = O[1] end })

TabTeleport:CreateButton({ 
    Name = "🔄 Forçar Varredura Física (Clique ao mudar de Ilha)", 
    Callback = function() 
        ScanAllNPCs() 
        DropGivers:Refresh(NPC_Categories["Missões de Level (Givers)"], true)
        DropShops:Refresh(NPC_Categories["Lojas / Vendedores"], true)
        DropSpecial:Refresh(NPC_Categories["Quests Especiais / Outros"], true)
    end 
})

TabTeleport:CreateSection("Ações de Teleporte")

TabTeleport:CreateButton({
    Name = "⚡ Executar Teleporte Instantâneo para o NPC Selecionado",
    Callback = function()
        if SelectedTeleportNPC ~= "Nenhum" and SelectedTeleportNPC ~= "Nenhum nesta ilha" then
            local f = false
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == SelectedTeleportNPC and obj:FindFirstChild("HumanoidRootPart") then
                    SecureTeleport(obj.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3))
                    f = true
                    break
                end
            end
            if f then
                Rayfield:Notify({ Name = "Teleporte", Content = "Você chegou até: " .. SelectedTeleportNPC, Duration = 3 })
            else
                Rayfield:Notify({ Name = "Aviso", Content = "O NPC sumiu ou descarregou do mapa.", Duration = 3 })
            end
        else
            Rayfield:Notify({ Name = "Erro", Content = "Selecione um NPC válido em um dos menus acima primeiro.", Duration = 3 })
        end
    end
})

TabTeleport:CreateButton({
    Name = "👁️ Mostrar Distância / Localizar Alvo",
    Callback = function()
        if SelectedTeleportNPC ~= "Nenhum" and SelectedTeleportNPC ~= "Nenhum nesta ilha" then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == SelectedTeleportNPC and obj:FindFirstChild("HumanoidRootPart") then
                    local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - obj.HumanoidRootPart.Position).Magnitude)
                    Rayfield:Notify({ Name = "Rastreador", Content = SelectedTeleportNPC .. " está a " .. dist .. " metros de distância de você.", Duration = 5 })
                    break
                end
            end
        end
    end
})


-- --- ABA 3: AJUSTES DO PERSONAGEM & PERFORMANCE ---
TabPlayer:CreateSection("Modificações de Movimento")
TabPlayer:CreateToggle({ Name = "Ligar Modificador de Velocidade", CurrentValue = false, Callback = function(v) WalkSpeedEnabled = v end })
TabPlayer:CreateSlider({ Name = "Ajustar Velocidade", Range = {16, 250}, Increment = 1, CurrentValue = 16, Callback = function(v) WalkSpeedValue = v end })
TabPlayer:CreateToggle({ Name = "Ligar Geppo (Pulo Infinito)", CurrentValue = false, Callback = function(v) InfiniteJumpEnabled = v end })

TabPlayer:CreateSection("Otimizações de Tela")
TabPlayer:CreateToggle({ Name = "Ligar Modo Ultra Leve (FastMode Mobile)", CurrentValue = false, Callback = function(v) FastModeEnabled = v end })
TabPlayer:CreateToggle({ Name = "Ligar Trava Antitremer (No Camera Shake)", CurrentValue = true, Callback = function(v) NoCameraShake = v end })

-- Loop FastMode Otimizado
task.spawn(function()
    while true do
        task.wait(3)
        if FastModeEnabled then
            Lighting.GlobalShadows = false
            for _, obj in ipairs(workspace:GetDescendants()) do
                if not FastModeEnabled then break end
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then obj.Enabled = false
                elseif obj:IsA("MeshPart") or obj:IsA("Part") then obj.Material = Enum.Material.SmoothPlastic end
            end
        end
    end
end)

Rayfield:LoadConfiguration()
