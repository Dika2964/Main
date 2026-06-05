--[[
    ROBLOX DEEP SCANNER v2.0 - EXECUTOR OPTIMIZED
    Dioptimalkan untuk dijalankan di Roblox Executor (Synapse X, Krnl, Fluxus, dll)
    
    FITUR:
    - Scan script dengan keyword tertentu
    - Compatible dengan semua executor modern
    - Clipboard support (opsional)
    - Better error handling
    
    USAGE:
    local scanner = DeepScanner:new()
    local results = scanner:scan("macro")
    scanner:print(results)
]]

local DeepScanner = {}
DeepScanner.__index = DeepScanner

function DeepScanner:new()
    return setmetatable({
        results = {},
        totalFound = 0,
        startTime = 0
    }, DeepScanner)
end

-- Get full path dari instance
function DeepScanner:getPath(instance)
    local path = instance.Name
    local parent = instance.Parent
    
    while parent and parent ~= game do
        path = parent.Name .. "/" .. path
        parent = parent.Parent
    end
    
    return path
end

-- Check apakah instance adalah script
function DeepScanner:isScript(instance)
    return instance:IsA("LocalScript") or 
           instance:IsA("Script") or 
           instance:IsA("ModuleScript")
end

-- Get script source dengan safe
function DeepScanner:getSource(script)
    local ok, source = pcall(function()
        return script.Source
    end)
    return ok and source or nil
end

-- Case-insensitive search
function DeepScanner:hasKeyword(text, keyword)
    if not text then return false end
    return string.find(string.lower(text), string.lower(keyword), 1, true) ~= nil
end

-- Count keyword occurrences
function DeepScanner:countMatches(text, keyword)
    local count = 0
    local pos = 1
    local lower = string.lower(text)
    local lowerKw = string.lower(keyword)
    
    while true do
        pos = string.find(lower, lowerKw, pos, true)
        if not pos then break end
        count = count + 1
        pos = pos + 1
    end
    
    return count
end

-- Main scan function
function DeepScanner:scan(keyword, location)
    if not keyword or keyword == "" then
        warn("⚠️ Keyword tidak boleh kosong!")
        return {}
    end
    
    location = location or game
    self.results = {}
    self.totalFound = 0
    self.startTime = tick()
    
    print("🔍 [DeepScanner] Memulai scan dengan keyword: '" .. keyword .. "'")
    
    local function recursiveScan(parent, depth)
        depth = depth or 0
        if depth > 50 then return end -- Prevent stack overflow
        
        local children = parent:GetChildren()
        for _, child in ipairs(children) do
            if self:isScript(child) then
                local source = self:getSource(child)
                
                if source and self:hasKeyword(source, keyword) then
                    local path = self:getPath(child)
                    local matches = self:countMatches(source, keyword)
                    
                    table.insert(self.results, {
                        name = child.Name,
                        path = path,
                        fullPath = "game." .. path,
                        type = child.ClassName,
                        matches = matches,
                        instance = child,
                        source = source
                    })
                    
                    self.totalFound = self.totalFound + 1
                    print("  ✓ Ditemukan: " .. path .. " (" .. matches .. "x)")
                end
            end
            
            recursiveScan(child, depth + 1)
        end
    end
    
    recursiveScan(location)
    
    local elapsed = math.floor((tick() - self.startTime) * 1000)
    print("✅ Scan selesai! Total: " .. self.totalFound .. " script (" .. elapsed .. "ms)\n")
    
    return self.results
end

-- Display results dengan format bagus
function DeepScanner:print(results)
    print(string.rep("═", 90))
    print("📋 HASIL SCANNING DEEP SCANNER")
    print(string.rep("═", 90))
    
    if #results == 0 then
        print("❌ Tidak ada script yang ditemukan")
        print(string.rep("═", 90) .. "\n")
        return
    end
    
    for i, result in ipairs(results) do
        print("\n📜 SCRIPT #" .. i)
        print("  Nama     : " .. result.name)
        print("  Tipe     : " .. result.type)
        print("  Path     : " .. result.path)
        print("  Match    : " .. result.matches .. "x")
        print("  Full     : " .. result.fullPath)
    end
    
    print("\n" .. string.rep("═", 90))
    print("📊 Total: " .. #results .. " script ditemukan")
    print(string.rep("═", 90) .. "\n")
end

-- Print hanya path
function DeepScanner:printPaths(results)
    print("\n📍 SCRIPT PATHS:\n")
    for i, result in ipairs(results) do
        print(i .. ". game." .. result.path)
    end
    print()
end

-- Get source dari result tertentu
function DeepScanner:getResultSource(index)
    if self.results[index] then
        return self.results[index].source
    end
    return nil
end

-- Filter by type
function DeepScanner:filterByType(type)
    local filtered = {}
    for _, result in ipairs(self.results) do
        if result.type == type then
            table.insert(filtered, result)
        end
    end
    return filtered
end

-- Highlight keyword dalam source
function DeepScanner:showKeywordLines(index, keyword)
    local result = self.results[index]
    if not result then return nil end
    
    local lines = {}
    local lineNum = 0
    
    for line in string.gmatch(result.source, "[^\n]+") do
        lineNum = lineNum + 1
        if string.find(string.lower(line), string.lower(keyword), 1, true) then
            table.insert(lines, {num = lineNum, text = line})
        end
    end
    
    return lines
end

-- Print keyword lines
function DeepScanner:printKeywordLines(index, keyword)
    local lines = self:showKeywordLines(index, keyword)
    if not lines then
        print("⚠️ Index tidak valid")
        return
    end
    
    print("\n📄 KEYWORD LINES (Result #" .. index .. "):\n")
    for _, line in ipairs(lines) do
        print("  [Line " .. line.num .. "] " .. line.text)
    end
    print()
end

-- Copy to clipboard (safe)
function DeepScanner:copyPath(index)
    if not self.results[index] then
        warn("⚠️ Index tidak valid!")
        return false
    end
    
    local path = self.results[index].fullPath
    
    -- Try setclipboard (works in modern executors)
    if setclipboard then
        pcall(function()
            setclipboard(path)
            print("✅ Path disalin: " .. path)
        end)
        return true
    else
        print("⚠️ setclipboard tidak tersedia di executor ini")
        print("📝 Path: " .. path)
        return false
    end
end

-- Export hasil sebagai string format
function DeepScanner:export()
    local output = {}
    for i, result in ipairs(self.results) do
        table.insert(output, {
            id = i,
            name = result.name,
            path = result.path,
            fullPath = result.fullPath,
            type = result.type,
            matches = result.matches
        })
    end
    return output
end

-- Return module
return DeepScanner

--[[
════════════════════════════════════════════════════════════════════════
                         CONTOH PENGGUNAAN
════════════════════════════════════════════════════════════════════════

local DeepScanner = require(LINK_KE_SCRIPT_INI)

-- 1️⃣ BASIC USAGE
local scanner = DeepScanner:new()
local results = scanner:scan("macro")
scanner:print(results)

-- 2️⃣ SCAN DENGAN LOKASI SPESIFIK
local workspaceResults = scanner:scan("teleport", workspace)
scanner:printPaths(workspaceResults)

-- 3️⃣ FILTER HANYA LOCAL SCRIPT
local localScripts = scanner:filterByType("LocalScript")
print("LocalScript ditemukan: " .. #localScripts)

-- 4️⃣ LIHAT KEYWORD DALAM SOURCE
scanner:printKeywordLines(1, "macro")

-- 5️⃣ COPY PATH KE CLIPBOARD
scanner:copyPath(1)

-- 6️⃣ SCAN MULTIPLE KEYWORDS
local keywords = {"macro", "teleport", "autofarm", "speed"}
for _, kw in ipairs(keywords) do
    print("\n[SCANNING] " .. kw)
    local res = scanner:scan(kw)
    print("Ditemukan: " .. #res)
end

-- 7️⃣ SAVE HASIL
local hasil = scanner:export()
for _, item in ipairs(hasil) do
    print(item.id .. ". " .. item.path .. " (" .. item.matches .. "x)")
end

════════════════════════════════════════════════════════════════════════
]]
