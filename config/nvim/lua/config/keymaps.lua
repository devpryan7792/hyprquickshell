-- =============================================================================
-- keymaps.lua — Intuitive Spacebar Leader Keybindings
-- =============================================================================

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- ── File & Session Operations ───────────────────────────────────────────────
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit window" })
map("n", "<leader>Q", "<cmd>qa!<CR>", { desc = "Force quit all" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- ── Buffer (Tab) Navigation ─────────────────────────────────────────────────
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next open buffer/tab" })
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous open buffer/tab" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Close buffer/tab" })

-- ── Window Splits ───────────────────────────────────────────────────────────
map("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Split window vertically" })
map("n", "<leader>sh", "<cmd>split<CR>", { desc = "Split window horizontally" })
map("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
map("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

-- ── Line Manipulation ───────────────────────────────────────────────────────
-- Move lines up/down in Visual mode
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move lines down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move lines up" })

-- Keep cursor centered when scrolling
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
map("n", "n", "nzzzv", { desc = "Next search match and center" })
map("n", "N", "Nzzzv", { desc = "Previous search match and center" })
