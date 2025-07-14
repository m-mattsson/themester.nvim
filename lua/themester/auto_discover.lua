-- File: lua/themester/auto_discover.lua
-- New module for auto-discovery functionality

local M = {}

-- Function to extract plugin URLs from theme files
local function extract_dependencies(theme_dir)
    local dependencies = {}
    
    if vim.fn.isdirectory(theme_dir) == 0 then
        return dependencies
    end
    
    local files = {}
    local success, result = pcall(vim.fn.glob, theme_dir .. "/*.lua", false, true)
    if success then
        files = result
    end
    
    for _, file_path in ipairs(files) do
        local filename = vim.fn.fnamemodify(file_path, ":t:r")
        
        -- Skip certain files
        if filename ~= "themester" and filename ~= "init" then
            local file = io.open(file_path, "r")
            if file then
                local content = file:read("*all")
                file:close()
                
                -- Extract plugin URLs using pattern matching
                for plugin_url in content:gmatch('["\']([%w%-_%.]+/[%w%-_%.]+)["\']') do
                    -- Avoid duplicates
                    local already_exists = false
                    for _, dep in ipairs(dependencies) do
                        if dep == plugin_url then
                            already_exists = true
                            break
                        end
                    end
                    
                    if not already_exists then
                        table.insert(dependencies, plugin_url)
                    end
                end
            end
        end
    end
    
    return dependencies
end

-- Function to extract colorschemes from theme file content
local function extract_colorschemes_from_file(file_path)
    local file = io.open(file_path, "r")
    if not file then return {} end
    
    local content = file:read("*all")
    file:close()
    
    local colorschemes = {}
    
    -- Look for vim.cmd.colorscheme patterns
    for colorscheme in content:gmatch("vim%.cmd%.colorscheme%s+['\"]([^'\"]+)['\"]") do
        table.insert(colorschemes, colorscheme)
    end
    
    -- Look for vim.cmd("colorscheme ...") patterns
    for colorscheme in content:gmatch("vim%.cmd%(['\"]colorscheme%s+([^'\"]+)['\"]%)") do
        table.insert(colorschemes, colorscheme)
    end
    
    -- Look for :colorscheme patterns in strings
    for colorscheme in content:gmatch(":colorscheme%s+([%w%-_]+)") do
        table.insert(colorschemes, colorscheme)
    end
    
    return colorschemes
end

-- Function to generate theme name from colorscheme
local function generate_theme_name(colorscheme)
    -- Handle common naming patterns
    local name_mappings = {
        ["tokyonight%-?(.*)"] = function(variant)
            if variant == "" or variant == "night" then
                return "TokyoNight Night"
            else
                return "TokyoNight " .. variant:gsub("^%l", string.upper)
            end
        end,
        ["kanagawa%-?(.*)"] = function(variant)
            if variant == "" or variant == "wave" then
                return "Kanagawa Wave"
            else
                return "Kanagawa " .. variant:gsub("^%l", string.upper)
            end
        end,
        ["catppuccin%-?(.*)"] = function(variant)
            if variant == "" then
                return "Catppuccin"
            else
                return "Catppuccin " .. variant:gsub("^%l", string.upper)
            end
        end,
        ["(.-)fox"] = function(variant)
            if variant == "night" then
                return "Nightfox"
            else
                return variant:gsub("^%l", string.upper) .. "fox"
            end
        end
    }
    
    -- Try to match known patterns
    for pattern, name_func in pairs(name_mappings) do
        local variant = colorscheme:match("^" .. pattern .. "$")
        if variant ~= nil then
            return name_func(variant)
        end
    end
    
    -- Handle special cases
    if colorscheme == "visual_studio_code" then
        return "Visual Studio Code"
    elseif colorscheme == "arctic" then
        return "Arctic"
    end
    
    -- Default: capitalize and clean up the colorscheme name
    return colorscheme:gsub("^%l", string.upper):gsub("[-_]", " "):gsub("%s+", " ")
end

-- Main auto-discovery function
function M.discover_themes(config)
    local themes = {}
    local theme_dir = vim.fn.stdpath("config") .. "/lua/" .. config.theme_dir
    
    -- Check if directory exists
    if vim.fn.isdirectory(theme_dir) == 0 then
        return themes
    end
    
    -- Get all .lua files
    local files = {}
    local success, result = pcall(vim.fn.glob, theme_dir .. "/*.lua", false, true)
    if success then
        files = result
    end
    
    for _, file_path in ipairs(files) do
        local filename = vim.fn.fnamemodify(file_path, ":t:r")
        
        -- Skip certain files
        if filename ~= "themester" and filename ~= "init" then
            -- Extract colorschemes from this file
            local colorschemes = extract_colorschemes_from_file(file_path)
            
            if #colorschemes > 0 then
                -- Use extracted colorschemes
                for _, colorscheme in ipairs(colorschemes) do
                    local name = generate_theme_name(colorscheme)
                    table.insert(themes, {
                        name = name,
                        colorscheme = colorscheme
                    })
                end
            else
                -- Fallback: create default entry
                local display_name = filename:gsub("^%l", string.upper):gsub("_", " ")
                table.insert(themes, {
                    name = display_name,
                    colorscheme = filename
                })
            end
        end
    end
    
    return themes
end

-- Function to get dependencies for lazy.nvim
function M.get_dependencies(theme_dir)
    local full_theme_dir = vim.fn.stdpath("config") .. "/lua/" .. theme_dir
    return extract_dependencies(full_theme_dir)
end

return M