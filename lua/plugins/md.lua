return {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
	  keys = {
	    { "<leader>md", "<cmd>MarkdownPreviewToggle<cr>", desc = "Toggle md preview" },
	  },
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"]() end,
}
