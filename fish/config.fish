if status is-interactive
    # Commands to run in interactive sessions can go here

   fish_vi_key_bindings

    function fish_right_prompt -d "Write out the prompt"
        # This shows up as USER@HOST /home/user/ >, with the directory colored
        # $USER and $hostname are set by fish, so you can just use them
        # instead of using `whoami` and `hostname`
        # printf '%s@%s %s%s%s > ' $USER $hostname \
        #    (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
    end
    # Emulates vim's cursor shape behavior
    # Set the normal and visual mode cursors to a block
    set fish_cursor_default block
    # Set the insert mode cursor to a line
    set fish_cursor_insert line
    # Set the replace mode cursor to an underscore
    set fish_cursor_replace_one underscore
    # The following variable can be used to configure cursor shape in
    # visual mode, but due to fish_cursor_default, is redundant here
    set fish_cursor_visual block

    function za
    	zathura $argv & disown (ps -T| pcregrep -o1 \([0-9]+\).+zathura^\<)
    end
    function mkcd
    	mkdir $argv && cd $argv
    end	
    alias bp bpython
    alias bt bpytop
    # wal -R > /dev/null
    cat ~/.cache/wal/sequences &
end

fish_add_path /$HOME/scripts/inkscape-figures/bin/	
fish_add_path /$HOME/.local/bin/
fish_add_path /$HOME/.emacs.d/bin/
set -Ua fish_user_paths /$HOME/scripts/

#set -g theme_color_scheme solarized-dark
#set fish_greeting (fortune)
set fish_greeting

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
