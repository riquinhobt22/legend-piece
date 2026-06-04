local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- --- CONFIGURAÇÃO DE IDS ---
local LegendPieceID = 9645882365
local CurrentPlaceID = game.PlaceId
local MarketService = game:GetService("MarketplaceService")

local GameName = "Legend Piece"
local Success, Info = pcall(function()
    return MarketService:GetProductInfo(CurrentPlaceID)
end)
if Success and Info then GameName = Info.Name end

-- --- VARIÁVEIS DE CONTROLE (COM DROPDOWNS E SLIDERS) ---
local WalkSpeedEnabled = false
local WalkSpeedValue = 16
local JumpPowerEnabled = false
local JumpPowerValue = 50
local InfiniteJumpEnabled = false
local FlyEnabled = false
local FlySpeed = 50

-- Variáveis de Combate Avançadas
local AutoAttackEnabled = false
local SpamFruitSkillsEnabled = false
local SelectedWeapon = ""
local SkillSpamDelay = 0.1 -- Valor padrão de velocidade do Spam
local HitboxEnabled = false
local HitboxSize = 25

-- Variáveis de Performance (Mobile)
local FastModeEnabled = false
local NoCameraShake = true

-- Serviços Core
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- --- FUNÇÃO PARA LISTAR EQUIPAMENTOS ---
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

-- --- CRIAR INTERFACE RAYFIELD ---
local Window = Rayfield:CreateWindow({
   Name = "Legend Piece Hub | Advanced Combat",
   LoadingTitle = "Iniciando Motores de Ataque...",
   LoadingSubtitle = "Otimizado para Mobile por Gemini",
   Theme = "Default",
   ConfigurationSaving = { Enabled = false }
})

-- --- LOOPS CORE ---

-- Loop de Atributos Físicos
RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if WalkSpeedEnabled then hum.WalkSpeed = WalkSpeedValue end
        if JumpPowerEnabled then hum.JumpPower = JumpPowerValue hum.UseJumpPower = true end
    end
    
    if NoCameraShake then
        local cam = workspace.CurrentCamera
        if cam then
            for _, effect in ipairs(cam:GetChildren()) do
                if effect:IsA("ColorCorrectionEffect") or effect:IsA("BlurEffect") then effect:Destroy() end
            end
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(0, 0, 0)
            end
        end
    end
end)

-- Pulo Infinito
UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

-- Loop de Vôo (Fly)
local fv = Vector3.new(0,0,0)
RunService.Heartbeat:Connect(function()
    if FlyEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local cam = workspace.CurrentCamera
        local moveDir = Vector3.new(0,0,0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0,1,0) end
        
        fv = moveDir.Magnitude > 0 and moveDir.Unit * FlySpeed or Vector3.new(0,0,0)
        hrp.Velocity = fv
    end
end)

-- Loop para Travar Equipamento (Auto-Equip)
task.spawn(function()
    while task.wait(0.3) do
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

-- Loop Dedicado para Auto M1 (Ataque básico rápido)
task.spawn(function()
    while task.wait(0.05) do -- Ataque rápido para acumular cliques de espada/soco
        if AutoAttackEnabled and LocalPlayer.Character then
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then 
                tool:Activate() 
            end
        end
    end
end)

-- Loop Dedicado para o Spam Skill com Delay Controlável por Slider
task.spawn(function()
    while true do
        task.wait(SkillSpamDelay) -- Usa o delay dinâmico modificado pelo slider
        if SpamFruitSkillsEnabled and LocalPlayer.Character then
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                -- Varre a Fruta ou Espada equipada disparando os ataques especiais
                for _, remote in ipairs(tool:GetDescendants()) do
                    if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then 
                        remote:FireServer() 
                    end
                end
            end
        end
    end
end)

-- Loop de Performance Globais (FastMode e Hitbox)
task.spawn(function()
    while task.wait(0.2) do
        if FastModeEnabled then
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Explosion") then
                    if obj:IsA("Explosion") then obj.Visible = false else obj.Enabled = false end
                elseif obj:IsA("MeshPart") or obj:IsA("Part") or obj:IsA("CornerWedgePart") or obj:IsA("WedgePart") then
                    if obj.Material ~= Enum.Material.SmoothPlastic then obj.Material = Enum.Material.SmoothPlastic end
                elseif obj:IsA("Texture") or obj:IsA("Decal") then
                    obj:Destroy()
                end
            end
        end

        if HitboxEnabled then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Humanoid") and obj.Parent and obj.Parent ~= LocalPlayer.Character then
                    local hrp = obj.Parent:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                        hrp.Transparency = 0.8
                        hrp.BrickColor = BrickColor.new("Neon orange")
                        hrp.Material = Enum.Material.SmoothPlastic
                        hrp.CanCollide = false
                    end
                end
            end
        end
    end
end)


-- --- CONFIGURAÇÃO DAS ABAS ---
local TabPlayer = Window:CreateTab("Navegação/Status", 4483362458)
local TabCombat = Window:CreateTab("Combate & Farm", 4483362534)
local TabPerformance = Window:CreateTab("Performance Mobile", 4483364419)

-- --- ABA: MOVIMENTAÇÃO ---
TabPlayer:CreateSection("Atributos do Pirata")
TabPlayer:CreateToggle({ Name = "Modificar Velocidade", CurrentValue = false, Flag = "LP_WS_T", Callback = function(v) WalkSpeedEnabled = v end })
TabPlayer:CreateSlider({ Name = "Velocidade de Corrida", Range = {16, 250}, Increment = 1, CurrentValue = 16, Flag = "LP_WS_S", Callback = function(v) WalkSpeedValue = v end })
TabPlayer:CreateToggle({ Name = "Modificar Super Pulo", CurrentValue = false, Flag = "LP_JP_T", Callback = function(v) JumpPowerEnabled = v end })
TabPlayer:CreateSlider({ Name = "Força do Pulo", Range = {50, 300}, Increment = 1, CurrentValue = 50, Flag = "LP_JP_S", Callback = function(v) JumpPowerValue = v end })
TabPlayer:CreateToggle({ Name = "Geppo / Pulo Infinito", CurrentValue = false, Flag = "LP_InfJ_T", Callback = function(v) InfiniteJumpEnabled = v end })
TabPlayer:CreateSection("Navegação pelo Mapa (Fly)")
TabPlayer:CreateToggle({ Name = "Ativar Modo Vôo (Ir para Ilhas)", CurrentValue = false, Flag = "LP_Fly_T", Callback = function(v) FlyEnabled = v if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0) end end })
TabPlayer:CreateSlider({ Name = "Velocidade de Vôo", Range = {20, 300}, Increment = 5, CurrentValue = 70, Flag = "LP_FlySpd_S", Callback = function(v) FlySpeed = v end })

-- --- ABA: COMBATE & FARM ---
TabCombat:CreateSection("Seleção de Armas / Frutas")
local WeaponDropdown = TabCombat:CreateDropdown({ Name = "Selecione o Item de Ataque", Options = GetLegendWeapons(), CurrentOption = {"Selecione um item"}, MultipleOptions = false, Flag = "LP_Weapon", Callback = function(O) SelectedWeapon = O[1] end })
TabCombat:CreateButton({ Name = "🔄 Atualizar Mochila (Refresh)", Callback = function() WeaponDropdown:Refresh(GetLegendWeapons(), true) end })

TabCombat:CreateSection("Mecanismos de Ataque")
TabCombat:CreateToggle({ Name = "Auto Clicker M1 (Soco/Espada)", CurrentValue = false, Flag = "LP_M1_T", Callback = function(v) AutoAttackEnabled = v end })
TabCombat:CreateToggle({ Name = "Spam Skills (Soltar Golpes)", CurrentValue = false, Flag = "LP_Skills_T", Callback = function(v) SpamFruitSkillsEnabled = v end })

-- SLIDER DE VELOCIDADE DO SPAM SKILL (MENOR VALOR = MAIS RÁPIDO)
TabCombat:CreateSlider({
   Name = "Velocidade do Spam Skill",
   Range = {1, 10}, -- Representa décimos de segundo (0.1s a 1.0s)
   Increment = 1,
   CurrentValue = 1,
   Flag = "LP_SpamDelay",
   Callback = function(v)
       -- Converte o número inteiro em frações de segundos para o loop
       SkillSpamDelay = v / 10
   end,
})

TabCombat:CreateSection("Facilitadores de Alvos")
TabCombat:CreateToggle({ Name = "Expandir Hitbox dos Inimigos", CurrentValue = false, Flag = "LP_HBox_T", Callback = function(v) HitboxEnabled = v end })
TabCombat:CreateSlider({ Name = "Tamanho do Alvo", Range = {5, 60}, Increment = 1, CurrentValue = 25, Flag = "LP_HBox_S", Callback = function(v) HitboxSize = v end })

-- --- ABA: PERFORMANCE MOBILE ---
TabPerformance:CreateSection("Otimização de Hardware")
TabPerformance:CreateToggle({ Name = "🚀 ATIVAR ULTRA FASTMODE", CurrentValue = false, Flag = "LP_FastMode", Callback = function(v) FastModeEnabled = v end })
TabPerformance:CreateToggle({ Name = "Remover Tremores (No Camera Shake)", CurrentValue = true, Flag = "LP_Shake", Callback = function(v) NoCameraShake = v end })
TabPerformance:CreateSection("Ajustes Rápidos de Render")
TabPerformance:CreateButton({ Name = "Limpar Decals e Imagens Soltas", Callback = function() for _, obj in ipairs(workspace:GetDescendants()) do if obj:IsA("Decal") or obj:IsA("Texture") then obj:Destroy() end end end })

Rayfield:LoadConfiguration()
