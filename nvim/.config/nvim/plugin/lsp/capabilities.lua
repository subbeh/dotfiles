local ms = vim.lsp.protocol.Methods
local augroup = vim.api.nvim_create_augroup("user.lsp", { clear = true })

-- Opt-in LSP features, keyed by the capability that has to be present for them to
-- work. Completion and signature help are deliberately absent: mini.completion
-- owns both (see plugin/mini.lua).
---@type table<string, fun(bufnr: integer, client: vim.lsp.Client)>
local capabilities = {
  [ms.textDocument_documentHighlight] = function(bufnr)
    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
      group = augroup,
      buffer = bufnr,
      callback = vim.lsp.buf.document_highlight,
      desc = "Highlight references under cursor",
    })
    vim.api.nvim_create_autocmd({ "CursorMoved", "InsertLeave" }, {
      group = augroup,
      buffer = bufnr,
      callback = vim.lsp.buf.clear_references,
      desc = "Clear reference highlights",
    })
  end,
  [ms.textDocument_inlayHint] = function(_, client)
    vim.lsp.inlay_hint.enable(true, { client_id = client.id })
  end,
  [ms.textDocument_documentColor] = function(_, client)
    vim.lsp.document_color.enable(true, { client_id = client.id }, { style = "virtual" })
  end,
  [ms.textDocument_linkedEditingRange] = function(_, client)
    vim.lsp.linked_editing_range.enable(true, { client_id = client.id })
  end,
}

vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup,
  desc = "Enable supported LSP capabilities",
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    for method, setup in pairs(capabilities) do
      if client:supports_method(method, args.buf) then
        setup(args.buf, client)
      end
    end
  end,
})
