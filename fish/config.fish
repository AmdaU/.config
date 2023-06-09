if status is-interactive

    #fish_vi_key_bindings
    set fish_cursor_default block
    set fish_cursor_insert line
    set fish_cursor_replace_one underscore
    set fish_cursor_visual line

    bind yy fish_clipboard_copy
    bind Y fish_clipboard_copy
    bind p fish_clipboard_paste   

    set -gx VIRTUAL_ENV_DISABLE_PROMPT 1
end


# aliases--------------------------------------------------------------------

function mkcd
    mkdir $argv && cd $argv
end
function clean_pac
    sudo pacman -Rs (pacman -Qdtq)
end
function tmp
    echo y | yay -S $argv[1] >/dev/null
    $argv
    echo y | yay -R $argv[1] >/dev/null
end

alias bp bpython
alias bt bpytop
alias tm "tmux -f $HOME/.config/tmux/tmux.conf"
alias gg "git add -A; git commit -m \"quick commit!\"; git push"
alias cat bat
alias ls "ls --hyperlink=auto --color=auto"
alias lg lazygit
alias lsg "git ls-files --exclude-standard | cut -d/ -f1 | uniq"

alias edit $EDITOR

alias nvim-fg "nvim-qt --nofork"


# variables-----------------------------------------------------------------

fish_add_path /$HOME/scripts/inkscape-figures/bin/
fish_add_path /$HOME/.local/bin/
fish_add_path /$HOME/.emacs.d/bin/
fish_add_path /$HOME/.config/scrptis
fish_add_path /$HOME/.local/share/gem/ruby/3.0.0/bin
fish_add_path /$HOME/.cargo/bin
fish_add_path /opt/cuda/bin

set -Ua fish_user_paths /$HOME/scripts/SD
set -Ua fish_user_paths /$HOME/scripts/gpt
set -Ua fish_user_paths /$HOME/scripts/
export PYENV_ROOT="$HOME/.pyenv"

set fish_greeting

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
