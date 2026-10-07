-- =============================================================================
-- options.lua — Core Neovim Editor Configuration
-- =============================================================================

local opt = vim.opt

-- Line Numbers
opt.number = true               -- Show line numbers
opt.relativenumber = true       -- Relative line numbers for swift vertical jumping

-- True Color & Cursor
opt.termguicolors = true        -- 24-bit TrueColor
opt.cursorline = true           -- Highlight current line
opt.signcolumn = "yes"          -- Always show sign column (prevents text shift on lints)
opt.scrolloff = 8               -- Keep 8 lines above/below cursor when scrolling
opt.sidescrolloff = 8

-- Indentation & Tabs
opt.expandtab = true            -- Convert tabs to spaces
opt.shiftwidth = 4              -- 4 spaces per indent
opt.tabstop = 4                 -- 4 spaces for tabs
opt.softtabstop = 4
opt.smartindent = true          -- Auto indent new lines based on syntax

-- Search & Case Sensitivity
opt.ignorecase = true           -- Case-insensitive search by default
opt.smartcase = true            -- Case-sensitive if pattern contains capital letters
opt.hlsearch = true             -- Highlight search results
opt.incsearch = true            -- Incremental search feedback as you type

-- Performance & Ergonomics
opt.updatetime = 50             -- Faster completion and diagnostics refresh (50ms)
opt.timeoutlen = 300            -- Which-key delay (300ms)
opt.clipboard = "unnamedplus"   -- Sync with Wayland/system clipboard (wl-copy)
opt.splitright = true           -- Put new vertical splits to the right
opt.splitbelow = true           -- Put new horizontal splits below
opt.undofile = true             -- Persistent undo history across editor restarts
opt.mouse = "a"                 -- Enable mouse support across all modes
opt.wrap = false                -- Don't wrap long lines automatically
opt.fillchars = { eob = " " }   -- Hide '~' on empty lines at end of buffer
