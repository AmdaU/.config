vim.g.mapleader = ";"
vim.keymap.set({"i", "n"}, "<C-s>"     , "<Esc>:w<CR>")
vim.keymap.set({"i", "n"}, "<C-b>"     , "<Esc>:NERDTreeToggle<CR>")
vim.keymap.set({"i", "n"}, "<C-r>"     , "<Esc>:tabnew<CR>")
vim.keymap.set({"i", "n"}, "<C-w>"     , "<Esc>:tabclose<CR>")
vim.keymap.set({"i", "n"}, "<leader>n" , "<Esc>:NERDTreeFocus<CR>")
vim.keymap.set({"i", "n"}, "<leader>r" , "<Esc>:source ~/.config/nvim/init.lua<CR>")
vim.keymap.set({"i", "n"}, "<leader>jf", "<Esc>:JuliaFormatterFormat<CR>")

vim.keymap.set("n", "<leader>sv", ":vsplit")
vim.keymap.set("n", "<leader>sh", ":hsplit")
vim.keymap.set("n", "<leader>ve", ":VimtexErrors<CR>")
vim.keymap.set("n", "<leader>vc", ":VimtexCompile<CR>")
vim.keymap.set("n", "<leader>vv", ":VimtexView<CR>")
vim.keymap.set("n", "<leader>vl", ":VimtexClean<CR>")

--Disable arrow keys
vim.keymap.set({"i", "n"}, "<Up>"   , "<Nop>")
vim.keymap.set({"i", "n"}, "<Down>" , "<Nop>")
vim.keymap.set({"i", "n"}, "<Left>" , "<Nop>")
vim.keymap.set({"i", "n"}, "<Right>", "<Nop>")


