return {
  {
    "nvim-telescope/telescope.nvim",
    version = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Dosya Ara" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "İçerikte Ara (live grep)" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Açık Dosyalar" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Yardım Etiketleri" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          layout_config = {
            horizontal = { width = 0.9 },
            vertical = { width = 0.9 },
          },
          prompt_prefix = "🔍 ",
          selection_caret = "➤ ",
          path_display = { "smart" },
        },
        pickers = {
          find_files = {
            hidden = true,
          },
        },
      })
    end,
  },
}
