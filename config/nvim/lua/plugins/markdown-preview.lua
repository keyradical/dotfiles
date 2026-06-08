return {
  "iamcco/markdown-preview.nvim",
  ft = "markdown",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  -- Use the bundled install.sh directly. The recommended
  -- `vim.fn["mkdp#util#install"]()` build hook is unreliable through Lazy
  -- (autoload file isn't always sourced before the hook runs) and silently
  -- skips downloading the binary.
  build = "cd app && bash install.sh",
  keys = {
    {
      "<leader>mb",
      "<cmd>MarkdownPreviewToggle<cr>",
      desc = "Markdown preview in browser",
      ft = "markdown",
    },
  },
  init = function()
    vim.g.mkdp_auto_close = 1     -- close the browser tab when leaving the buffer
    vim.g.mkdp_theme = "dark"
  end,
}
