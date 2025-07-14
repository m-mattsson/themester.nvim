local M = {}

-- Load modules
local auto_discover = require("themester.auto_discover")
local plugin_loader = require("themester.plugin_loader")
local controller = require("themester.controller")

-- Default configuration
local default_config = {
    themes = {},
    auto_discover = {
        enabled = false,
        theme_dir = "themes",
        dynamic_loading = true,
        wait_for_plugins = true,
    },
    livePreview = true,
}

-- Store config globally for controller access
local themester_config = {}

-- Merge user config with defaults
local function merge_config(user_config)
    local config = vim.tbl_deep_extend("force", default_config, user_config or {})
    return config
end

-- Setup function with dynamic loading
function M.setup(user_config)
    local config = merge_config(user_config)
    
    print("Setup called with config:", vim.inspect(config))
    
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
    
    -- Store config globally for controller to access
    themester_config = config
    
    -- Initialize controller manually since it doesn't have setup
    if controller then
        -- Set the themes directly on controller if it has a themes property
        controller.themes = config.themes
        controller.config = config
        
        -- Call bootstrap if it exists
        if controller.bootstrap then
            controller.bootstrap(config)
        end
        
        print("Controller initialized with", #config.themes, "themes")
    end
end

-- Function to get current config (for controller to access)
function M.get_config()
    return themester_config
end

-- Expose the main themester function
function M.themester()
    if controller and controller.open then
        controller.open()
    else
        vim.notify("Themester controller not available", vim.log.levels.ERROR)
    end
end

-- Create the :Themester command
vim.api.nvim_create_user_command("Themester", function()
    M.themester()
end, {})

-- Also create :Themery for backward compatibility
vim.api.nvim_create_user_command("Themery", function()
    M.themester()
end, {})

return M