vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("config.lazy")

vim.lsp.config("buf_ls", {
  cmd = { "buf", "lsp", "serve" },
  filetypes = { "proto" },
  root_markers = { "buf.yaml", ".git" },
})
vim.lsp.enable("buf_ls")

vim.lsp.config("tombi", {
  cmd = { "tombi", "lsp" },
  filetypes = { "toml" },
  root_markers = { "tombi.toml", "pyproject.toml", "Cargo.toml", ".git" },
})
vim.lsp.enable("tombi")

vim.lsp.config("rumdl", {
  cmd = { "rumdl", "server" },
  filetypes = { "markdown" },
  root_markers = { ".git", ".rumdl.toml" },
  settings = {
    rumdl = {
      lineLength = 100,
    },
  },
})

vim.lsp.enable("rumdl")

vim.lsp.config("codebook", {
    cmd = { "codebook-lsp", "serve" },
    filetypes = {
        "rust",
        "lua",
        "markdown",
        "toml",
        "text",
    },
    root_markers = {
        ".git",
        "codebook.toml",
        ".codebook.toml",
    },
    init_options = {
        checkWhileTyping = false,
        diagnosticSeverity = "hint",
        logLevel = "warn",
    },
    on_attach = function(client)
        local namespace = vim.lsp.diagnostic.get_namespace(client.id)

        vim.diagnostic.config({
            signs = false,        -- no H/W letters in the gutter
            virtual_text = false, -- no diagnostic text after the code
            underline = true,     -- retain subtle underlining
        }, namespace)
    end,
})
vim.lsp.enable("codebook")
vim.lsp.log.set_level("WARN")

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.clipboard = "unnamedplus"
vim.opt.completeopt = { "menuone", "noinsert", "noselect" }
vim.opt.pummaxwidth = 40
vim.opt.updatetime = 250
vim.opt.autoread = true
vim.opt.cmdheight = 0

local inlay_hint_group = vim.api.nvim_create_augroup("inlay-hints-on-reload", { clear = true })
local restore_inlay_hints = {}

vim.api.nvim_create_autocmd("BufReadPre", {
  group = inlay_hint_group,
  callback = function(event)
    if vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }) then
      restore_inlay_hints[event.buf] = true
      -- Old hint columns can be invalid while the new file is being read.
      vim.lsp.inlay_hint.enable(false, { bufnr = event.buf })
    end
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = inlay_hint_group,
  callback = function(event)
    if not restore_inlay_hints[event.buf] then
      return
    end

    -- Let the reload and LSP document synchronization finish before refreshing.
    vim.schedule(function()
      if not restore_inlay_hints[event.buf] then
        return
      end
      restore_inlay_hints[event.buf] = nil
      if vim.api.nvim_buf_is_loaded(event.buf)
        and #vim.lsp.get_clients({ bufnr = event.buf, method = "textDocument/inlayHint" }) > 0 then
        vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
      end
    end)
  end,
})

vim.api.nvim_create_autocmd("BufWipeout", {
  group = inlay_hint_group,
  callback = function(event)
    restore_inlay_hints[event.buf] = nil
  end,
})

local file_watch_group = vim.api.nvim_create_augroup("file-watch", { clear = true })

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "TermClose", "TermLeave" }, {
  group = file_watch_group,
  callback = function()
    if vim.fn.getcmdwintype() == "" and vim.fn.mode() ~= "c" then
      vim.cmd.checktime()
    end
  end,
})

local preferred_colorscheme = "astrodark"
if not pcall(vim.cmd.colorscheme, preferred_colorscheme) then
  vim.cmd.colorscheme("habamax")
end

for _, mode in ipairs({ "i", "c" }) do
  vim.keymap.set(mode, "<M-BS>", "<C-w>", { desc = "Delete previous word" })
  vim.keymap.set(mode, "<M-Del>", "<C-w>", { desc = "Delete previous word" })
  vim.keymap.set(mode, "<D-BS>", "<C-u>", { desc = "Delete to start of line" })
  vim.keymap.set(mode, "<D-Del>", "<C-u>", { desc = "Delete to start of line" })
end

local lsp_attach_group = vim.api.nvim_create_augroup("lsp-attach", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
  group = lsp_attach_group,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if not client then
      return
    end

    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, {
        buffer = args.buf,
        silent = true,
        desc = desc,
      })
    end

    if client:supports_method("textDocument/hover") then
      map("n", "K", vim.lsp.buf.hover, "LSP hover")
    end

    if client:supports_method("textDocument/definition") then
      map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    end

    if client:supports_method("textDocument/declaration") then
      map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
    end

    if client:supports_method("textDocument/references") then
      map("n", "gr", vim.lsp.buf.references, "Find references")
    end

    if client:supports_method("textDocument/implementation") then
      map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
    end

    if client:supports_method("textDocument/typeDefinition") then
      map("n", "gt", vim.lsp.buf.type_definition, "Go to type definition")
    end

    if client:supports_method("textDocument/completion") and not vim.g.use_cmp_completion then
      vim.lsp.completion.enable(true, client.id, args.buf, {
        autotrigger = true,
      })

      map("i", "<C-Space>", function()
        vim.lsp.completion.get()
      end, "Trigger completion")
    end

    if client:supports_method("textDocument/codeAction") then
      map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code actions")
    end

    if client:supports_method("textDocument/rename") then
      map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    end

    if client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
    if client:supports_method("textDocument/documentHighlight", args.buf) then
      local group = vim.api.nvim_create_augroup("lsp-document-highlight-" .. args.buf, { clear = true })

      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = args.buf,
        group = group,
        callback = function(event)
          if #vim.lsp.get_clients({ bufnr = event.buf, method = "textDocument/documentHighlight" }) > 0 then
            vim.lsp.buf.document_highlight()
          end
        end,
      })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
        buffer = args.buf,
        group = group,
        callback = function(event)
          vim.lsp.util.buf_clear_references(event.buf)
        end,
      })

      vim.api.nvim_create_autocmd("LspDetach", {
        buffer = args.buf,
        group = group,
        callback = function(event)
          for _, other in ipairs(vim.lsp.get_clients({ bufnr = event.buf })) do
            if other.id ~= event.data.client_id
              and other:supports_method("textDocument/documentHighlight", event.buf) then
              return
            end
          end

          vim.lsp.util.buf_clear_references(event.buf)
          vim.api.nvim_clear_autocmds({ group = group, buffer = event.buf })
        end,
      })
    end
  end,
})
local rust_format_group = vim.api.nvim_create_augroup("rust-format-on-save", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  group = rust_format_group,
  pattern = "*.rs",
  callback = function(args)
    local clients = vim.lsp.get_clients({
      bufnr = args.buf,
      name = "rust-analyzer",
      method = "textDocument/formatting",
    })
    if #clients == 0 then
      return
    end

    -- Apply edits before writing so the buffer, file and LSP stay in sync.
    vim.lsp.buf.format({
      bufnr = args.buf,
      id = clients[1].id,
      async = false,
      timeout_ms = 3000,
    })
  end,
})
