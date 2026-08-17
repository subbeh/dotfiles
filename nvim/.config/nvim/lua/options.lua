local opt = vim.opt
local g = vim.g

-- stylua: ignore start
g.mapleader = " "                  --  Use space as the leader key
g.maplocalleader = vim.g.mapleader --  Match the local leader to the leader
g.loaded_perl_provider = 0         --  Disable the unused Perl provider
g.loaded_netrw = 1                 --  Disable netrw in favour of the snacks explorer
g.loaded_netrwPlugin = 1           --  Disable netrw's plugin half as well

opt.autoindent = true                                                                          --  Enable auto-indentation
opt.autoread = true                                                                            --  Enable auto-reload
opt.backup = false                                                                             --  Disable backup files
opt.breakindent = true                                                                         --  Preserve indentation in wrapped text
opt.clipboard = "unnamedplus"                                                                  --  Use system clipboard
opt.cmdheight = 0                                                                              --  Hide command line unless needed
-- opt.complete = "o,F,.,w,b,u,t"                                                              --  Sources for insert-mode <C-n>/<C-p> completion
opt.completeopt = { "menuone", "noselect" }                                                    --  Completion options
-- opt.completeopt = { "menuone", "noselect", "noinsert", "popup", "preinsert" }               --  Completion menu behaviour
opt.conceallevel = 0                                                                           --  Show text normally
opt.confirm = true                                                                             --  Prompt to save changes before closing
opt.cursorline = true                                                                          --  Highlight current line
opt.diffopt = "internal,filler,closeoff,vertical"                                              --  Diff options
-- opt.equalalways = false                                                                     --  Don't auto-resize windows on split/close
opt.expandtab = true                                                                           --  Convert tabs to spaces
opt.fileencoding = "utf-8"                                                                     --  Set file encoding
opt.fillchars:append { stl = " " }                                                             --  Status line fill character
opt.fillchars = opt.fillchars + "eob: "                                                        --  Hide ~ at end of buffer
opt.guicursor = "n-c-sm:block-Cursor,v-ve:block-CursorVisual,i-ci:block-CursorInsert,r-cr-o:block-Cursor" --  Block cursor everywhere; insert/visual get their own colour
opt.hidden = true                                                                              --  Allow switching buffers without saving
opt.hlsearch = true                                                                            --  Highlight search results
opt.ignorecase = true                                                                          --  Case-insensitive searching
opt.inccommand = "nosplit"                                                                     --  Preview substitutions live
-- opt.inccommand = "split"                                                                    --  Live-preview :substitute in a split
opt.joinspaces = false                                                                         --  No double spaces with join
opt.jumpoptions:append("stack")                                                                --  Make the jumplist behave like a stack
opt.laststatus = 3                                                                             --  Global statusline
opt.linebreak = true                                                                           --  Wrap long lines at word boundaries
opt.listchars = { tab = "" }                                                                 --  Render tabs as a vertical dotted line
opt.list = true                                                                                --  Show invisible characters
opt.modeline = true                                                                            --  Honour modelines in files
opt.mouse = "v"                                                                                --  Enable mouse in visual mode
opt.number = true                                                                              --  Show line numbers
opt.numberwidth = 2                                                                            --  Width of line number column
opt.pumblend = 10                                                                              --  Popup menu transparency
opt.pumheight = 10                                                                             --  Maximum number of items in popup menu
opt.relativenumber = true                                                                      --  Show relative line numbers
opt.ruler = false                                                                              --  Hide line and column number
opt.scrollback = 100000                                                                        --  Scrollback buffer size
opt.scrolloff = 8                                                                              --  Lines of context when scrolling
opt.sessionoptions = { "buffers", "curdir", "folds", "help", "tabpages", "winsize", "winpos" } --  What sessions save
opt.shiftround = true                                                                          --  Round indent to multiple of shiftwidth
opt.shiftwidth = 2                                                                             --  Size of indent
opt.shortmess:append("a")                                                                      --  Use short forms for many messages
opt.showcmd = false                                                                            --  Hide command in status line
opt.showmode = false                                                                           --  Hide mode in command line
opt.showtabline = 1                                                                            --  Show tabline when needed
opt.sidescrolloff = 8                                                                          --  Columns of context when scrolling
opt.signcolumn = "yes:1"                                                                       --  Always show a one-cell sign column
opt.smartcase = true                                                                           --  Case-sensitive if search has uppercase
opt.smartindent = true                                                                         --  Smart autoindenting
opt.smoothscroll = true                                                                        --  Scroll by screen line for wrapped lines
opt.softtabstop = -1                                                                           --  Make <Tab> insert 'shiftwidth' worth of spaces
opt.splitbelow = true                                                                          --  Open new splits below
opt.splitkeep = "screen"                                                                       --  Keep text on screen when splitting
opt.splitright = true                                                                          --  Open new splits to the right
opt.swapfile = false                                                                           --  Disable swap files
opt.switchbuf = { "useopen", "uselast" }                                                       --  Reuse open windows when switching buffers
opt.tabstop = 2                                                                                --  Spaces per tab
opt.termguicolors = true                                                                       --  Enable 24-bit RGB colors
opt.timeoutlen = 1000                                                                          --  Time to wait for mapped sequence
opt.title = true                                                                               --  Set window title
opt.undofile = true                                                                            --  Enable persistent undo
opt.undolevels = 500                                                                           --  Maximum number of undos kept
opt.updatetime = 100                                                                           --  Faster completion
opt.updatetime = 500                                                                           --  Idle delay (ms) before CursorHold / swap write
opt.wildignore:append({ "*.o", "*.rej", "*.so", "*~", "*.pyc", "*pycache*", "Cargo.lock" })    --  Ignore these in file completion
-- opt.wildmode = { "longest:full", "full", "noselect" }                                          --  Command-line completion behaviour
opt.winborder = "single"                                                                       --  Default border for floating windows
opt.wrap = false                                                                               --  Disable line wrap

vim.cmd("set whichwrap+=<,>,[,],h,l") --  Allow these keys to move across line ends
vim.cmd([[set iskeyword+=-]])         --  Treat dashes as part of a word
