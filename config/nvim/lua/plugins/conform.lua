return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        cpp = { "clang-format" },
        c = { "clang-format" },
        cc = { "clang-format" },
        cxx = { "clang-format" },
        h = { "clang-format" },
        hpp = { "clang-format" },
        mojo = { "mojo-format" },
      },
      formatters = {
        ["clang-format"] = {
          command = "/opt/homebrew/opt/llvm/bin/clang-format",
        },
        ["mojo-format"] = {
          command = "mojo",
          args = { "format", "$FILENAME" },
          stdin = false,
        },
      },
    },
  },
}