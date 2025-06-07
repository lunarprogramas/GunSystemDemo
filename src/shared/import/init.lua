local RunService = game:GetService("RunService")
local import = {}

local Server = {
    Modules = {},
    Services = {}
}
local Client = {
    Controllers = {},
    Modules = {}
}
local Shared = {}

local function setAliases(modules, type, isShared: boolean?)
    if RunService:IsServer() and not isShared then
        Server[type] = modules
    elseif RunService:IsClient() and not isShared then
        Client[type] = modules
    else
        Shared = modules
    end
end

return function (directory, modules: Object?, isShared: boolean?)
    if string.find(directory, "set") then
        local split = string.split(directory, ":")
        return setAliases(modules, split[2], isShared)
    end

    local split = string.split(directory, "/")

    if split[1] == "Server" then
        for _, module in Server[split[2]] do
            if module.Name == split[3] then
                return require(module)
            end
        end
    elseif split[1] == "Client" then
        for _, module in Client[split[2]] do
            if module.Name == split[3] then
                return require(module)
            end
        end
    elseif split[1] == "Shared" then
        for _, module in Shared do
            if module.Name == split[2] then
                return require(module)
            end
        end
    end
end