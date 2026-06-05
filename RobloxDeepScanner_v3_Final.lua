local Scanner = {}
Scanner.__index = Scanner

function Scanner:new()
    return setmetatable({
        results = {},
        scanning = false,
        foundCount = 0
    }, Scanner)
end

function Scanner:getInstancePath(instance)
    local path = {}
    local current = instance
    while current and current ~= game do
        table.insert(path, 1, current.Name)
        current = current.Parent
    end
    return table.concat(path, "/")
end

function Scanner:getScriptContent(script)
    local ok, source = pcall(function()
        return script.Source or ""
    end)
    if not ok then
        return nil
    end
    return source
end

function Scanner:findKeywordInSource(source, keyword)
    if not source then return 0 end
    local lower = string.lower(source)
    local lowerKw = string.lower(keyword)
    local count = 0
    local pos = 1
    
    while pos do
        pos = string.find(lower, lowerKw, pos, true)
        if pos then
            count = count + 1
            pos = pos + 1
        end
    end
    return count
end

function Scanner:scanRecursive(parent, keyword, depth, maxDepth)
    if depth > maxDepth then return end
    
    local ok, children = pcall(function()
        return parent:GetChildren()
    end)
    
    if not ok then return end
    
    for _, child in ipairs(children) do
        if child:IsA("LocalScript") or child:IsA("Script") or child:IsA("ModuleScript") then
            local source = self:getScriptContent(child)
            local matches = self:findKeywordInSource(source, keyword)
            
            if matches > 0 then
                local path = self:getInstancePath(child)
                table.insert(self.results, {
                    name = child.Name,
                    type = child.ClassName,
                    path = path,
                    fullPath = "game." .. path,
                    matches = matches,
                    instance = child
                })
                self.foundCount = self.foundCount + 1
                print("[FOUND] " .. path .. " (" .. matches .. "x match)")
            end
        end
        
        self:scanRecursive(child, keyword, depth + 1, maxDepth)
    end
end

function Scanner:scan(keyword, location)
    if not keyword or keyword == "" then
        print("ERROR: Keyword kosong!")
        return {}
    end
    
    self.results = {}
    self.foundCount = 0
    self.scanning = true
    
    location = location or game
    
    print("=========================================")
    print("[SCAN START] Keyword: " .. keyword)
    print("=========================================")
    
    self:scanRecursive(location, keyword, 0, 100)
    
    print("=========================================")
    print("[SCAN COMPLETE] Ditemukan: " .. self.foundCount .. " script")
    print("=========================================")
    
    self.scanning = false
    return self.results
end

function Scanner:scanPlayerGui()
    local player = game.Players.LocalPlayer
    if not player then
        print("ERROR: Player tidak ditemukan!")
        return {}
    end
    
    return self:scan(self.lastKeyword or "macro", player:WaitForChild("PlayerGui"))
end

function Scanner:scanWorkspace()
    return self:scan(self.lastKeyword or "macro", workspace)
end

function Scanner:scanAll(keyword)
    self.lastKeyword = keyword
    local results = {}
    
    print("Scanning PlayerGui...")
    local playerGui = self:scan(keyword, game.Players.LocalPlayer:WaitForChild("PlayerGui"))
    for _, result in ipairs(playerGui) do
        table.insert(results, result)
    end
    
    print("Scanning Workspace...")
    local workspaceScripts = self:scan(keyword, workspace)
    for _, result in ipairs(workspaceScripts) do
        table.insert(results, result)
    end
    
    print("Scanning ServerScriptService...")
    local ok, serverScripts = pcall(function()
        return self:scan(keyword, game:GetService("ServerScriptService"))
    end)
    if ok then
        for _, result in ipairs(serverScripts) do
            table.insert(results, result)
        end
    end
    
    return results
end

function Scanner:print(results)
    if #results == 0 then
        print("Tidak ada script yang ditemukan!")
        return
    end
    
    print("")
    print("=====================================")
    print("HASIL SCAN: " .. #results .. " SCRIPT")
    print("=====================================")
    
    for i, result in ipairs(results) do
        print("")
        print("[" .. i .. "] " .. result.name)
        print("    Type: " .. result.type)
        print("    Path: " .. result.path)
        print("    Match: " .. result.matches .. "x")
        print("    Full: " .. result.fullPath)
    end
    
    print("")
    print("=====================================")
end

function Scanner:printPaths(results)
    print("")
    for i, result in ipairs(results) do
        print(i .. ". " .. result.fullPath)
    end
    print("")
end

function Scanner:copyPath(index)
    if not self.results[index] then
        print("ERROR: Index invalid!")
        return false
    end
    
    local path = self.results[index].fullPath
    
    if setclipboard then
        pcall(function()
            setclipboard(path)
        end)
        print("COPIED: " .. path)
        return true
    else
        print("Path: " .. path)
        return false
    end
end

function Scanner:filterByType(scriptType)
    local filtered = {}
    for _, result in ipairs(self.results) do
        if result.type == scriptType then
            table.insert(filtered, result)
        end
    end
    return filtered
end

function Scanner:getScriptSource(index)
    if not self.results[index] then
        return nil
    end
    return self:getScriptContent(self.results[index].instance)
end

function Scanner:getScriptLines(index, keyword)
    local source = self:getScriptSource(index)
    if not source then return {} end
    
    local lines = {}
    local lineNum = 0
    
    for line in string.gmatch(source, "[^\n]+") do
        lineNum = lineNum + 1
        if string.find(string.lower(line), string.lower(keyword), 1, true) then
            table.insert(lines, {num = lineNum, text = line})
        end
    end
    
    return lines
end

function Scanner:printScriptLines(index, keyword)
    local lines = self:getScriptLines(index, keyword)
    if #lines == 0 then
        print("Tidak ada line yang match")
        return
    end
    
    print("")
    print("=== KEYWORD LINES (Script #" .. index .. ") ===")
    for _, line in ipairs(lines) do
        print("[Line " .. line.num .. "] " .. line.text)
    end
    print("")
end

function Scanner:exportResults()
    local exported = {}
    for i, result in ipairs(self.results) do
        table.insert(exported, {
            id = i,
            name = result.name,
            type = result.type,
            path = result.path,
            fullPath = result.fullPath,
            matches = result.matches
        })
    end
    return exported
end

return Scanner
