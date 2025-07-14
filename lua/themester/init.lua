-- File: lua/themester/init.lua
-- Modified version of the main themester init file

local controller = require("themester.controller")
local auto_discover = require("themester.auto_discover")

local M = {}

-- Default configuration
local default_config = {
    themes = {},
    auto_discover = {
        enabled = false,
        theme_dir = "themes", -- relative to lua/ directory
        dependency_injection = false, -- whether to automatically load discovered plugins
    },
    livePreview = true,
    themeConfigFile = vim.fn.stdpath("config") .. "/lua/themester/themes.lua",
}

-- Merge user config with defaults
local function merge_config(user_config)
    local config = vim.tbl_deep_extend("force", default_config, user_config or {})
    
    -- Auto-discover themes if enabled
    if config.auto_discover.enabled then
        local discovered_themes = auto_discover.discover_themes(config.auto_discover)
        
        if #discovered_themes > 0 then
            -- Merge discovered themes with manually configured ones
            for _, theme in ipairs(discovered_themes) do
                table.insert(config.themes, theme)
            end
            
            -- Remove duplicates based on colorscheme name
            local seen = {}
            local unique_themes = {}
            for _, theme in ipairs(config.themes) do
                if not seen[theme.colorscheme] then
                    seen[theme.colorscheme] = true
                    table.insert(unique_themes, theme)
                end
            end
            config.themes = unique_themes
            
            -- Sort themes alphabetically
            table.sort(config.themes, function(a, b)
                return a.name < b.name
            end)
        end
    end
    
    return config
end

-- Setup function
function M.setup(user_config)
    local config = merge_config(user_config)
    controller.setup(config)
end

-- Function to get dependencies for lazy.nvim (called externally)
function M.get_auto_dependencies(theme_dir)
    theme_dir = theme_dir or "themes"
    return auto_discover.get_dependencies(theme_dir)
end

-- Expose the main themester function
function M.themester()
    controller.open()
end

-- Create the :Themester command
vim.api.nvim_create_user_command("Themester", function()
    M.themester()
end, {})

return M