local function rust_analyzer_cmd()
  if vim.fn.executable('rustup') == 0 then
    return { 'rust-analyzer' }
  end

  local default_toolchain = vim.system({ 'rustup', 'default' }, { text = true }):wait()
  local toolchain = (default_toolchain.stdout or ''):match('^(%S+)')

  if toolchain then
    local rust_analyzer = vim.system(
      { 'rustup', 'which', 'rust-analyzer', '--toolchain', toolchain },
      { text = true }
    ):wait()
    local path = vim.trim(rust_analyzer.stdout or '')

    if rust_analyzer.code == 0 and path ~= '' then
      return { path }
    end
  end

  return { 'rust-analyzer' }
end

return {
  {
    'rust-lang/rust.vim',
    init = function()
      -- The LSP BufWritePre hook owns automatic formatting.
      vim.g.rustfmt_autosave = 0
      vim.g.rustfmt_autosave_if_config_present = 0
    end,
  },
  {
    'mrcjkb/rustaceanvim',
    version = '^8', -- Recommended
    lazy = false, -- This plugin is already lazy
    init = function()
      local analyzer_settings = {
        cargo = { features = 'all' },
      }
      if vim.g.rustfmt_override_command then
        analyzer_settings.rustfmt = {
          overrideCommand = vim.g.rustfmt_override_command,
        }
      end

      ---@type rustaceanvim.Opts
      vim.g.rustaceanvim = {
        server = {
          cmd = rust_analyzer_cmd,
          default_settings = {
            ['rust-analyzer'] = analyzer_settings,
          },
        },
      }
    end,
  },
}
