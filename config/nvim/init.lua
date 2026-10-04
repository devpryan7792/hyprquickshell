-- =============================================================================
-- ~/.config/nvim/init.lua — Modern Neovim with Animated Smear Cursor & Eye Candy
-- =============================================================================

-- ── Leader Key ───────────────────────────────────────────────────────────────
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ── General Editor Options ───────────────────────────────────────────────────
local opt = vim.opt
opt.number = true               -- Show line numbers
opt.relativenumber = true       -- Relative line numbers for swift jumping
opt.termguicolors = true        -- 24-bit TrueColor in terminal
opt.cursorline = true           -- Highlight current line
opt.signcolumn = "yes"          -- Always show sign column
opt.scrolloff = 8               -- Keep 8 lines above/below cursor
opt.sidescrolloff = 8

-- Indentation & Tabs
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true

-- Search & Case
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Performance & Ergonomics
opt.updatetime = 50             -- Faster completion and diagnostics
opt.timeoutlen = 300
opt.clipboard = "unnamedplus"   -- Sync with system clipboard (Wayland wl-copy)
opt.splitright = true
opt.splitbelow = true
opt.undofile = true             -- Persistent undo history across sessions
opt.mouse = "a"                 -- Enable mouse support

-- ── Bootstrap Lazy.nvim Package Manager ──────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- ── Plugins ──────────────────────────────────────────────────────────────────
require("lazy").setup({
    -- 1. Animated Smear Cursor (The iconic "zup-zup" smooth trailing cursor)
    {
        "sphamba/smear-cursor.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            stiffness = 0.6,
            trailing_stiffness = 0.45,
            anticipation = 0.2,
            smear_between_buffers = true,
            smear_between_neighbor_lines = true,
            smear_horizontally = true,
            smear_vertically = true,
            smear_diagonally = true,
            smear_insert_mode = true,
            vertical_bar_cursor_insert_mode = true,
            scroll_buffer_space = true,
        },
    },
}, {
    ui = {
        border = "rounded",
    },
})

-- ── Keybindings ──────────────────────────────────────────────────────────────
local map = vim.keymap.set

-- Clear search highlight on Esc
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Better window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Quick save & quit
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })

-- Move lines up/down in visual mode with Alt+j / Alt+k
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move up" })

-- ── Dynamic Rice Theming (Auto-synced with Quickshell & Hyprland) ────────────
pcall(require, "colors")
