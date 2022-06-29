if status is-interactive

    #fish_vi_key_bindings
    set fish_cursor_default block
    set fish_cursor_insert line
    set fish_cursor_replace_one underscore
    set fish_cursor_visual line

    function za
        zathura $argv & disown (ps -T| pcregrep -o1 \([0-9]+\).+zathura^\<)
    end
    function mkcd
        mkdir $argv && cd $argv
    end
    function clean_pac
        sudo pacman -Rs (pacman -Qdtq)
    end
    function tmp
        echo y | yay -S $argv > /dev/null; $argv; echo y | yay -R $argv > /dev/null
    end
    alias bp bpython
    alias bt bpytop
    alias tm "tmux -f $HOME/.config/tmux/tmux.conf"
    alias gg "git add -A; git commit -m \"quick commit!\"; git push"
    set -gx VIRTUAL_ENV_DISABLE_PROMPT 1
    #function g
        #"git add -A; git commit -m \"$argv\"; git push"

    #end
    # wal -R > /dev/null
    # cat ~/.cache/wal/sequences &
end

#function edit
    #$EDITOR $argv
#end

alias edit $EDITOR

alias nvim-fg "nvim-qt --nofork"

fish_add_path /$HOME/scripts/inkscape-figures/bin/
fish_add_path /$HOME/.local/bin/
fish_add_path /$HOME/.emacs.d/bin/
fish_add_path /$HOME/.config/scrptis
fish_add_path /$HOME/.local/share/gem/ruby/3.0.0/bin

set -Ua fish_user_paths /$HOME/scripts/
export PYENV_ROOT="$HOME/.pyenv"

set fish_greeting

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
