-- =============================================================================
-- which-key.lua — Interactive Cheat-sheet for Keybindings
-- =============================================================================

return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = "modern",
        delay = 250,
        spec = {
            { "<leader>f", group = "Find (Telescope)" },
            { "<leader>s", group = "Split Windows" },
            { "<leader>b", group = "Buffer/Tabs" },
            { "<leader>c", group = "Code / LSP" },
            { "<leader>a", group = "AI Assistant" },
        },
    },
}
