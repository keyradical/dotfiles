return {
  "lewis6991/gitsigns.nvim",
  event = "BufReadPost",
  opts = {
    current_line_blame = true,
    current_line_blame_opts = {
      delay = 300,
      virt_text_pos = "eol",
    },
    current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
  },
  keys = {
    { "<leader>gb", function() require("gitsigns").blame_line({ full = true }) end, desc = "Git blame (full)" },
    { "<leader>go", function()
      local blame = vim.b.gitsigns_blame_line_dict
      if blame and blame.sha and blame.sha ~= string.rep("0", 40) then
        vim.fn.jobstart({ "gh", "browse", blame.sha }, { detach = true })
      end
    end, desc = "Open commit in browser" },
  },
}
