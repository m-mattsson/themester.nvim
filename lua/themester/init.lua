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

-- Store config globally
local themester_config = {}

-- Merge user config with defaults
local function merge_config(user_config)
    local config = vim.tbl_deep_extend("force", default_config, user_config or {})
    return config
end

-- Initialize controller with themes
local function initialize_controller(config)
    print("Initializing controller with", #config.themes, "themes")
    
    -- Debug: print themes being passed
    for i, theme in ipairs(config.themes) do
        print(string.format("Theme %d: %s -> %s", i, theme.name, theme.colorscheme))
    end
    
    -- Try different ways to set themes on controller
    if controller.setThemes then
        controller.setThemes(config.themes)
    elseif controller.themes then
        controller.themes = config.themes
    end
    
    -- Try to set config
    if controller.setConfig then
        controller.setConfig(config)
    elseif controller.config then
        controller.config = config
    end
    
    -- Look for initialization functions
    if controller.init then
        controller.init(config)
    elseif controller.bootstrap then
        controller.bootstrap(config)
    elseif controller.setup then
        controller.setup(config)
    end
    
    -- Debug: check what's actually set
    print("Controller state after init:")
    print("  controller.themes:", controller.themes and #controller.themes or "nil")
    print("  controller.config:", controller.config and "set" or "nil")
    
    -- Force set themes if nothing worked
    if not controller.themes or #controller.themes == 0 then
        print("Force setting themes on controller...")
        controller.themes = config.themes
        
        -- Also try common property names
        controller.themeList = config.themes
        controller.availableThemes = config.themes
        controller._themes = config.themes
    end
end

-- Setup function with dynamic loading
function M.setup(user_config)
    local config = merge_config(user_config)
    
    print("Setup called with config")
    
    -- If auto-discovery is enabled, handle dynamic loading
    if config.auto_discover.enabled then
        local theme_dir = vim.fn.stdpath("config") .. "/lua/" .. config.auto_discover.theme_dir
        
        if config.auto_discover.dynamic_loading then
            vim.notify("Themester: Discovering and loading theme plugins...", vim.log.levels.INFO)
            
            local loaded_plugins, failed_plugins = plugin_loader.load_theme_dependencies(theme_dir)
            
            if #loaded_plugins > 0 then
                vim.notify(string.format("Themester: Loaded %d theme plugins", #loaded_plugins), vim.log.levels.INFO)
            end
            
            if #failed_plugins > 0 then
                vim.notify(string.format("Themester: Failed to load %d plugins: %s", 
                    #failed_plugins, table.concat(failed_plugins, ", ")), vim.log.levels.WARN)
            end
            
            if config.auto_discover.wait_for_plugins then
                plugin_loader.wait_for_plugins(5000)
            end
        end
        
        -- Discover themes
        local discovered_themes = auto_discover.discover_themes(config.auto_discover)
        
        if #discovered_themes > 0 then
            for _, theme in ipairs(discovered_themes) do
                table.insert(config.themes, theme)
            end
            
            -- Remove duplicates
            local seen = {}
            local unique_themes = {}
            for _, theme in ipairs(config.themes) do
                if not seen[theme.colorscheme] then
                    seen[theme.colorscheme] = true
                    table.insert(unique_themes, theme)
                end
            end
            config.themes = unique_themes
            
            -- Sort themes
            table.sort(config.themes, function(a, b)
                return a.name < b.name
            end)
            
            vim.notify(string.format("Themester: Auto-discovered %d themes", #discovered_themes), vim.log.levels.INFO)
        end
    end
    
    -- Ensure we have at least one theme
    if #config.themes == 0 then
        config.themes = {{ name = "Default", colorscheme = "default" }}
    end
    
    -- Store config globally
    themester_config = config
    
    -- Initialize controller
    initialize_controller(config)
    
    print("Setup completed with", #config.themes, "themes")
end

-- Function to get current config
function M.get_config()
    return themester_config
end

-- Function to get themes (for controller to call)
function M.get_themes()
    return themester_config.themes or {}
end

-- Expose the main themester function
function M.themester()
    if not controller then
        vim.notify("Themester controller not available", vim.log.levels.ERROR)
        return
    end
    
    -- Double-check themes are set before opening
    if not controller.themes or #controller.themes == 0 then
        print("Re-initializing controller before opening...")
        initialize_controller(themester_config)
    end
    
    -- Debug before opening
    print("Opening themester with themes:", controller.themes and #controller.themes or "nil")
    
    if controller.open then
        controller.open()
    else
        vim.notify("Controller open function not available", vim.log.levels.ERROR)
    end
end

-- Create commands
vim.api.nvim_create_user_command("Themester", function()
    M.themester()
end, {})

vim.api.nvim_create_user_command("Themery", function()
    M.themester()
end, {})

return M