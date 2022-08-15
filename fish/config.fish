if status is-interactive

    #fish_vi_key_bindings
    set fish_cursor_default block
    set fish_cursor_insert line
    set fish_cursor_replace_one underscore
    set fish_cursor_visual line

    set -gx VIRTUAL_ENV_DISABLE_PROMPT 1
end

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

alias edit $EDITOR

alias nvim-fg "nvim-qt --nofork"

fish_add_path /$HOME/scripts/inkscape-figures/bin/
fish_add_path /$HOME/.local/bin/
fish_add_path /$HOME/.emacs.d/bin/
fish_add_path /$HOME/.config/scrptis
fish_add_path /$HOME/.local/share/gem/ruby/3.0.0/bin
fish_add_path /$HOME/amda/.cargo/bin

set -Ua fish_user_paths /$HOME/scripts/
export PYENV_ROOT="$HOME/.pyenv"

set fish_greeting

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
