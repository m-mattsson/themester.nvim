local M = {}

-- Load modules
local auto_discover = require("themester.auto_discover")
local plugin_loader = require("themester.plugin_loader")
local controller = require("themester.controller")
local config = require("themester.config")  -- Need this for controller

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
    globalBefore = "",  -- Required by controller
    globalAfter = "",   -- Required by controller
}

-- Store config globally
local themester_config = {}

-- Merge user config with defaults
local function merge_config(user_config)
    local config = vim.tbl_deep_extend("force", default_config, user_config or {})
    return config
end

-- Initialize controller with proper config setup
local function initialize_controller(final_config)
    print("Initializing controller with", #final_config.themes, "themes")
    
    -- Debug: print themes being passed
    for i, theme in ipairs(final_config.themes) do
        print(string.format("Theme %d: %s -> %s", i, theme.name, theme.colorscheme))
    end
    
    -- IMPORTANT: The controller expects config to be set via config.setup()
    -- This is how the original themery works
    local controller_config = config.setup(final_config)
    
    print("Controller config setup completed")
    print("Config themes count:", #controller_config.themes)
    
    -- Now bootstrap the controller (this loads the actual theme config)
    if controller.bootstrap then
        controller.bootstrap()
        print("Controller bootstrap completed")
    end
    
    -- Verify themes are available
    local available_themes = controller.getAvailableThemes()
    print("Available themes after setup:", #available_themes)
    
    for i, theme in ipairs(available_themes) do
        print(string.format("  Available theme %d: %s", i, theme.name))
    end
end

-- Setup function with dynamic loading
function M.setup(user_config)
    local final_config = merge_config(user_config)
    
    print("Setup called with config")
    
    -- If auto-discovery is enabled, handle dynamic loading
    if final_config.auto_discover.enabled then
        local theme_dir = vim.fn.stdpath("config") .. "/lua/" .. final_config.auto_discover.theme_dir
        
        if final_config.auto_discover.dynamic_loading then
            vim.notify("Themester: Discovering and loading theme plugins...", vim.log.levels.INFO)
            
            local loaded_plugins, failed_plugins = plugin_loader.load_theme_dependencies(theme_dir)
            
            if #loaded_plugins > 0 then
                vim.notify(string.format("Themester: Loaded %d theme plugins", #loaded_plugins), vim.log.levels.INFO)
            end
            
            if #failed_plugins > 0 then
                vim.notify(string.format("Themester: Failed to load %d plugins: %s", 
                    #failed_plugins, table.concat(failed_plugins, ", ")), vim.log.levels.WARN)
            end
            
            if final_config.auto_discover.wait_for_plugins then
                plugin_loader.wait_for_plugins(5000)
            end
        end
        
        -- Discover themes
        local discovered_themes = auto_discover.discover_themes(final_config.auto_discover)
        
        if #discovered_themes > 0 then
            for _, theme in ipairs(discovered_themes) do
                table.insert(final_config.themes, theme)
            end
            
            -- Remove duplicates
            local seen = {}
            local unique_themes = {}
            for _, theme in ipairs(final_config.themes) do
                if not seen[theme.colorscheme] then
                    seen[theme.colorscheme] = true
                    table.insert(unique_themes, theme)
                end
            end
            final_config.themes = unique_themes
            
            -- Sort themes
            table.sort(final_config.themes, function(a, b)
                return a.name < b.name
            end)
            
            vim.notify(string.format("Themester: Auto-discovered %d themes", #discovered_themes), vim.log.levels.INFO)
        end
    end
    
    -- Ensure we have at least one theme
    if #final_config.themes == 0 then
        final_config.themes = {{ name = "Default", colorscheme = "default" }}
    end
    
    -- Store config globally
    themester_config = final_config
    
    -- Initialize controller with proper config
    initialize_controller(final_config)
    
    print("Setup completed with", #final_config.themes, "themes")
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
    
    -- Make sure controller is properly initialized
    local available_themes = controller.getAvailableThemes()
    if not available_themes or #available_themes == 0 then
        print("No themes available, re-initializing...")
        initialize_controller(themester_config)
    end
    
    -- Debug before opening
    print("Opening themester...")
    
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