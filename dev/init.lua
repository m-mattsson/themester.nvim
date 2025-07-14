package.loaded['dev'] = nil
package.loaded['themester'] = nil
package.loaded['themester.module'] = nil
package.loaded['themester.config'] = nil
package.loaded['themester.constants'] = nil
package.loaded['themester.controller'] = nil
package.loaded['themester.persistence'] = nil
package.loaded['themester.utils'] = nil
package.loaded['themester.window'] = nil

vim.api.nvim_set_keymap('n', ',r', '<cmd>luafile dev/init.lua<cr><cmd>lua require("themester").pop()<cr>', {})

