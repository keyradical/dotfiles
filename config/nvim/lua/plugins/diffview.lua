return {
  "sindrets/diffview.nvim",
  cmd = {
    "DiffviewOpen",
    "DiffviewClose",
    "DiffviewToggleFiles",
    "DiffviewFocusFiles",
    "DiffviewFileHistory",
    "DiffviewRefresh",
  },
  keys = {
    { "<leader>dv", "<cmd>DiffviewOpen<cr>",                            desc = "Diffview: uncommitted changes" },
    { "<leader>db", "<cmd>DiffviewFileHistory --range=main..HEAD<cr>",  desc = "Diffview: walk commits on this branch (vs main)" },
    { "<leader>df", "<cmd>DiffviewFileHistory %<cr>",                   desc = "Diffview: history of current file" },
    { "<leader>dc", "<cmd>DiffviewClose<cr>",                           desc = "Diffview: close" },
  },
  opts = {
    view = {
      merge_tool = {
        layout = "diff4_mixed",
        disable_diagnostics = true,
        winbar_info = true,
      },
    },
  },
}