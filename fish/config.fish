if status is-interactive
    fish_vi_key_bindings
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
#alias tm "tmux -f $HOME/.config/tmux/tmux.conf"
function gg
    set -l msg "quick commit!"
    if test (count $argv) -gt 0
        set msg (string join " " $argv)
    end
    git add -A && git commit -m "$msg" && git push
end
#alias cat bat
alias ls "ls --hyperlink=auto --color=auto"
alias lg lazygit
alias lsg "git ls-files --exclude-standard | cut -d/ -f1 | uniq"
alias tm "tmux -u"
alias julia_itensors="julia --sysimage ~/.julia/sysimages/sys_itensors.so -e \"using ITensors\" -i "

alias edit $EDITOR

alias nvim-fg "nvim-qt --nofork"
# A versatile function to launch a tmux monitoring session
# Usage:
#   monitor                  (runs on the local machine)
#   monitor user@hostname    (runs on a remote machine via SSH)
function monitor
    # Define the block of tmux commands. This is used for both local and remote.
    set -l tmux_commands 'bash -c "
        SESSION=\"monitoring\";
        tmux kill-session -t \$SESSION 2>/dev/null;
        tmux new-session -d -s \$SESSION \"bpytop\";
        tmux split-window -v -p 30;
        tmux respawn-pane -k \"gpustat -c -i 1 --no-header --show-power\";
        tmux select-pane -t :.-;
        tmux attach-session -t \$SESSION;"
    '

    # Check if an argument (the remote host) was provided.
    # 'test -n' checks if the string is not empty.
    if test -n "$argv[1]"
        # --- REMOTE ---
        # An argument was given, so run via SSH.
        set -l remote_host "$argv[1]"
        echo "Connecting to $remote_host to start monitoring session..."
        ssh -t "$remote_host" "$tmux_commands"
    else
        # --- LOCAL ---
        # No argument was given, so run locally.
        # 'eval' executes the string as if it were typed in the terminal.
        echo "Starting local monitoring session..."
        eval $tmux_commands
    end
end
function spin --description 'Run a fish commandline with a spinner (via gum)'
    if not command -q gum
        echo "spin: gum not installed (pacman -S gum)" >&2
        return 127
    end

    if test (count $argv) -eq 0
        echo "usage: spin 'cmd1; and cmd2; ...'" >&2
        return 2
    end

    gum spin --title "Running..." -- fish -c "$argv[1]"
end
# variables-----------------------------------------------------------------

#fish_add_path /$HOME/scripts/inkscape-figures/bin/
#fish_add_path /$HOME/scripts/bspwm
#fish_add_path /$HOME/.local/bin/
fish_add_path /$HOME/.emacs.d/bin/
fish_add_path /$HOME/.local/share/gem/ruby/3.0.0/bin
fish_add_path /$HOME/.cargo/bin
fish_add_path /opt/cuda/bin

set -Ua fish_user_paths /$HOME/.config/scripts/SD
set -Ua fish_user_paths /$HOME/.config/scripts/gpt
set -Ua fish_user_paths /$HOME/.config/scripts/bspwm
set -Ua fish_user_paths /$HOME/.config/scripts/
set -gx PYENV_ROOT $HOME/.pyenv
fish_add_path $PYENV_ROOT/bin

set fish_greeting

pyenv init - --no-rehash | source
pyenv virtualenv-init - | source
