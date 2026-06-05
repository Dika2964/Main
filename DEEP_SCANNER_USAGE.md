# 🔍 Roblox Deep Scanner v3 - Cara Penggunaan

## 📥 Langkah 1: Load Script

Buka executor Roblox Anda (Synapse X, Krnl, Fluxus, dll) dan paste kode ini:

```lua
local Scanner = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dika2964/Main/main/RobloxDeepScanner_v3_Final.lua"))()
```

## 🎯 Langkah 2: Buat Instance Scanner

```lua
local scanner = Scanner:new()
```

## 📍 Langkah 3: Scan Script

### **Opsi A: Scan Semua Lokasi (RECOMMENDED)**

Scanning PlayerGui, Workspace, dan ServerScriptService sekaligus:

```lua
local results = scanner:scanAll("macro")
```

Ganti `"macro"` dengan keyword yang ingin dicari, contoh:
- `"macro"` - Mencari script dengan keyword macro
- `"teleport"` - Mencari script dengan keyword teleport
- `"autofarm"` - Mencari script dengan keyword autofarm
- `"speed"` - Mencari script dengan keyword speed

### **Opsi B: Scan Lokasi Spesifik**

**Scan hanya PlayerGui:**
```lua
local results = scanner:scan("macro", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
```

**Scan hanya Workspace:**
```lua
local results = scanner:scan("macro", workspace)
```

**Scan hanya ServerScriptService:**
```lua
local results = scanner:scan("macro", game:GetService("ServerScriptService"))
```

## 📊 Langkah 4: Tampilkan Hasil

### **Tampilkan Semua Detail:**
```lua
scanner:print(results)
```

Output akan seperti ini:
```
=====================================
HASIL SCAN: 3 SCRIPT
=====================================

[1] AutoMacro
    Type: LocalScript
    Path: PlayerGui/MainUI/AutoMacro
    Match: 5x
    Full: game.PlayerGui.MainUI.AutoMacro

[2] MacroHandler
    Type: ModuleScript
    Path: Workspace/Scripts/MacroHandler
    Match: 3x
    Full: game.Workspace.Scripts.MacroHandler

[3] KeyMacro
    Type: Script
    Path: Workspace/Config/KeyMacro
    Match: 2x
    Full: game.Workspace.Config.KeyMacro

=====================================
```

### **Tampilkan Hanya Path:**
```lua
scanner:printPaths(results)
```

Output:
```
1. game.PlayerGui.MainUI.AutoMacro
2. game.Workspace.Scripts.MacroHandler
3. game.Workspace.Config.KeyMacro
```

## 🔧 Langkah 5: Fungsi Tambahan

### **Copy Path ke Clipboard:**
```lua
scanner:copyPath(1)
```

Output: `COPIED: game.PlayerGui.MainUI.AutoMacro`

### **Filter Hanya LocalScript:**
```lua
local localScripts = scanner:filterByType("LocalScript")
print("Total LocalScript: " .. #localScripts)
```

### **Lihat Keyword dalam Script:**
```lua
scanner:printScriptLines(1, "macro")
```

Output akan menampilkan baris-baris yang mengandung keyword "macro"

### **Dapatkan Source Code Script:**
```lua
local source = scanner:getScriptSource(1)
print(source)
```

### **Export Hasil ke Table:**
```lua
local exported = scanner:exportResults()
for _, item in ipairs(exported) do
    print(item.id .. ". " .. item.path .. " (" .. item.matches .. "x match)")
end
```

## 📝 Contoh Lengkap Script

Salin dan paste ini langsung ke executor:

```lua
local Scanner = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dika2964/Main/main/RobloxDeepScanner_v3_Final.lua"))()

local scanner = Scanner:new()

print("Starting scan for 'macro'...")
local results = scanner:scanAll("macro")

print("\nDisplaying all results:")
scanner:print(results)

print("\nScript paths:")
scanner:printPaths(results)

if #results > 0 then
    print("\nCopying first result path...")
    scanner:copyPath(1)
    
    print("\nShowing keyword lines:")
    scanner:printScriptLines(1, "macro")
    
    print("\nFiltering LocalScripts only:")
    local localScripts = scanner:filterByType("LocalScript")
    print("Found: " .. #localScripts .. " LocalScript(s)")
end
```

## 🎨 Scan Multiple Keywords

Scan beberapa keyword sekaligus:

```lua
local Scanner = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dika2964/Main/main/RobloxDeepScanner_v3_Final.lua"))()

local keywords = {"macro", "teleport", "autofarm", "speed", "noclip"}

for _, keyword in ipairs(keywords) do
    print("\n[SCANNING] " .. keyword)
    local scanner = Scanner:new()
    local results = scanner:scanAll(keyword)
    print("Found: " .. #results .. " script(s)")
end
```

## ⚙️ Advanced: Custom Scan

```lua
local Scanner = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dika2964/Main/main/RobloxDeepScanner_v3_Final.lua"))()

local scanner = Scanner:new()

local results = scanner:scan("customKeyword", workspace)

if #results == 0 then
    print("No scripts found!")
else
    for i, result in ipairs(results) do
        print(i .. ". " .. result.name .. " (" .. result.matches .. " matches)")
    end
end
```

## 🚀 Quick Start (Copy-Paste Langsung)

**Untuk scanning cepat, cukup copy ini:**

```lua
local Scanner = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dika2964/Main/main/RobloxDeepScanner_v3_Final.lua"))()
local scanner = Scanner:new()
local results = scanner:scanAll("macro")
scanner:print(results)
```

## 🐛 Troubleshooting

**Q: Tidak ada hasil yang ditemukan?**
A: Cek apakah keyword benar. Gunakan keyword yang lebih umum seperti "script", "function", dll.

**Q: Error saat scanning?**
A: Kemungkinan executor tidak mendukung. Coba gunakan Synapse X atau Krnl.

**Q: Bagaimana cara scan game yang berbeda?**
A: Masuk ke game yang ingin di-scan, baru jalankan script scanner.

**Q: Bisa scan di ServerScriptService?**
A: Hanya bisa jika executor punya akses level tinggi (seperti Synapse X).

## 📌 Catatan Penting

- Script ini **TIDAK akan crash game** seperti Ketamine
- Hasil scanning **aman untuk digunakan**
- Bisa di-run berkali-kali tanpa masalah
- Compatible dengan semua executor modern

---

**Happy Scanning!** 🎮✨
