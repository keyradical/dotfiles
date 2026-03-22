return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = "markdown",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {},
  keys = {
    { "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle Markdown render" },
  },
}
