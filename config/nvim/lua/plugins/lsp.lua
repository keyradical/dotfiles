-- LSP configuration for multiple languages
-- Uses LazyVim's opts pattern for proper integration
-- Supports: C/C++ (clangd), Python (pyright), Mojo, TableGen, MLIR

local modular_bin = vim.env.HOME .. "/Development/modular/.derived/build/bin"

return {
  -- clangd_extensions for enhanced C++ support
  {
    "p00f/clangd_extensions.nvim",
    lazy = true,
    config = function() end,
    opts = {
      inlay_hints = { inline = false },
      ast = {
        role_icons = {
          type = "",
          declaration = "",
          expression = "",
          specifier = "",
          statement = "",
          ["template argument"] = "",
        },
        kind_icons = {
          Compound = "",
          Recovery = "",
          TranslationUnit = "",
          PackExpansion = "",
          TemplateTypeParm = "",
          TemplateTemplateParm = "",
          TemplateParamObject = "",
        },
      },
    },
  },

  -- nvim-lspconfig with LazyVim opts pattern
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- C/C++ configuration (extends LazyVim's clangd extra)
        clangd = {
          keys = {
            { "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C/C++)" },
          },
          capabilities = {
            offsetEncoding = { "utf-16" },
          },
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
          },
          init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,
          },
        },

        -- Python configuration
        pyright = {
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                diagnosticMode = "workspace",
                useLibraryCodeForTypes = true,
                typeCheckingMode = "basic",
              },
            },
          },
        },

        -- Mojo configuration
        mojo = {
          cmd = { modular_bin .. "/mojo-lsp-server" },
          filetypes = { "mojo" },
          single_file_support = true,
        },

        -- TableGen LSP configuration
        tblgen_lsp_server = {
          cmd = { modular_bin .. "/tblgen-lsp-server" },
          filetypes = { "tablegen" },
          single_file_support = true,
        },

        -- MLIR LSP configuration (using modular's mlir server)
        mlir_lsp_server = {
          cmd = { modular_bin .. "/modular-lsp-server" },
          filetypes = { "mlir" },
          single_file_support = true,
        },
      },

      -- Setup hook for clangd to integrate with clangd_extensions
      setup = {
        clangd = function(_, opts)
          local clangd_ext_opts = LazyVim.opts("clangd_extensions.nvim")
          require("clangd_extensions").setup(vim.tbl_deep_extend("force", clangd_ext_opts or {}, { server = opts }))
          return false
        end,
      },
    },
  },

  -- Ensure .mojo files are recognized
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.filetype.add({
        extension = {
          mojo = "mojo",
        },
      })
    end,
  },
}
