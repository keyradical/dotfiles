return {
  {
    "nvim-mini/mini.nvim",
    version = false,
    event = "InsertEnter",
    config = function()
      require("mini.pairs").setup()
    end,
  },
}