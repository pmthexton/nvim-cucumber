-- requiring cucumber here ensures that the user command has been defined.
require("cucumber")

-- setup keymaps
vim.api.nvim_buf_set_keymap(0, 'n', '<Leader>cd', ':CucumberDebugCurrentScenario<CR>', { noremap = true, silent = true })

-- Not implemented yet
-- vim.api.nvim_buf_set_keymap(0, 'n', '<Leader>ct', ':CucumberRunCurrentScenario<CR>', { noremap = true, silent = true })
