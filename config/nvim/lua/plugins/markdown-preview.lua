return {
  "iamcco/markdown-preview.nvim",
  ft = "markdown",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  build = function()
    vim.fn["mkdp#util#install"]()
  end,
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
