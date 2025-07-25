local M = {}

local themeList = {}
local constants = require("themester.constants")
local config = require("themester.config")
local persistence = require("themester.persistence")
local window = require("themester.window")
local api = vim.api

local position = 0
local selectedThemeId = 0
local resultsStart = constants.RESULTS_TOP_MARGIN

-- Add the missing load function
function M.load(code)
	local fn, err = load(code)
	if err then
		return nil, err
	end
	return fn, nil
end

function M.loadActualThemeConfig()
	local themeList = config.getSettings().themes
	selectedThemeId = vim.g.theme_id

	-- if currentThemeId isn't set, it's because it's the first time it has been run
	if not selectedThemeId then
		position = resultsStart
		return
	end

	for k in pairs(themeList) do
		if selectedThemeId == k then
			position = k + resultsStart - 1
			return
		end
	end
end

function M.setColorscheme(theme)
	local globalBefore = config.getSettings().globalBefore
	local globalAfter = config.getSettings().globalAfter

	if globalBefore then
		local fn, err = M.load(globalBefore)
		if err then
			print("Themester error: " .. err)
			return false
		end
		if fn then
			fn()
		end
	end

	if theme.before then
		local fn, err = M.load(theme.before)
		if err then
			print("Themester error: " .. err)
			return false
		end
		if fn then
			fn()
		end
	end

	local ok, _ = pcall(vim.cmd, "colorscheme " .. theme.colorscheme)

	-- check if the colorscheme was loaded successfully
	if not ok then
		print(constants.MSG_ERROR.THEME_NOT_LOADED .. ": " .. theme.colorscheme)
		-- Restore previus
		local currentThemes = config.getSettings().themes
		if selectedThemeId and currentThemes[selectedThemeId] then
			vim.cmd("colorscheme " .. currentThemes[selectedThemeId].colorscheme)
		end
		return false
	end

	if globalAfter then
		local fn, err = M.load(globalAfter)
		if err then
			print("Themester error: " .. err)
			return false
		end
		if fn then
			fn()
		end
	end

	if theme.after then
		local fn, err = M.load(theme.after)
		if err then
			print(constants.MSG_ERROR.GENERIC .. ": " .. err)
			return false
		end
		if fn then
			fn()
		end
	end

	return true
end

function M.updateView(direction)
    local themeList = config.getSettings().themes
    position = position + direction
    api.nvim_set_option_value("modifiable", true, {buf=window.getBuf()})

    -- cycle to the last result if cursor is at the top of the results list and moved up
    if position < resultsStart then
        position = #themeList + resultsStart - 1
    end

    -- cycle to the first result if cursor is at the bottom of the results list and moved down
    if position > #themeList + resultsStart - 1 then
        position = resultsStart
    end

    if #themeList == 0 then
        window.printNoThemesLoaded()
        api.nvim_set_option_value("modifiable", false, {buf=window.getBuf()})
        return
    end

    local resultToPrint = {}
    for i in ipairs(themeList) do
        local prefix = "  "

        if selectedThemeId == i then
            prefix = "> "
        end

        resultToPrint[i] = prefix .. themeList[i].name
    end

    api.nvim_buf_set_lines(window.getBuf(), 1, -1, false, resultToPrint)
    api.nvim_win_set_cursor(window.getWin(), { position, 0 })

    -- Live preview - apply theme as you navigate
    if config.getSettings().livePreview then
        local themeIndex = position - resultsStart + 1  -- Calculate correct index
        if themeList[themeIndex] then
            print("Applying theme:", themeList[themeIndex].name)
            M.setColorscheme(themeList[themeIndex])
        end
    end

    api.nvim_set_option_value("modifiable", false, {buf=window.getBuf()})
end

function M.revertTheme()
	local colorschemeToSet

	-- If there is no previous theme to revert to, use the default.
	if selectedThemeId then
		colorschemeToSet = config.getSettings().themes[selectedThemeId]
	else
		colorschemeToSet = { colorscheme = "default" }
	end
	M.setColorscheme(colorschemeToSet)
end

function M.open()
	M.loadActualThemeConfig()
	window.openWindow()
    M.setupKeyMappings()
	M.updateView(0)
end

function M.close()
	window.closeWindow()
end

function M.setPosition (value)
  position = value
end

function M.closeAndRevert()
	M.revertTheme()
	window.closeWindow()
end

function M.save()
	local theme = config.getSettings().themes[position - 1]
	persistence.saveTheme(theme, position - 1)
	selectedThemeId = position - 1
	vim.g.theme_id = selectedThemeId
end

function M.closeAndSave()
	M.save()
	window.closeWindow()
end

--- Sets the colorscheme based on the specified name.
-- This function retrieves the list of available themes from the config,
-- searches for the theme with the specified name, and applies the colorscheme.
--
-- @param name string The name of the theme to apply.
-- @param makePersistent boolean Whether to save the current state after applying the colorscheme.
-- @usage
-- 	 setThemeByName("monokai") -- Applies the monokai theme
--
-- @error Prints an error message if the theme is not found.
function M.setThemeByName(name, makePersistent)
	makePersistent = makePersistent or false
	local themes = config.getSettings().themes
	for index, theme in ipairs(themes) do
		if theme.name == name or theme.colorscheme == name then
			position = index + 1
			selectedThemeId = index + 1
			M.setColorscheme(themes[index])
			if makePersistent then
				M.save()
			end
			return
		end
	end
	print("Themester: Theme \"" .. name .. "\" not found.")
end

--- Sets the colorscheme based on the specified index.
-- This function retrieves the list of available themes from the config,
-- validates the provided index, and applies the colorscheme at that index.
-- If the index is out of range, an error message is printed. After setting the
-- colorscheme, the current state is saved.
--
-- @param index number The index of the theme to apply. Must be between 1 and the total number of available themes.
-- @param makePersistent boolean Whether to save the current state after applying the colorscheme.
-- @usage
--   setThemeByIndex(2)  -- Applies the theme at index 2
--
-- @error Prints an error message if the index is invalid.
function M.setThemeByIndex(index, makePersistent)
	makePersistent = makePersistent or false
	local themes = config.getSettings().themes
	if index < 1 or index > #themes then
		print("Themester: Invalid index. Should be between 1 and " .. #themes .. ".")
		return
	end
	position = index + 1
	selectedThemeId = index
	M.setColorscheme(themes[index])
	if makePersistent then
		M.save()
	end
end

--- Retrieves the current theme..
--
-- @return table|nil A table containing the name and index of the current theme if it exists, or nil if not.
function M.getCurrentTheme()
	M.loadActualThemeConfig()
	local themes = config.getSettings().themes
	if themes[selectedThemeId] then
		return {
			name = themes[selectedThemeId].name,
			index = position
		}
	else
		return nil
	end
end

-- Setup key mappings for the themester window
function M.setupKeyMappings()
    local buf = window.getBuf()
    local opts = { buffer = buf, noremap = true, silent = true }
    
    -- Navigation keys (j/k and arrow keys)
    vim.keymap.set('n', 'j', function() M.updateView(1) end, opts)
    vim.keymap.set('n', '<Down>', function() M.updateView(1) end, opts)
    vim.keymap.set('n', 'k', function() M.updateView(-1) end, opts)
    vim.keymap.set('n', '<Up>', function() M.updateView(-1) end, opts)
    
    -- Selection keys (Enter and Space to select theme)
    vim.keymap.set('n', '<CR>', function() M.closeAndSave() end, opts)
    vim.keymap.set('n', '<Space>', function() M.closeAndSave() end, opts)
    
    -- Cancel/close keys (q and Esc to cancel and revert)
    vim.keymap.set('n', 'q', function() M.closeAndRevert() end, opts)
    vim.keymap.set('n', '<Esc>', function() M.closeAndRevert() end, opts)
    
    -- Help key
    vim.keymap.set('n', '?', function()
        print("Themester: ↑↓/jk=navigate, Enter/Space=select, q/Esc=cancel")
    end, opts)
    
    print("Themester keymaps set up")
end

--- Retrieves the available themes.
--
-- @return table A table containing the available themes.
function M.getAvailableThemes()
	M.loadActualThemeConfig()
	return config.getSettings().themes
end

function M.bootstrap()
	M.loadActualThemeConfig()
	persistence.loadState() 
end

return M