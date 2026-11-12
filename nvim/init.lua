-----------------------------------------------------------
-- 1. 基础选项
-----------------------------------------------------------
local opt = vim.opt
opt.relativenumber = true
opt.number = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true
opt.wrap = false
opt.cursorline = true
opt.mouse:append("a")
opt.clipboard:append("unnamedplus")
opt.splitright = true
opt.splitbelow = true
opt.ignorecase = true
opt.smartcase = true
opt.termguicolors = true
opt.signcolumn = "yes"

-----------------------------------------------------------
-- 2. 快捷键
-----------------------------------------------------------
local k = vim.keymap
vim.g.mapleader = " "
k.set("i", "jj", "<ESC>")
k.set("v", "J", ":m '>+1<CR>gv=gv")
k.set("v", "K", ":m '<-2<CR>gv=gv")
k.set("n", "<leader>v", "<C-w>v")
k.set("n", "<leader>h", "<C-w>s")
k.set("n", "<leader>n", ":nohl<CR>")
k.set("n", "<leader>e", ":RnvimrToggle<CR>", { silent = true, desc = "Toggle Ranger" })

-----------------------------------------------------------
-- 3. 配色: Gruber Darker Renaissance (透明)
-----------------------------------------------------------
local colorscheme_ok, gdr = pcall(require, "gruber-darker-renaissance")
if colorscheme_ok then
    gdr.setup({ transparent = true })
    vim.cmd.colorscheme("gruber-darker-renaissance")
end

-----------------------------------------------------------
-- 4. Ranger 集成 (rnvimr)
-----------------------------------------------------------
vim.g.rnvimr_enable_ex = 1
vim.g.rnvimr_enable_picker = 1
vim.g.rnvimr_shadow_winblend = 100
vim.g.rnvimr_ranger_cmd = { 'ranger', '--cmd=set show_hidden=true' }

-----------------------------------------------------------
-- 5. 补全: blink.cmp
-----------------------------------------------------------
require('blink.cmp').setup({
    keymap = {
        preset = 'default',
        ['<Tab>'] = { 'accept', 'fallback' },
    },
    appearance = { nerd_font_variant = 'mono' },
    completion = { documentation = { auto_show = true } },
    sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
    fuzzy = { implementation = 'lua' }, -- 强制使用 Lua 避免警告
})
-----------------------------------------------------------
-- 6. LSP (通过 Mason 管理)
-----------------------------------------------------------
-----------------------------------------------------------
-- 6. LSP (Mason 只管理 lua_ls，Go 使用本地 go install)
-----------------------------------------------------------
require("mason").setup()
require("mason-lspconfig").setup({
    automatic_enable = false,        -- Neovim 0.10 必须关闭
    ensure_installed = { "lua_ls" }, -- Mason 只负责 lua_ls，gopls 本地管理
})

local lspconfig = require('lspconfig')
local capabilities = require('blink.cmp').get_lsp_capabilities()

-- 1. 启用 Lua LSP (由 Mason 管理)
lspconfig.lua_ls.setup({ capabilities = capabilities })

-- 2. 启用 Go LSP (由本地 go install 管理)
lspconfig.gopls.setup({
    capabilities = capabilities,
    -- 明确告诉 gopls 处理这些文件类型
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    -- 用 go.mod / go.work / .git 来识别项目根目录
    root_dir = lspconfig.util.root_pattern("go.work", "go.mod", ".git"),
    cmd = { "gopls" },
    settings = {
        gopls = {
            completeUnimported = true, -- 自动补全未导入的包
            usePlaceholders = true,    -- 函数参数占位符
            analyses = {
                unusedparams = true,   -- 提示未使用的参数
            },
        },
    },
})

-- 3. Go 专属缩进设置 (Go 官方强制使用 Tab)
vim.api.nvim_create_autocmd("FileType", {
    pattern = "go",
    callback = function()
        vim.opt_local.expandtab = false
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
    end,
})

-- 4. LSP 快捷键
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local bufnr = args.buf
        local opts = { buffer = bufnr, silent = true }
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    end,
})

-----------------------------------------------------------
-- 7. 搜索: fzf-lua
-----------------------------------------------------------
require('fzf-lua').setup({
    winopts = { height = 0.85, width = 0.85, row = 0.1, col = 0.1 },
})

local fzf = require('fzf-lua')
k.set('n', '<leader>ff', fzf.files, { desc = 'Find files' })
k.set('n', '<leader>fg', fzf.live_grep, { desc = 'Live grep' })
k.set('n', '<leader>fb', fzf.buffers, { desc = 'Find buffers' })
k.set('n', '<leader>fh', fzf.help_tags, { desc = 'Help tags' })
k.set('n', '<leader>fr', fzf.oldfiles, { desc = 'Recent files' })

-----------------------------------------------------------
-- 8. Treesitter (可选: 如果你确认不要，可以删掉这段)
-----------------------------------------------------------
local ts_ok, ts_configs = pcall(require, "nvim-treesitter.configs")
if ts_ok then
    ts_configs.setup({
        ensure_installed = { "lua", "python", "c", "cpp", "javascript", "html", "css", "json", "markdown" },
        auto_install = false,
        highlight = { enable = true },
        indent = { enable = true },
    })
end

-----------------------------------------------------------
-- 9. 自动括号: nvim-autopairs
-----------------------------------------------------------
require('nvim-autopairs').setup({})

-----------------------------------------------------------
-- 10. 代码格式化: conform.nvim
-----------------------------------------------------------
require('conform').setup({
    formatters_by_ft = {
        lua = { "stylua" },
        python = { "black" },
        javascript = { "prettier" },
    },
    format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
    },
})
-- 强制浮动窗口透明 (背景和边框)
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none", fg = "none" })

-- 仅在 Neovim 0.11+ 时设置全局浮窗边框（0.10 不支持此选项）
if vim.fn.has("nvim-0.11") == 1 then
    vim.o.winborder = "none"
end

-----------------------------------------------------------
-- 针对补全菜单和当前行的透明增强
-----------------------------------------------------------
-- 1. 补全菜单背景透明 (Pmenu)
vim.api.nvim_set_hl(0, "Pmenu", { bg = "none" })
-- 补全菜单选中项：建议保留一点半透明底色，否则在当前行上方完全透明会看不清文字
vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#3a3a3a", bold = true })
vim.api.nvim_set_hl(0, "PmenuSbar", { bg = "none" })
vim.api.nvim_set_hl(0, "PmenuThumb", { bg = "#555555" })

-- 2. blink.cmp 专属透明设置
-- (blink.cmp 使用的是 Neovim 原生 Pmenu 高亮，但文档窗口使用了独立的高亮组)
vim.api.nvim_set_hl(0, "BlinkCmpDoc", { bg = "none" })
vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { bg = "none", fg = "none" })
vim.api.nvim_set_hl(0, "BlinkCmpMenu", { bg = "none" })
vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { bg = "none", fg = "none" })

-- 3. 当前行背景透明
-- 完全透明（bg = "none"）可能导致你找不到光标在哪
-- 推荐使用一个极淡的半透明灰色，或者直接去掉背景色只留光标线
vim.api.nvim_set_hl(0, "CursorLine", { bg = "none" }) -- 极淡的灰色
-- 如果你想要绝对透明，把上面一行改成：vim.api.nvim_set_hl(0, "CursorLine", { bg = "none" })
-- 补全菜单和文档之间的分割线/边框透明
vim.api.nvim_set_hl(0, "BlinkCmpDocSeparator", { bg = "none", fg = "none" })
vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { bg = "none", fg = "none" })
vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { bg = "none", fg = "none" })
