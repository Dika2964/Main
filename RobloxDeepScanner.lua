--[[
    ROBLOX DEEP SCANNER v1.0
    Fungsi: Mencari script dalam game berdasarkan keyword tertentu
    Mengembalikan path script yang ditemukan
    
    Contoh penggunaan:
    local scanner = RobloxDeepScanner:new()
    local results = scanner:scanForKeyword("macro")
    scanner:displayResults(results)
]]

local RobloxDeepScanner = {}
RobloxDeepScanner.__index = RobloxDeepScanner

-- Constructor
function RobloxDeepScanner:new()
    local self = setmetatable({}, RobloxDeepScanner)
    self.results = {}
    self.keywordFound = 0
    return self
end

-- Fungsi untuk mendapatkan path penuh instance
function RobloxDeepScanner:getFullPath(instance)
    local path = instance.Name
    local parent = instance.Parent
    
    while parent ~= nil and parent ~= game do
        path = parent.Name .. "/" .. path
        parent = parent.Parent
    end
    
    return path
end

-- Fungsi untuk mengecek apakah string adalah script
function RobloxDeepScanner:isScript(instance)
    return instance:IsA("LocalScript") or 
           instance:IsA("Script") or 
           instance:IsA("ModuleScript")
end

-- Fungsi untuk membaca source code script dengan aman
function RobloxDeepScanner:getScriptSource(script)
    local success, source = pcall(function()
        return script.Source
    end)
    
    if success then
        return source or ""
    else
        return nil
    end
end

-- Fungsi untuk memeriksa apakah keyword ada dalam script
function RobloxDeepScanner:checkKeyword(source, keyword)
    if not source then return false end
    
    -- Case-insensitive search
    local lowerSource = string.lower(source)
    local lowerKeyword = string.lower(keyword)
    
    return string.find(lowerSource, lowerKeyword, 1, true) ~= nil
end

-- Fungsi utama: scan untuk keyword
function RobloxDeepScanner:scanForKeyword(keyword, startLocation)
    if not keyword or keyword == "" then
        warn("[Deep Scanner] Keyword tidak boleh kosong!")
        return {}
    end
    
    startLocation = startLocation or game
    self.results = {}
    self.keywordFound = 0
    
    print("[Deep Scanner] Mulai scanning dengan keyword: " .. keyword)
    print("[Deep Scanner] Lokasi awal: " .. startLocation:GetFullName())
    
    -- Recursive function untuk scan semua instances
    local function recursiveScan(parent)
        for _, instance in pairs(parent:GetChildren()) do
            -- Cek jika instance adalah script
            if self:isScript(instance) then
                local source = self:getScriptSource(instance)
                
                if source and self:checkKeyword(source, keyword) then
                    local fullPath = self:getFullPath(instance)
                    local matchCount = self:countMatches(source, keyword)
                    
                    table.insert(self.results, {
                        name = instance.Name,
                        path = fullPath,
                        type = instance.ClassName,
                        matches = matchCount,
                        instance = instance,
                        source = source
                    })
                    
                    self.keywordFound = self.keywordFound + 1
                    print("[FOUND] " .. fullPath .. " (" .. matchCount .. " matches)")
                end
            end
            
            -- Recursively scan children
            recursiveScan(instance)
        end
    end
    
    recursiveScan(startLocation)
    
    print("[Deep Scanner] Scan selesai! Total: " .. self.keywordFound .. " script ditemukan")
    return self.results
end

-- Fungsi untuk menghitung jumlah keyword match
function RobloxDeepScanner:countMatches(source, keyword)
    local lowerSource = string.lower(source)
    local lowerKeyword = string.lower(keyword)
    local count = 0
    local pos = 1
    
    while true do
        pos = string.find(lowerSource, lowerKeyword, pos, true)
        if not pos then break end
        count = count + 1
        pos = pos + 1
    end
    
    return count
end

-- Fungsi untuk tampilkan hasil
function RobloxDeepScanner:displayResults(results)
    print("\n" .. string.rep("=", 80))
    print("HASIL SCANNING - DEEP SCANNER ROBLOX")
    print(string.rep("=", 80))
    
    if #results == 0 then
        print("❌ Tidak ada script yang ditemukan")
        return
    end
    
    for i, result in ipairs(results) do
        print("\n📜 Script #" .. i)
        print("  Nama: " .. result.name)
        print("  Tipe: " .. result.type)
        print("  Path: " .. result.path)
        print("  Match: " .. result.matches .. "x")
        print("  Lokasi: game." .. result.path)
    end
    
    print("\n" .. string.rep("=", 80))
    print("Total ditemukan: " .. #results .. " script")
    print(string.rep("=", 80) .. "\n")
end

-- Fungsi untuk export hasil ke table
function RobloxDeepScanner:exportResults()
    local exported = {}
    for _, result in ipairs(self.results) do
        table.insert(exported, {
            name = result.name,
            path = result.path,
            type = result.type,
            matches = result.matches
        })
    end
    return exported
end

-- Fungsi untuk copy path hasil ke clipboard
function RobloxDeepScanner:copyPathToClipboard(index)
    if not self.results[index] then
        warn("[Deep Scanner] Index tidak valid!")
        return
    end
    
    local path = self.results[index].path
    setclipboard("game." .. path)
    print("[Deep Scanner] Path disalin ke clipboard: game." .. path)
end

-- Fungsi untuk dapatkan source code script hasil scan
function RobloxDeepScanner:getResultSource(index)
    if not self.results[index] then
        warn("[Deep Scanner] Index tidak valid!")
        return nil
    end
    
    return self.results[index].source
end

-- Fungsi untuk filter results berdasarkan tipe script
function RobloxDeepScanner:filterByType(scriptType)
    local filtered = {}
    
    for _, result in ipairs(self.results) do
        if result.type == scriptType then
            table.insert(filtered, result)
        end
    end
    
    return filtered
end

-- Fungsi untuk highlight bagian keyword dalam source
function RobloxDeepScanner:highlightKeywordInSource(index, keyword)
    if not self.results[index] then
        warn("[Deep Scanner] Index tidak valid!")
        return nil
    end
    
    local source = self.results[index].source
    local lowerSource = string.lower(source)
    local lowerKeyword = string.lower(keyword)
    local lines = {}
    
    for line in string.gmatch(source, "[^\n]+") do
        if string.find(string.lower(line), lowerKeyword, 1, true) then
            table.insert(lines, line)
        end
    end
    
    return lines
end

-- ==================== USAGE EXAMPLE ====================

--[[
-- Contoh Penggunaan:

local scanner = RobloxDeepScanner:new()

-- 1. Scan untuk keyword "macro"
local results = scanner:scanForKeyword("macro")

-- 2. Tampilkan semua hasil
scanner:displayResults(results)

-- 3. Filter hanya LocalScript
local localScriptResults = scanner:filterByType("LocalScript")
print("LocalScript ditemukan: " .. #localScriptResults)

-- 4. Dapatkan lines yang contain keyword
local keywordLines = scanner:highlightKeywordInSource(1, "macro")
for _, line in ipairs(keywordLines or {}) do
    print(line)
end

-- 5. Copy path ke clipboard
scanner:copyPathToClipboard(1)

-- 6. Export hasil sebagai table
local exportedData = scanner:exportResults()
print(game:GetService("HttpService"):JSONEncode(exportedData))

-- 7. Scan dari lokasi spesifik
local resultsFromWorkspace = scanner:scanForKeyword("macro", workspace)

-- 8. Scan multiple keywords
local keywords = {"macro", "teleport", "autofarm"}
for _, keyword in ipairs(keywords) do
    local keywordResults = scanner:scanForKeyword(keyword)
    print("Keyword '" .. keyword .. "': " .. #keywordResults .. " script ditemukan")
end
]]

return RobloxDeepScanner
