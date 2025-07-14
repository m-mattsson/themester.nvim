local constants = require("themester.constants")
local utils = require("themester.utils")
local api = vim.api
local buf, win

-- Calculates the window transformation for centering the themester window
local function getWinTransform()
	local totalWidth = api.nvim_get_option("columns")
	local totalHeight = api.nvim_get_option("lines")
	local height = math.ceil(totalHeight * 0.4 - 4)
	local width = math.ceil(totalWidth * 0.3)

	return {
		row = math.ceil((totalHeight - height) / 2 - 1),
		col = math.ceil((totalWidth - width) / 2),
		height = height,
		width = width,
	}
end

-- Closes the themester window
local function closeWindow()
	api.nvim_win_close(win, true)
end

local function setupCloseOnUnfocus(buffer)
	-- Create an autocommand group to detect when the window loses focus
	local group_id = api.nvim_create_augroup("ThemesterWindowFocus", { clear = true })

	-- Set up an autocommand for WinLeave and BufLeave events to call on_focus_lost
	api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
		group = group_id,
		buffer = buffer,
		callback = closeWindow,
		once = true,
	})
end

-- Opens the Themester window with minimal style and centered positioning
local function openWindow()
	buf = api.nvim_create_buf(false, true)
	api.nvim_set_option_value("filetype", "themester", { buf = buf })
	api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
	setupCloseOnUnfocus(buf)

	local winTransform = getWinTransform()

	local opts = {
		style = "minimal",
		relative = "editor",
		border = "rounded",
		width = winTransform.width,
		height = winTransform.height,
		row = winTransform.row,
		col = winTransform.col,
	}

	win = api.nvim_open_win(buf, true, opts)
	api.nvim_set_option_value("cursorline", true, { win = win })

	local title = utils.centerHorizontal(constants.TITLE)
	api.nvim_buf_set_lines(buf, 0, -1, false, { title })
end

-- Prints a message when no themes are loaded
local function printNoThemesLoaded()
	local text = constants.MSG_INFO.NO_THEMES_CONFIGURED
	api.nvim_buf_set_lines(buf, 1, -1, false, { text })
end

-- Retrieves the buffer ID of the Themester window
local getBuf = function()
	return buf
end

-- Retrieves the window ID of the Themester window
local getWin = function()
	return win
end

return {
	openWindow = openWindow,
	closeWindow = closeWindow,
	printNoThemesLoaded = printNoThemesLoaded,
	getBuf = getBuf,
	getWin = getWin,
}
