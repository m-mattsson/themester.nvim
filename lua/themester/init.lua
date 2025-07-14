local controller = require("themester.controller")
local auto_discover = require("themester.auto_discover")
local plugin_loader = require("themester.plugin_loader")

local M = {}

-- Default configuration
local default_config = {
    themes = {},
    auto_discover = {
        enabled = false,
        theme_dir = "themes", -- relative to lua/ directory
        dynamic_loading = true, -- Enable dynamic plugin loading
        wait_for_plugins = true, -- Wait for plugins to load before setup
    },
    livePreview = true,
    themeConfigFile = vim.fn.stdpath("config") .. "/lua/themester/themes.lua",
}

-- Merge user config with defaults
local function merge_config(user_config)
    local config = vim.tbl_deep_extend("force", default_config, user_config or {})
    return config
end

-- Setup function with dynamic loading
function M.setup(user_config)
    local config = merge_config(user_config)
    
    -- If auto-discovery is enabled, handle dynamic loading
    if config.auto_discover.enabled then
        local theme_dir = vim.fn.stdpath("config") .. "/lua/" .. config.auto_discover.theme_dir
        
        if config.auto_discover.dynamic_loading then
            -- Dynamically load theme plugins
            vim.notify("Themester: Discovering and loading theme plugins...", vim.log.levels.INFO)
            
            local loaded_plugins, failed_plugins = plugin_loader.load_theme_dependencies(theme_dir)
            
            if #loaded_plugins > 0 then
                vim.notify(string.format("Themester: Loaded %d theme plugins", #loaded_plugins), vim.log.levels.INFO)
            end
            
            if #failed_plugins > 0 then
                vim.notify(string.format("Themester: Failed to load %d plugins: %s", 
                    #failed_plugins, table.concat(failed_plugins, ", ")), vim.log.levels.WARN)
            end
            
            -- Wait for plugins to be fully loaded
            if config.auto_discover.wait_for_plugins then
                vim.notify("Themester: Waiting for plugins to load...", vim.log.levels.INFO)
                plugin_loader.wait_for_plugins(5000)
            end
        end
        
        -- Now discover themes
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
            
            vim.notify(string.format("Themester: Auto-discovered %d themes", #discovered_themes), vim.log.levels.INFO)
        end
    end
    
    -- Setup controller
    controller.setup(config)
end

-- Expose the main Themester function
function M.themester()
    controller.open()
end

-- Create the :Themester command
vim.api.nvim_create_user_command("Themester", function()
    M.themester()
end, {})

return M