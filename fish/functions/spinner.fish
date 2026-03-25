function spinner --description 'Run cmd1 && cmd2 && ... with a spinner per step'
	if test (count $argv) -lt 1
		echo "usage: spinner 'cmd1 && cmd2 && cmd3'" >&2
		return 2
	end

	set -l chain $argv[1]

	set -l parts (string split "&&" -- $chain)
	set -l cmds
	for p in $parts
		set -l t (string trim -- $p)
		if test -n "$t"
			set -a cmds "$t"
		end
	end

	if test (count $cmds) -eq 0
		echo "spinner: no commands found" >&2
		return 2
	end

	set -l frames ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
	set -l errfile (mktemp)
	set -l rcfile (mktemp)
	set -g __spinner_pid 0

	function __spinner_cleanup --on-signal INT --inherit-variable errfile --inherit-variable rcfile
		if test $__spinner_pid -ne 0; and kill -0 $__spinner_pid 2>/dev/null
			kill $__spinner_pid 2>/dev/null
			wait $__spinner_pid 2>/dev/null
		end
		printf "\r\033[2K" >/dev/tty
		rm -f $errfile $rcfile
		set -e __spinner_pid
		functions -e __spinner_cleanup
	end

	for cmd in $cmds
		set -l title (string shorten -m 60 -- $cmd)
		set -l frame_idx 1
		set -l start_time (date +%s.%N)

		echo 1 >$rcfile
		fish -c "$cmd; echo \$status >$rcfile" >/dev/null 2>$errfile &
		set -g __spinner_pid $last_pid

		while true
			kill -0 $__spinner_pid 2>/dev/null; or break
			set -l elapsed (math (date +%s.%N) - $start_time)
			set -l mins (math -s0 "$elapsed / 60")
			set -l secs (math -s0 "$elapsed % 60")
			set -l time_str (printf "%02d:%02d" $mins $secs)

			printf "\r\033[2K%s%s%s %s%s%s %s" (set_color magenta) $frames[$frame_idx] (set_color normal) (set_color brblack) $time_str (set_color normal) "$title" >/dev/tty
			set frame_idx (math "$frame_idx % 10 + 1")
			sleep 0.08
		end

		wait $__spinner_pid 2>/dev/null
		set -g __spinner_pid 0
		set -l rc (string trim -- (cat $rcfile))
		test -z "$rc"; and set rc 1

		set -l elapsed (math (date +%s.%N) - $start_time)
		set -l time_str
		if test (math -s0 "$elapsed") -eq 0
			set -l ms (math -s0 "$elapsed * 1000")
			set time_str (printf "%03dms" $ms)
		else
			set -l mins (math -s0 "$elapsed / 60")
			set -l secs (math -s0 "$elapsed % 60")
			set time_str (printf "%02d:%02d" $mins $secs)
		end

		printf "\r\033[2K" >/dev/tty
		if test "$rc" -ne 0
			echo (set_color red)"✗ "(set_color brblack)$time_str(set_color normal)" $title" >&2
			if test -s $errfile
				cat $errfile >&2
			end
			rm -f $errfile $rcfile
			set -e __spinner_pid
			functions -e __spinner_cleanup
			return $rc
		end
		echo (set_color green)"✓ "(set_color brblack)$time_str(set_color normal)" $title" >&2
		: >$errfile
	end

	rm -f $errfile $rcfile
	set -e __spinner_pid
	functions -e __spinner_cleanup
	return 0
end
