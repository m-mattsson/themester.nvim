local TITLE = "Themester - Theme Selector"

local DEFAULT_SETTINGS = {
  themes = {},
  themesConfigFile = "",
  globalBefore = "",
  globalAfter = "",
  livePreview = true,
}

local RESULTS_TOP_MARGIN = 2

local MSG_INFO = {
  NO_SETUP = "Themester is not configured. See installation guide.",
  NO_THEMES_CONFIGURED = "No themes configured. See :help Themester",
  THEME_SAVED = "Theme Saved",
  THEME_CONFIG_FILE_DEPRECATED = "Themester: The ‘themeConfigFile’ property is deprecated. Delete it from config and use normally. More info in the project page.",
  GLOBAL_SETTINGS_CHANGED = "Themester: Global settings changes detected. Please restart to apply the changes."
}

local MSG_ERROR = {
  THEME_NOT_LOADED = "Themester error: Could not load theme",
  GENERIC = "Themester error",
  NO_MARKETS = "Themester error: Could not find markets in config file. See \"Persistence\"",
  READ_FILE = "Themester error: Could not open file for read",
  CREATE_DIRECTORY = "Themester error: Could not create themester directory",
  WRITE_FILE = "Themester error: Could not open file for writing",
}

return {
  TITLE = TITLE,
  DEFAULT_SETTINGS = DEFAULT_SETTINGS,
  RESULTS_TOP_MARGIN = RESULTS_TOP_MARGIN,
  MSG_INFO = MSG_INFO,
  MSG_ERROR = MSG_ERROR,
}
