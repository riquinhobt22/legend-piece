-- Aguarda o jogo carregar completamente para evitar tabelas vazias
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- --- SERVIÇOS NATIVOS ---
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- --- VARIÁVEIS DE CONTROLE ---
_G.AutoFarm = false
_G.AutoQuest = false
_G.AutoM1 = false
_G.AutoSkills = false
_G.FruitMagnet = false
_G.BringMob = false

local SelectedEnemy = "Nenhum"
local SelectedWeapon = "Nenhum"

local EnemiesList = {}
local WeaponsList = {}

-- --- FUNÇÃO DE MAPEAMENTO DOS MOBS E ITENS ---
local function UpdateLists()
    EnemiesList = {}
    WeaponsList = {}
    
    -- No Legend Piece, os monstros ficam na pasta "NPCs" ou direto no Workspace com Humanoids ativos
    local folder = Workspace:FindFirstChild("NPCs") or Workspace:FindFirstChild("Monsters") or Workspace
    for _, v in ipairs(folder:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Name ~= LocalPlayer.Name then
            if not table.find(EnemiesList, v.Name) and not string.find(v.Name, "Quest") then
                table.insert(EnemiesList, v.Name)
            end
        end
    end
    
    -- Inventário / Itens equipáveis
    if LocalPlayer:FindFirstChild("Backpack") then
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if not table.find(WeaponsList, item.Name) then table.insert(WeaponsList, item.Name) end
        end
    end
    if LocalPlayer.Character then
        for _, item in ipairs(LocalPlayer.Character:GetChildren()) do
            if item:IsA("Tool") and not table.find(WeaponsList, item.Name) then table.insert(WeaponsList, item.Name) end
        end
    end
    
    if #EnemiesList == 0 then table.insert(EnemiesList, "Nenhum Monstro Encontrado") end
    if #WeaponsList == 0 then table.insert(WeaponsList, "Nenhuma Arma Encontrada") end
end

UpdateLists()

-- --- INTERFACE RAYFIELD ---
local Window = Rayfield:CreateWindow({
   Name = "KeyBrew | LEGEND PIECE PRO",
   LoadingTitle = "Injetando Motores de Farm...",
   LoadingSubtitle = "Estabilização de Remotes OK",
   Theme = "Default",
   ConfigurationSaving = { Enabled = false }
})

local TabFarm = Window:CreateTab("⚔️ Main Farm", nil)
local TabFruit = Window:CreateTab("🍎 Fruits", nil)

TabFarm:CreateSection("Configurações do Farm")
local DropMob = TabFarm:CreateDropdown({ Name = "Selecione o Monstro", Options = EnemiesList, CurrentOption = {"Selecione"}, Callback = function(O) SelectedEnemy = O[1] end })
local DropTool = TabFarm:CreateDropdown({ Name = "Selecione sua Arma", Options = WeaponsList, CurrentOption = {"Selecione"}, Callback = function(O) SelectedWeapon = O[1] end })

TabFarm:CreateButton({ 
    Name = "🔄 Atualizar Mobs e Inventário", 
    Callback = function() 
        UpdateLists() 
        DropMob:Refresh(EnemiesList, true) 
        DropTool:Refresh(WeaponsList, true) 
    end 
})

TabFarm:CreateSection("Controles de Automação")
TabFarm:CreateToggle({ Name = "Auto Farm (Teleporte Seguro)", CurrentValue = false, Callback = function(v) _G.AutoFarm = v end })
TabFarm:CreateToggle({ Name = "Puxar Monstros (Bring Mob)", CurrentValue = false, Callback = function(v) _G.BringMob = v end })
TabFarm:CreateToggle({ Name = "Auto Missão (Quest)", CurrentValue = false, Callback = function(v) _G.AutoQuest = v end })
TabFarm:CreateToggle({ Name = "Auto Clique M1", CurrentValue = false, Callback = function(v) _G.AutoM1 = v end })
TabFarm:CreateToggle({ Name = "Auto Skills (Z, X, C, V)", CurrentValue = false, Callback = function(v) _G.AutoSkills = v end })

TabFruit:CreateSection("Coletor de Frutas")
TabFruit:CreateToggle({ Name = "Magnet Fruit", CurrentValue = false, Callback = function(v) _G.FruitMagnet = v end })


-- ================================================================
-- --- LOOPS DE EXECUÇÃO ADAPTADOS PARA A ENGINE DO JOGO ---
-- ================================================================

-- Sistema Anti-Void (Flutua caso o mob morra para o boneco não cair no limbo)
local bV = Instance.new("BodyVelocity")
bV.Velocity = Vector3.new(0, 0, 0)
bV.MaxForce = Vector3.new(0, 0, 0)

RunService.Heartbeat:Connect(function()
    if _G.AutoFarm and SelectedEnemy ~= "Nenhum" and SelectedEnemy ~= "Nenhum Monstro Encontrado" then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            
            bV.Parent = LocalPlayer.Character.HumanoidRootPart
            local folder = Workspace:FindFirstChild("NPCs") or Workspace:FindFirstChild("Monsters") or Workspace
            local targetMob = nil
            
            for _, mob in ipairs(folder:GetChildren()) do
                if mob.Name == SelectedEnemy and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                    targetMob = mob
                    break
                end
            end
            
            if targetMob then
                bV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                
                -- Desativa colisão do player para evitar detecção e travamentos
                for _, part in ipairs(LocalPlayer.Character:GetChildren()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
                
                -- Fica posicionado em cima da cabeça do monstro olhando para baixo
                LocalPlayer.Character.HumanoidRootPart.CFrame = targetMob.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                
                -- Bring Mob: Move os monstros clones próximos para a mesma coordenada de ataque
                if _G.BringMob then
                    for _, otherMob in ipairs(folder:GetChildren()) do
                        if otherMob.Name == SelectedEnemy and otherMob:FindFirstChild("HumanoidRootPart") and otherMob ~= targetMob then
                            if (otherMob.HumanoidRootPart.Position - targetMob.HumanoidRootPart.Position).Magnitude < 200 then
                                otherMob.HumanoidRootPart.CanCollide = false
                                otherMob.HumanoidRootPart.CFrame = targetMob.HumanoidRootPart.CFrame
                            end
                        end
                    end
                end
            else
                -- Caso o mob tenha morrido, segura o jogador no mesmo ponto flutuando até o respawn
                bV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bV.Velocity = Vector3.new(0, 0, 0)
            end
        end
    else
        bV.MaxForce = Vector3.new(0, 0, 0)
        bV.Parent = nil
    end
end)

-- Auto Equipar Arma de forma nativa e limpa
task.spawn(function()
    while task.wait(0.4) do
        if _G.AutoFarm and SelectedWeapon ~= "Nenhum" and SelectedWeapon ~= "Nenhuma Arma Encontrada" then
            local character = LocalPlayer.Character
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            if character and backpack and not character:FindFirstChild(SelectedWeapon) then
                local tool = backpack:FindFirstChild(SelectedWeapon)
                if tool then
                    character.Humanoid:EquipTool(tool)
                end
            end
        end
    end
end)

-- Auto M1 (Ataque Básico integrado aos Remotes nativos do Communicate)
task.spawn(function()
    while task.wait(0.05) do
        if _G.AutoM1 and LocalPlayer.Character then
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate() -- Ativação física do clique da ferramenta
                
                -- Disparo de suporte na rede local de combate do jogo
                local communicate = ReplicatedStorage:FindFirstChild("Communicate")
                if communicate then
                    local attack = communicate:FindFirstChild("Inflict") or communicate:FindFirstChild("Hit") or communicate:FindFirstChild("Attack")
                    if attack then
                        attack:InvokeServer(tool)
                    end
                end
            end
        end
    end
end)

-- Auto Skills (Dispara as habilidades principais enviando os inputs direto para o Handler)
task.spawn(function()
    local skills = {"Z", "X", "C", "V"}
    while task.wait(0.4) do
        if _G.AutoSkills and _G.AutoFarm and LocalPlayer.Character then
            local communicate = ReplicatedStorage:FindFirstChild("Communicate")
            if communicate then
                local skillRemote = communicate:FindFirstChild("UseSkill") or communicate:FindFirstChild("Skill") or communicate:FindFirstChild("ActivateSkill")
                if skillRemote then
                    for _, key in ipairs(skills) do
                        skillRemote:InvokeServer(key)
                    end
                end
            end
        end
    end
end)

-- Auto Quest (Interage com os Remotes de contratos e missões)
task.spawn(function()
    while task.wait(2.5) do
        if _G.AutoQuest and SelectedEnemy ~= "Nenhum" and SelectedEnemy ~= "Nenhum Monstro Encontrado" then
            local communicate = ReplicatedStorage:FindFirstChild("Communicate")
            if communicate then
                -- O Legend Piece utiliza Invoke/Fire para validação de missões dinâmicas
                local questRemote = communicate:FindFirstChild("Quest") or communicate:FindFirstChild("AcceptQuest")
                if questRemote then
                    if questRemote:IsA("RemoteFunction") then
                        questRemote:InvokeServer("AcceptQuest", SelectedEnemy)
                    elseif questRemote:IsA("RemoteEvent") then
                        questRemote:FireServer("AcceptQuest", SelectedEnemy)
                    end
                end
            end
        end
    end
end)

-- Coletor Automático de Frutas (Magnet / Auto Equip)
task.spawn(function()
    while task.wait(1) do
        if _G.FruitMagnet and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            for _, obj in ipairs(Workspace:GetChildren()) do
                -- Verifica ferramentas largadas ou modelos contendo nomes de frutas geradas no mapa
                if (obj:IsA("Tool") or obj:IsA("Model")) and (string.find(string.lower(obj.Name), "fruit") or string.find(string.lower(obj.Name), "fruta") or obj:FindFirstChild("Fruit")) then
                    local part = obj:FindFirstChild("Handle") or obj:FindFirstChildOfClass("BasePart")
                    if part then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = part.CFrame
                        task.wait(0.2)
                        
                        -- Se for uma tool no chão, força o humanoid a coletar
                        if obj:IsA("Tool") then
                            LocalPlayer.Character.Humanoid:EquipTool(obj)
                        end
                        break
                    end
                end
            end
        end
    end
end)

Rayfield:LoadConfiguration()
