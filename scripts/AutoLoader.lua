function GetClearCount(fileName)
    local extPos = 0
    local countPos = 0
    local p = 0
    
    repeat
        p = string.find(fileName, "%.", extPos + 1)
        if p then
            extPos = p
        end
    until not p
    
    repeat
        p = string.find(fileName, "_", countPos + 1)
        if p then
            countPos = p
        end
    until not p
    
    if extPos > 0 and countPos > 0 then
        local countStr = string.sub(fileName, countPos + 1, extPos - 1)
        local count = tonumber(countStr)
        return count or -1
    end
    
    return -1
end

function GetRealPlayerName(s)
    local lower = string.lower(s)
    local i = 0
    local j = 1
    
    repeat
        i = string.find(lower, "|c", i + 1)
        if i then
            j = i + 10
        end
    until not i
    
    i = string.find(lower, "|r", j + 1)
    if not i then
        i = string.len(s) - j + 1
    else
        i = i - j
    end
    
    local name = string.sub(s, j, j + i - 1)

    local startParen = string.find(name, "%(")
    local endParen = string.find(name, "%)")
    
    if startParen and endParen and startParen < endParen then
        return string.sub(name, startParen + 1, endParen - 1)
    end
    
    return name
end 

function GetSaveCode(directory, name)
    local fName = GetRealPlayerName(name)
    if not DirecotryExists(directory) or fName == "" then
        return ""
    end
    
    local highCount = -1
    local preload = ""
    
    local files = GetFiles(directory)
    for i = 1, #files do
        local fileName = files[i]
        local baseName = string.match(fileName, "([^\\/]+)$")
        local pattern = "^.*_"..fName.."_.*%.txt$"
        if string.find(baseName, pattern) then
            
            local count = GetClearCount(baseName)
            if highCount < count then
                preload = fileName
                highCount = count
            end
        end
    end
    
    if highCount > -1 and FileExists(preload) then
        local file = io.open(preload, "r")
        if file then
            local content = file:read("*all")
            file:close()
            
            local i = string.find(content, "-load")
            if i then
                local parts = {}
                for part in string.gmatch(string.sub(content, i), '([^"]+)') do
                    table.insert(parts, part)
                end
                return parts[1]
            end
        end
    end
    
    return ""
end

local loaded = false

Callbacks.Bind("Run", function()
    if War3.WorldInitialized then
        if not loaded and War3.IsChatInputEnabled() then
            local playerId = War3.GetLocalPlayerId()
            local playerName = War3.GetPlayerName(playerId)
            local saveCode = GetSaveCode(War3.GetDataDirectory()..'ORDR1', playerName)
            if saveCode ~= "" then
                War3.PostChat(saveCode)
            end
            loaded = true
        end
    else
        loaded = false
    end
end)