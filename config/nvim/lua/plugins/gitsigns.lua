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
    { "<leader>gp", function()
      local blame = vim.b.gitsigns_blame_line_dict
      if not (blame and blame.sha and blame.sha ~= string.rep("0", 40)) then
        vim.notify("No commit found for this line", vim.log.levels.WARN)
        return
      end
      local sha = blame.sha
      local cwd = vim.fn.expand("%:p:h")
      vim.system(
        { "gh", "api", "repos/{owner}/{repo}/commits/" .. sha .. "/pulls",
          "--jq", ".[0].html_url" },
        { text = true, cwd = cwd },
        function(out)
          local url = (out.stdout or ""):gsub("%s+", "")
          if url == "" then
            vim.schedule(function()
              vim.notify("No PR found for commit " .. sha:sub(1, 7),
                         vim.log.levels.WARN)
            end)
            return
          end
          vim.schedule(function() vim.ui.open(url) end)
        end
      )
    end, desc = "Open PR for current line in browser" },
  },
}
