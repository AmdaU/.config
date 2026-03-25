#!/bin/bash

# The name for your tmux session
SESSION="monitoring"

# -----------------------------

# Kill any old session with the same name to ensure a fresh start
tmux kill-session -t $SESSION 2>/dev/null

# Create a new detached session, running bpytop with its full path.
tmux new-session -d -s $SESSION "bpytop"

# Split the window horizontally. This targets the current session's main window.
tmux split-window -v -p 30 -t $SESSION

# Send the gpustat command (using full paths) to the "next" pane.
# The '.+' means we don't have to guess the pane index number.
tmux respawn-pane -k "gpustat -c -i 1 --no-header --show-power"

# Select the "previous" pane (bpytop) to make it active.
tmux select-pane -t $SESSION:.-

# Attach to the session.
tmux attach-session -t $SESSION
