-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Use absolute line numbers
vim.opt.relativenumber = false

-- Enable mouse support
vim.opt.mouse = "a"

-- System clipboard integration
-- Use OSC52 only when in SSH session, otherwise use default (pbcopy/pbpaste)
vim.opt.clipboard = "unnamedplus"

if os.getenv("SSH_TTY") then
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
      ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
      ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
    },
  }
end
