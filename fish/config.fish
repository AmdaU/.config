if status is-interactive
    # Commands to run in interactive sessions can go here
   set -g fish_vi_force_cursor 1
   fish_vi_key_bindings
   set fish_cursor_default block
   set fish_cursor_insert line
   set fish_cursor_replace_one underscore
   set fish_cursor_visual line

   function fish_right_prompt -d "Write out the prompt"
   end

   function za
      zathura $argv & disown (ps -T| pcregrep -o1 \([0-9]+\).+zathura^\<)
   end
   function mkcd
      mkdir $argv && cd $argv
   end	
   alias bp bpython
   alias bt bpytop
   alias tm "tmux -f $HOME/.config/tmux/tmux.conf"
   # wal -R > /dev/null
   # cat ~/.cache/wal/sequences &
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
