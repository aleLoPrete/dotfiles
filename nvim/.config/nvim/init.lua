-- 1. SET LEADER KEY
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- BOOTSTRAPPING LAZY.NVIM
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 2. PLUGINS
require("lazy").setup({
  -- Themes
  { 'catppuccin/nvim', name = "catppuccin", priority = 1000 },
  { 'maxmx03/solarized.nvim', priority = 1000 },

  -- File Tree
  'nvim-tree/nvim-tree.lua',

  -- Status Line
  'nvim-lualine/lualine.nvim',

  -- Buffer Line (VSCode-style tabs)
  {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      require("bufferline").setup({
        options = {
          mode = "buffers", -- Show buffers instead of tabs
          separator_style = "slant", -- VSCode-like style
          always_show_bufferline = true,
          show_buffer_close_icons = true,
          show_close_icon = false,
          color_icons = true,
          diagnostics = "nvim_lsp", -- Show LSP diagnostics
          offsets = {
            {
              filetype = "NvimTree",
              text = "File Explorer",
              highlight = "Directory",
              text_align = "left"
            }
          },
        }
      })
    end
  },

  -- Fuzzy Finder (Telescope)
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.5',
    dependencies = { 'nvim-lua/plenary.nvim' }
  },

  -- Tmux Navigation
  'christoomey/vim-tmux-navigator',

  -- Better Buffer Delete
  'moll/vim-bbye',

  -- Smooth Scrolling
  {
    'karb94/neoscroll.nvim',
    config = function()
      require('neoscroll').setup({
        mappings = {'<C-u>', '<C-d>', '<C-b>', '<C-f>', '<C-y>', '<C-e>', 'zt', 'zz', 'zb'},
        hide_cursor = true,
        stop_eof = true,
        respect_scrolloff = true,
        cursor_scrolls_alone = true,
      })
    end
  },

  -- Zen Mode (centered writing)
  {
    "folke/zen-mode.nvim",
    opts = {
      window = {
        width = 120,
      },
    },
    keys = {
      { "<leader>z", "<cmd>ZenMode<cr>", desc = "Toggle Zen Mode" },
    },
  },

  -- Markdown Rendering
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    ft = { 'markdown' }, -- Only load for markdown files
    config = function()
      require('render-markdown').setup({})
    end
  },

  -- GIT INTEGRATION (NEW
  {
      "kdheepak/lazygit.nvim",
      dependencies = {
          "nvim-lua/plenary.nvim",
      },
  },
  {
      "lewis6991/gitsigns.nvim", -- Adds the little colored bars on the left
      config = function()
          require('gitsigns').setup()
      end
  },

-- TREESITTER
  {
      'nvim-treesitter/nvim-treesitter',
      build = ':TSUpdate', -- Command run after installation
      config = function()
          require('nvim-treesitter.configs').setup({
              -- A list of parser names, you will install them when you run :Lazy
              ensure_installed = { "c", "lua", "vim", "vimdoc", "javascript", "typescript", "markdown", "yaml", "python"},

              -- Install parsers synchronously (good for initial setup)
              sync_install = false,

              highlight = {
                  enable = true,    -- Enable syntax highlighting
                  disable = {}, -- Enable for all languages including markdown
              },
              indent = { enable = true }, -- Enable smart auto-indentation
          })
      end
  },
-- LSP & Completion

-- LSP & Completion (Unified Block)
  {
      'neovim/nvim-lspconfig',
      dependencies = {
          'williamboman/mason.nvim',
          'williamboman/mason-lspconfig.nvim',
      },
      config = function()
          -- 1. Setup Mason (The Installer)
          require("mason").setup()

          -- 2. Setup Mason-LSPConfig (The Bridge)
          local mason_lspconfig = require("mason-lspconfig")
          
          mason_lspconfig.setup({
              -- LSP servers to install automatically
              ensure_installed = { "lua_ls", "pyright", "clangd", "yamlls" },
          })

          -- 3. Setup General LSP Settings
          local lspconfig = require("lspconfig")
          local capabilities = require('cmp_nvim_lsp').default_capabilities()

          local on_attach = function(client, bufnr)
              local bufopts = { noremap=true, silent=true, buffer=bufnr }
              vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
              vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
              vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
              vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
              vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
              vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
          end

          -- 4. Automatic Server Setup (The Fix)
          -- This function automatically sets up any server Mason installs.
          -- It handles the loop for you, avoiding the "deprecation" warning interactions.
          if mason_lspconfig.setup_handlers then
              mason_lspconfig.setup_handlers({
                  function(server_name)
                      lspconfig[server_name].setup({
                          on_attach = on_attach,
                          capabilities = capabilities,
                      })
                  end,
              })
          else
              -- Fallback just in case (should not be reached)
              print("Mason-LSPConfig setup_handlers not found")
          end
      end
  },

{
    'hrsh7th/nvim-cmp', -- The main completion engine
    dependencies = {
        'hrsh7th/cmp-nvim-lsp', -- LSP source
        'hrsh7th/cmp-buffer',   -- Buffer word source
        'hrsh7th/cmp-path',     -- File path source
        'L3MON4D3/LuaSnip',     -- Snippet engine
        'saadparwaiz1/cmp_luasnip', -- Snippet source
    },
    config = function()
        local cmp = require('cmp')
        local luasnip = require('luasnip')

        cmp.setup({
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept selected item
                ['<Tab>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item()
                    elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    else
                        fallback()
                    end
                end, { 'i', 's' }),
            }),
            sources = cmp.config.sources({
                { name = 'nvim_lsp' },
                { name = 'luasnip' }, -- For snippets
                { name = 'buffer' },
                { name = 'path' },
            })
        })
    end
}
})

-- 3. CONFIGURATION
require("catppuccin").setup({ flavour = "mocha" })
vim.cmd("colorscheme catppuccin")
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a' -- Enable mouse support for smooth scrolling
vim.opt.scrolloff = 999 -- Keep cursor line centered on screen
vim.opt.cursorline = true -- Enable cursor line

-- Customize cursor line to show only underline
vim.api.nvim_set_hl(0, 'CursorLine', { underline = true, bg = 'NONE' })

-- Setup Lualine
require('lualine').setup()

-- Setup NvimTree
require("nvim-tree").setup({
  view = { width = 30 },
  filters = {
    git_ignored = false,  -- Show gitignored files
  },
  actions = {
    open_file = {
      quit_on_open = false,  -- Keep tree open
      window_picker = {
        enable = true,  -- Enable window picker
      },
    },
  },
})

-- 4. SIMPLE SHORTCUTS

-- > File Explorer (Space + e)
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = 'Toggle Explorer' })

-- > Find Files (Space + f)
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>f', builtin.find_files, { desc = 'Telescope Find Files' })

-- > Find Text in Files (Space + g)
vim.keymap.set('n', '<leader>g', builtin.live_grep, { desc = 'Telescope Live Grep' })

-- > Search in Current Buffer (Space + /)
vim.keymap.set('n', '<leader>/', builtin.current_buffer_fuzzy_find, { desc = 'Fuzzy Find in Current Buffer' })

-- > Clear Highlight after search (Space + h)
vim.keymap.set('n', '<leader>h', ':nohl<CR>', { desc = 'Clear Search Highlight' })

-- Space + b to list open buffers
vim.keymap.set('n', '<leader>b', builtin.buffers, { desc = 'Telescope Buffers' })

-- > GIT SHORTCUTS (NEW)
-- Space + gg to open Lazygit
vim.keymap.set('n', '<leader>gg', ':LazyGit<CR>', { desc = 'Toggle LazyGit' })

-- > BUFFER NAVIGATION (Modern VSCode-style)
-- Shift+H / Shift+L to cycle through buffers (most popular convention)
vim.keymap.set('n', '<S-h>', ':BufferLineCyclePrev<CR>', { desc = 'Previous Buffer', silent = true })
vim.keymap.set('n', '<S-l>', ':BufferLineCycleNext<CR>', { desc = 'Next Buffer', silent = true })
-- Space + x to close current buffer (VSCode-like)
vim.keymap.set('n', '<leader>x', ':Bdelete<CR>', { desc = 'Close Buffer', silent = true })
-- Space + X to close all other buffers
vim.keymap.set('n', '<leader>X', ':BufferLineCloseOthers<CR>', { desc = 'Close Other Buffers', silent = true })

-- > THEME TOGGLE (Space + t)
local theme_dark = true
local function toggle_theme()
  theme_dark = not theme_dark
  if theme_dark then
    vim.o.background = "dark"
    require("catppuccin").setup({ flavour = "mocha" })
    vim.cmd("colorscheme catppuccin")
  else
    vim.o.background = "light"
    require("solarized").setup({ theme = "neo" })
    vim.cmd("colorscheme solarized")
  end
end
vim.keymap.set('n', '<leader>tt', toggle_theme, { desc = 'Toggle Dark/Light Theme' })

-- > CENTERED SCROLLING
-- Note: Neoscroll plugin handles smooth scrolling for <C-d> and <C-u>
