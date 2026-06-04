local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- --- CONFIGURAÇÃO DE SERVIÇOS ROBLOX ---
local LocalPlayer = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")

-- --- CONTROLADORES MASTER ---
local WalkSpeedEnabled, WalkSpeedValue = false, 16
local InfiniteJumpEnabled = false
local AutoFarmEnabled = false
local AutoQuestEnabled = false
local AutoAttackEnabled = false
local AutoSkillEnabled = false

local SelectedEnemy = "Nenhum"
local SelectedWeapon = ""
local SelectedTeleportNPC = "Nenhum"

-- Tabelas de armazenamento do Scanner
local NPC_Categories = { ["Combate / Bosses"] = {}, ["Missões (Givers)"] = {}, ["Lojas / Vendedores"] = {}, ["Outros NPCs"] = {} }
local MapFruits = {}

-- --- FUNÇÃO DE TELEPORTE SEGURO ---
local function SecureTeleport(targetCFrame)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame
    end
end

-- --- PARTE 1: O CÉREBRO - VARREDURA BRUTA DE INFRAESTRUTURA ---
local function DeepScanGame()
    for cat, _ in pairs(NPC_Categories) do NPC_Categories[cat] = {} end
    
    -- Varre absolutamente tudo no mapa físico
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") and obj.Name ~= LocalPlayer.Name then
            local nameLow = string.lower(obj.Name)
            local hum = obj:FindFirstChildOfClass("Humanoid")
            
            if string.find(nameLow, "dealer") or string.find(nameLow, "seller") or string.find(nameLow, "shop") or string.find(nameLow, "vendedor") or string.find(nameLow, "gacha") or string.find(nameLow, "boat") then
                if not table.find(NPC_Categories["Lojas / Vendedores"], obj.Name) then table.insert(NPC_Categories["Lojas / Vendedores"], obj.Name) end
            elseif string.find(nameLow, "quest") or string.find(nameLow, "giver") or string.find(nameLow, "missao") then
                if not table.find(NPC_Categories["Missões (Givers)"], obj.Name) then table.insert(NPC_Categories["Missões (Givers)"], obj.Name) end
            elseif hum and hum.MaxHealth > 0 then
                if not table.find(NPC_Categories["Combate / Bosses"], obj.Name) then table.insert(NPC_Categories["Combate / Bosses"], obj.Name) end
            else
                if not table.find(NPC_Categories["Outros NPCs"], obj.Name) then table.insert(NPC_Categories["Outros NPCs"], obj.Name) end
            end
        end
    end
    for cat, lista in pairs(NPC_Categories) do if #lista == 0 then table.insert(NPC_Categories[cat], "Nenhum Detectado") end end
end

-- Captura o inventário
local function GetWeapons()
    local items = {}
    if LocalPlayer:FindFirstChild("Backpack") then for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do table.insert(items, t.Name) end end
    if LocalPlayer.Character then for _, t in ipairs(LocalPlayer.Character:GetChildren()) do if t:IsA("Tool") and not table.find(items, t.Name) then table.insert(items, t.Name) end end end
    if #items == 0 then table.insert(items, "Nenhum item") end
    return items
end

-- --- CRIAR INTERFACE RAYFIELD ---
local Window = Rayfield:CreateWindow({
   Name = "Legend Piece Hub | V6 HACKER ENGINE",
   LoadingTitle = "Iniciando Descompilador de Tráfego...",
   LoadingSubtitle = "Modo Analisador Ativado",
   Theme = "Default",
   ConfigurationSaving = { Enabled = false }
})

DeepScanGame()

-- --- PARTE 2: A FERRAMENTA DE EXTRAÇÃO (DUMPER DE COMANDOS) ---
-- Esta função vai caçar os Remotes reais que o jogo usa para skills e quests
local function DumpGameRemotes()
    print("--- [INÍCIO DO DUMP DE COMANDOS DO JOGO] ---")
    local foundCount = 0
    
    -- Busca no ReplicatedStorage (onde ficam os comandos centrais do jogo)
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            print(string.format("Comando Central Encontrado: Nome: '%s' | Caminho: %s", v.Name, v:GetFullName()))
            foundCount = foundCount + 1
        end
    end
    
    -- Busca na ferramenta que você está segurando na mão
    if LocalPlayer.Character then
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            print("--- [Analisando sua Fruta/Arma Equipada: " .. tool.Name .. "] ---")
            for _, sub in ipairs(tool:GetDescendants()) do
                if sub:IsA("RemoteEvent") or sub:IsA("RemoteFunction") then
                    print(string.format("Gatilho de Skill Detectado: Nome: '%s' | Tipo: %s", sub.Name, sub.ClassName))
                    foundCount = foundCount + 1
                end
            end
        end
    end
    print("--- [FIM DO DUMP - TOTAL DE " .. foundCount .. " COMANDOS EXTRAÍDOS] ---")
    
    Rayfield:Notify({
        Name = "Dump Concluído!",
        Content = "Abra o Log do Roblox para ver todos os comandos reais do jogo.",
        Duration = 5,
    })
end

-- --- LOOPS DE NATIVOS ---
RunService.RenderStepped:Connect(function()
    if WalkSpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = WalkSpeedValue
    end
end)

-- Auto Clicker M1 Forçado
task.spawn(function()
    while task.wait(0.1) do
        if AutoAttackEnabled and LocalPlayer.Character then
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then 
                tool:Activate() 
                -- Força o disparo em qualquer remote dentro da arma
                for _, r in ipairs(tool:GetDescendants()) do
                    if r:IsA("RemoteEvent") then r:FireServer() r:FireServer("Attack") end
                end
            end
        end
    end
end)

-- Auto Skill Forçado
task.spawn(function()
    while task.wait(0.5) do
        if AutoSkillEnabled and LocalPlayer.Character then
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                local keys = {"Z", "X", "C", "V", "Skill1", "Skill2"}
                for _, r in ipairs(tool:GetDescendants()) do
                    if r:IsA("RemoteEvent") then
                        for _, k in ipairs(keys) do pcall(function() r:FireServer(k) r:FireServer("Skill", k) end) end
                    end
                end
            end
        end
    end
end)


-- --- CONSTRUÇÃO DAS ABAS ---
local TabFarm = Window:CreateTab("Auto Farm", 4483362534)
local TabTeleport = Window:CreateTab("Auto Teleport NPC", 4370345144)
local TabDumper = Window:CreateTab("🛠️ ANALISAR JOGO (F9)", 4483364419) -- NOVA ABA SCOUTER
local TabPlayer = Window:CreateTab("Config", 4483362458)

-- --- ABA FARM ---
TabFarm:CreateSection("Alvos")
local EnemyDropdown = TabFarm:CreateDropdown({ Name = "Monstro/Boss", Options = NPC_Categories["Combate / Bosses"], CurrentOption = {"Selecione"}, MultipleOptions = false, Callback = function(O) SelectedEnemy = O[1] end })
local WeaponDropdown = TabFarm:CreateDropdown({ Name = "Sua Arma/Fruta", Options = GetWeapons(), CurrentOption = {"Selecione"}, MultipleOptions = false, Callback = function(O) SelectedWeapon = O[1] end })
TabFarm:CreateButton({ Name = "🔄 Atualizar Listas", Callback = function() DeepScanGame() EnemyDropdown:Refresh(NPC_Categories["Combate / Bosses"], true) WeaponDropdown:Refresh(GetWeapons(), true) end })

TabFarm:CreateSection("Controles (ON/OFF)")
TabFarm:CreateToggle({ Name = "Auto Clicker M1", CurrentValue = false, Callback = function(v) AutoAttackEnabled = v end })
TabFarm:CreateToggle({ Name = "Auto Skill (Fruta/Arma)", CurrentValue = false, Callback = function(v) AutoSkillEnabled = v end })

-- --- ABA TELEPORT ---
TabTeleport:CreateSection("Selecione para onde ir")
local DropGivers = TabTeleport:CreateDropdown({ Name = "Pegar Missão (Level)", Options = NPC_Categories["Missões (Givers)"], CurrentOption = {"Nenhum"}, MultipleOptions = false, Callback = function(O) SelectedTeleportNPC = O[1] end })
local DropShops = TabTeleport:CreateDropdown({ Name = "Lojas / Vendedores / Gacha", Options = NPC_Categories["Lojas / Vendedores"], CurrentOption = {"Nenhum"}, MultipleOptions = false, Callback = function(O) SelectedTeleportNPC = O[1] end })
TabTeleport:CreateButton({ Name = "⚡ Teleportar para o NPC Selecionado", Callback = function()
    if SelectedTeleportNPC ~= "Nenhum" then
        for _, o in ipairs(workspace:GetDescendants()) do
            if o:IsA("Model") and o.Name == SelectedTeleportNPC and o:FindFirstChild("HumanoidRootPart") then SecureTeleport(o.HumanoidRootPart.CFrame) break end
        end
    end
end })

-- --- NOVA ABA: O DESCOMPILADOR DO JOGO ---
TabDumper:CreateSection("🔬 Engenharia Reversa (Descobrir Segredos do Jogo)")
TabDumper:CreateParagraph({Title = "Como funciona?", Content = "Como o jogo roda em códigos ocultos, use os botões abaixo para forçar o jogo a revelar o nome exato dos comandos dele. Isso vai gerar uma lista perfeita para nós criarmos o bypass definitivo."})

TabDumper:CreateButton({
    Name = "📥 MAPEAR E EXTRAIR TODOS OS COMANDOS (DUMP)",
    Callback = function()
        DumpGameRemotes()
    end
})

TabDumper:CreateParagraph({Title = "⚠️ IMPORTANTE PARA VER O RESULTADO:", Content = "Após clicar no botão acima, você PRECISA abrir o console do Roblox para ver a mágica. No celular, digite exatamente '/console' no chat do jogo para abrir a tela preta com os logs!"})


-- --- ABA CONFIG ---
TabPlayer:CreateToggle({ Name = "Modificar Velocidade", CurrentValue = false, Callback = function(v) WalkSpeedEnabled = v end })
TabPlayer:CreateSlider({ Name = "Velocidade", Range = {16, 200}, Increment = 1, CurrentValue = 16, Callback = function(v) WalkSpeedValue = v end })

Rayfield:LoadConfiguration()
