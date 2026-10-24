return {
  "shortcuts/no-neck-pain.nvim",
  version = "*",
  cmd = "NoNeckPain",
  keys = {
    { "<leader>np", "<cmd>NoNeckPain<cr>", desc = "Toggle No Neck Pain" },
  },
  opts = {
    width = 240,

    autocmds = {
      -- enableOnVimEnter = true,
      skipEnteringNoNeckPainBuffer = true,
      reloadOnColorSchemeChange = true,
    },
  },
}
