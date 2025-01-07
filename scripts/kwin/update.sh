#!/bin/bash

systemd-inhibit --what=shutdown:sleep:idle $(kitty -e tmux -u new-session "yes | yay")

