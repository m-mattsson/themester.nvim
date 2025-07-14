-- module for dynamic plugin loading

local M = {}

-- Function to dynamically load plugins using lazy.nvim
local function load_plugin_dynamically(plugin_spec)
    local lazy_available, lazy = pcall(require, "lazy")
    if not lazy_available then
        vim.notify("Lazy.nvim not available for dynamic loading", vim.log.levels.ERROR)
        return false
    end
    
    -- Check if plugin is already loaded
    local lazy_plugins = lazy.plugins()
    for _, loaded_plugin in ipairs(lazy_plugins) do
        if loaded_plugin[1] == plugin_spec or loaded_plugin.name == plugin_spec then
            return true -- Already loaded
        end
    end
    
    -- Dynamically add and load the plugin
    local success = pcall(function()
        lazy.load({ plugin_spec })
    end)
    
    if not success then
        -- Try alternative loading method
        success = pcall(function()
            local plugin_config = { plugin_spec, lazy = false }
            lazy.setup({ plugin_config })
        end)
    end
    
    return success
end

-- Function to extract and load theme plugin dependencies
function M.load_theme_dependencies(theme_dir)
    local loaded_plugins = {}
    local failed_plugins = {}
    
    if vim.fn.isdirectory(theme_dir) == 0 then
        return loaded_plugins, failed_plugins
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
            local file = io.open(file_path, "r")
            if file then
                local content = file:read("*all")
                file:close()
                
                -- Extract plugin URLs using pattern matching
                for plugin_url in content:gmatch('["\']([%w%-_%.]+/[%w%-_%.]+)["\']') do
                    -- Avoid duplicates
                    local already_processed = false
                    for _, loaded in ipairs(loaded_plugins) do
                        if loaded == plugin_url then
                            already_processed = true
                            break
                        end
                    end
                    for _, failed in ipairs(failed_plugins) do
                        if failed == plugin_url then
                            already_processed = true
                            break
                        end
                    end
                    
                    if not already_processed then
                        -- Try to load the plugin dynamically
                        if load_plugin_dynamically(plugin_url) then
                            table.insert(loaded_plugins, plugin_url)
                            vim.notify("Dynamically loaded: " .. plugin_url, vim.log.levels.INFO)
                        else
                            table.insert(failed_plugins, plugin_url)
                            vim.notify("Failed to load: " .. plugin_url, vim.log.levels.WARN)
                        end
                    end
                end
            end
        end
    end
    
    return loaded_plugins, failed_plugins
end

-- Alternative approach: Use Lazy's add API
function M.load_theme_dependencies_lazy_add(theme_dir)
    local lazy_available, lazy = pcall(require, "lazy")
    if not lazy_available then
        vim.notify("Lazy.nvim not available", vim.log.levels.ERROR)
        return {}, {}
    end
    
    local loaded_plugins = {}
    local failed_plugins = {}
    
    if vim.fn.isdirectory(theme_dir) == 0 then
        return loaded_plugins, failed_plugins
    end
    
    -- Get discovered plugins
    local discovered_plugins = {}
    local files = {}
    local success, result = pcall(vim.fn.glob, theme_dir .. "/*.lua", false, true)
    if success then
        files = result
    end
    
    for _, file_path in ipairs(files) do
        local filename = vim.fn.fnamemodify(file_path, ":t:r")
        
        if filename ~= "themester" and filename ~= "init" then
            local file = io.open(file_path, "r")
            if file then
                local content = file:read("*all")
                file:close()
                
                for plugin_url in content:gmatch('["\']([%w%-_%.]+/[%w%-_%.]+)["\']') do
                    if not discovered_plugins[plugin_url] then
                        discovered_plugins[plugin_url] = true
                    end
                end
            end
        end
    end
    
    -- Convert to plugin specs and add them
    local plugin_specs = {}
    for plugin_url, _ in pairs(discovered_plugins) do
        table.insert(plugin_specs, {
            plugin_url,
            lazy = false,
            priority = 800, -- Load before themester
        })
    end
    
    if #plugin_specs > 0 then
        -- Add plugins to lazy
        local add_success = pcall(function()
            for _, spec in ipairs(plugin_specs) do
                lazy.plugins[spec[1]] = spec
            end
            
            -- Trigger lazy to process new plugins
            lazy.reload()
        end)
        
        if add_success then
            for _, spec in ipairs(plugin_specs) do
                table.insert(loaded_plugins, spec[1])
            end
        else
            for _, spec in ipairs(plugin_specs) do
                table.insert(failed_plugins, spec[1])
            end
        end
    end
    
    return loaded_plugins, failed_plugins
end

-- Function to wait for plugins to be fully loaded
function M.wait_for_plugins(timeout_ms)
    timeout_ms = timeout_ms or 5000
    local start_time = vim.loop.hrtime()
    
    while (vim.loop.hrtime() - start_time) / 1000000 < timeout_ms do
        -- Check if all plugins are loaded
        local lazy_available, lazy = pcall(require, "lazy")
        if lazy_available then
            local stats = lazy.stats()
            if stats.loaded == stats.count then
                return true
            end
        end
        
        -- Wait a bit
        vim.wait(100)
    end
    
    return false
end

return M