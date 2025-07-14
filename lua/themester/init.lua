-- The issue is that the controller has a local variable 'themeList' that needs to be set
-- You need to modify your lua/themester/controller.lua file

-- Look for line 101 in controller.lua - it probably looks something like:
-- local themeList = ...
-- for i = 1, #themeList do  -- <-- This is line 101 causing the error

-- Here are the fixes to add to your controller.lua:

-- Option 1: Add this at the top of controller.lua (after any existing local variables)
local M = {}
local themeList = {} -- Initialize themeList

-- Option 2: Add a function to set themeList
function M.setThemeList(themes)
    themeList = themes or {}
end

-- Option 3: Modify the updateView function to use M.themes instead of themeList
-- Find the updateView function and change lines like:
-- for i = 1, #themeList do
-- to:
-- for i = 1, #(M.themes or {}) do

-- Option 4: Complete controller initialization function
function M.initialize(config)
    if config and config.themes then
        themeList = config.themes
        M.themes = config.themes
        M.config = config
    end
end

-- Make sure at the end of controller.lua you have:
return M

---

-- Meanwhile, update your init.lua to call the new initialize function:
-- Add this to your initialize_controller function in init.lua:

local function initialize_controller(config)
    print("Initializing controller with", #config.themes, "themes")
    
    -- Debug: print themes being passed
    for i, theme in ipairs(config.themes) do
        print(string.format("Theme %d: %s -> %s", i, theme.name, theme.colorscheme))
    end
    
    -- NEW: Call initialize function if it exists
    if controller.initialize then
        controller.initialize(config)
        print("Called controller.initialize")
    end
    
    -- NEW: Call setThemeList function if it exists
    if controller.setThemeList then
        controller.setThemeList(config.themes)
        print("Called controller.setThemeList")
    end
    
    -- Try other methods
    if controller.setThemes then
        controller.setThemes(config.themes)
    end
    
    -- Set properties
    controller.themes = config.themes
    controller.config = config
    
    -- Try initialization functions
    if controller.init then
        controller.init(config)
    elseif controller.bootstrap then
        controller.bootstrap(config)
    elseif controller.setup then
        controller.setup(config)
    end
    
    print("Controller initialization completed")
end