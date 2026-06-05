-- ScriptScanner_optimized.lua
-- Optimized batched script scanner module
-- Usage (example):
-- local Scanner = require(path.to.ScriptScanner_optimized)
-- local handle = Scanner.scan{
--     root = workspace,
--     query = "print",
--     onResult = function(match) print(match.path, match.instance) end,
--     onProgress = function(processed, total) end,
--     onComplete = function(stats) print("done", stats) end,
--     nodesPerStep = 250, -- optional
--     debounce = 0.12,    -- optional UI update debounce
--     maxResults = 1000   -- optional cap on results to collect
-- }
-- handle:cancel() -- to cancel an in-progress scan

local RunService = game:GetService("RunService")

local Scanner = {}
Scanner.__index = Scanner

local function defaultOptions(opts)
    opts = opts or {}
    opts.nodesPerStep = opts.nodesPerStep or 250
    opts.debounce = opts.debounce or 0.12
    opts.maxResults = opts.maxResults or 1000
    opts.recursive = opts.recursive == nil and true or opts.recursive
    return opts
end

-- Safe tostring for instance path
local function instancePath(inst)
    local parts = {}
    while inst and inst ~= game do
        table.insert(parts, 1, inst.Name or "<unknown>")
        inst = inst.Parent
    end
    return table.concat(parts, "/")
end

local function safeMatchString(source, query)
    -- fast path: simple substring search
    local ok, res = pcall(function() return string.find(source, query, 1, true) end)
    return ok and res ~= nil
end

-- scan options: root, query, onResult, onProgress, onComplete, nodesPerStep, debounce, maxResults
function Scanner.scan(opts)
    assert(type(opts) == "table", "Scanner.scan requires an options table")
    opts = defaultOptions(opts)
    assert(opts.root and typeof(opts.root) == "Instance", "opts.root must be an Instance")
    assert(opts.query and type(opts.query) == "string", "opts.query must be a string")

    local running = true
    local queue = {opts.root}
    local results = {}
    local processed = 0
    local totalProcessedThisStep = 0
    local lastDebounce = 0

    local connection

    local onResult = opts.onResult
    local onProgress = opts.onProgress
    local onComplete = opts.onComplete

    local nodesPerStep = math.max(1, tonumber(opts.nodesPerStep) or 250)
    local debounce = math.max(0.01, tonumber(opts.debounce) or 0.12)
    local maxResults = math.max(1, tonumber(opts.maxResults) or 1000)

    local function step(dt)
        if not running then
            if connection then connection:Disconnect() end
            return
        end

        local nodesThisStep = 0
        while nodesThisStep < nodesPerStep and #queue > 0 do
            local inst = table.remove(queue, 1)
            nodesThisStep = nodesThisStep + 1
            processed = processed + 1

            -- examine instance properties that commonly contain scripts
            local ok, props = pcall(function()
                -- attempt to read Name and ClassName and Source if present
                local class = inst.ClassName or ""
                local name = inst.Name or ""
                local sourceText = ""
                -- if object is a ModuleScript or Script, try reading its Source
                if inst:IsA("ModuleScript") or inst:IsA("Script") or inst:IsA("LocalScript") then
                    -- read Source safely
                    local sOk, sVal = pcall(function() return inst.Source end)
                    if sOk and sVal then
                        sourceText = sVal
                    end
                end
                return class, name, sourceText
            end)

            if ok then
                local class, name, sourceText = props[1], props[2], props[3]
                local matched = false
                -- check name and className quickly
                if name and name ~= "" and safeMatchString(name, opts.query) then
                    matched = true
                end
                if (not matched) and class and class ~= "" and safeMatchString(class, opts.query) then
                    matched = true
                end
                -- check source
                if (not matched) and sourceText and sourceText ~= "" and safeMatchString(sourceText, opts.query) then
                    matched = true
                end

                if matched then
                    local match = {
                        instance = inst,
                        path = instancePath(inst),
                        type = inst.ClassName,
                        matchedOn = "unknown"
                    }
                    table.insert(results, match)
                    if onResult and #results <= maxResults then
                        -- call immediately or let debounce handle? We call immediately but user can debounce UI
                        local okR, err = pcall(function() onResult(match) end)
                        if not okR then
                            -- ignore callback errors
                        end
                    end
                    if #results >= maxResults then
                        -- reached cap; we keep scanning but stop pushing results
                        -- optionally we could stop scanning entirely; for now we continue but don't call onResult beyond cap
                    end
                end
            end

            -- enqueue children if recursive
            if opts.recursive then
                local childrenOk, children = pcall(function() return inst:GetChildren() end)
                if childrenOk and children then
                    for i = 1, #children do
                        table.insert(queue, children[i])
                    end
                end
            end
        end

        -- progress callback
        if onProgress then
            local okP, err = pcall(function() onProgress(processed, #queue) end)
            if not okP then end
        end

        if #queue == 0 then
            running = false
            if connection then connection:Disconnect() end
            if onComplete then
                pcall(function() onComplete({processed = processed, results = results, capped = (#results >= maxResults)}) end)
            end
        end
    end

    connection = RunService.Heartbeat:Connect(step)

    local handle = {}
    function handle:cancel()
        running = false
        if connection then connection:Disconnect() end
        if onComplete then
            pcall(function() onComplete({processed = processed, results = results, canceled = true}) end)
        end
    end

    return handle
end

return Scanner
