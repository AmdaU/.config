#!/usr/bin/env python3
"""RealtimeSTT dictation daemon.

VAD-triggered (Silero) inference via faster-whisper.
Each completed utterance is typed into the active window via wtype.

Usage: run via dictation-rt-toggle.sh; kill with SIGTERM.

Voice commands (entire utterance, case-insensitive):
  "scratch that" / "delete that"       — delete last typed utterance (repeat to undo more)
  "scratch all" / "undo all"           — delete all typed text since last voice command
  "verbatim on"                        — enter verbatim mode (only text typed, no commands)
  "verbatim off"                       — exit verbatim mode
  "toggle verbatim mode"               — toggle verbatim mode (works in all modes)
  "command mode on"                    — enter command mode (only commands; unrecognised input
                                         triggers a notification instead of being typed)
  "command mode off"                   — exit command mode
  "toggle command mode"                — toggle command mode (works in all modes)
  "toggle normal mode"                 — return to normal mode from verbatim or command mode
  "[key]" only (entire utterance)      — same as "press [key]" when the transcript is
      exactly a known key name, e.g. "enter" / "escape" / "page up"
  "[modifier]-[key]" / "[modifier] [key]" — chord without "press", e.g. "ctrl-c", "alt f4"
  "press [modifiers] [key]"            — send a key event, e.g.:
      "press enter" / "press escape" / "press F5"
      "press control C" / "press alt F4" / "press control shift T"
  "go to workspace [N]"               — switch Hyprland workspace (1–10, or spoken)
  "switch to workspace [N]"           — same
  "move window to workspace [N]"      — move focused window to workspace
  "close window" / "close the window" — close focused window (Hyprland killactive)
  "dictation help"                    — open wofi menu listing these commands
  "launch|open|start <name>"          — run a whitelisted app (see ~/.config/dictation/voice-launch.json)
  "dictation off" / "dictation of"     — stop dictation (runs dictation-rt-toggle.sh; Whisper
      often says "of" for "off"); also "dication off", "stop dictation", etc.
  "again"                             — repeat the last command (not text)
  "space" (in text)                   — insert a literal space character, e.g.
      "space slash clear" → " /clear"
"""
import json
import re
import signal
import subprocess
import sys
from datetime import datetime
from pathlib import Path

LOG = Path.home() / ".local/share/dictation-results.log"
TOGGLE_SCRIPT = Path.home() / ".config/scripts/dictation/dictation-rt-toggle.sh"
VOICE_LAUNCH_JSON = Path.home() / ".config/dictation/voice-launch.json"

# Lines shown in the wofi “dictation help” menu (keep in sync with voice handlers below).
_HELP_MENU_LINES = (
    "again — repeat last voice command",
    "scratch / delete / undo that — remove last typed utterance",
    "scratch / undo all — remove all typed text since last voice command",
    "verbatim on / off — bypass all commands, type everything literally",
    "toggle verbatim mode — toggle verbatim on/off (works in all modes)",
    "command mode on / off — only commands accepted; unrecognised input notified",
    "toggle command mode — toggle command mode on/off (works in all modes)",
    "toggle normal mode — return to normal mode from verbatim or command",
    "dictation help — show this menu (wofi)",
    "dictation off — stop dictation",
    "key name alone — enter, escape, F5, page up, c, …",
    "chord without “press” — ctrl c, ctrl-c, alt f4, control shift t",
    "press … — press control C, press alt F4, press escape",
    "workspace N — switch workspace (1–10 or one … ten)",
    "go to workspace N / switch to workspace N — same",
    "move window to workspace N — move focused window",
    "next window / switch window / alt tab — cycle to next window",
    "close window — close focused window (killactive)",
    "launch / open / start <name> — app from voice-launch.json whitelist",
    'space (in text) — insert literal space, e.g. "space slash clear" → " /clear"',
)

# ── Spoken punctuation ────────────────────────────────────────────────────────
# Order matters: multi-word phrases before single words.
_PUNCT = [
    (r"\bnew paragraph\b",       "\n\n"),
    (r"\bnew line\b",            "\n"),
    (r"\bdot dot dot\b",         "..."),
    (r"\bellipsis\b",            "..."),
    (r"\bem dash\b",             "—"),
    (r"\bexclamation point\b",   "!"),
    (r"\bexclamation mark\b",    "!"),
    (r"\bquestion mark\b",       "?"),
    (r"\bopen parenthesis\b",    "("),
    (r"\bopen paren\b",          "("),
    (r"\bclose parenthesis\b",   ")"),
    (r"\bclose paren\b",         ")"),
    (r"\bsemicolon\b",           ";"),
    (r"\bcolon\b",               ":"),
    (r"\bbackslash\b",           "\\\\"),
    (r"\bslash\b",               "/"),
]
_PUNCT_RE = [(re.compile(p, re.IGNORECASE), s) for p, s in _PUNCT]


def apply_spoken_punctuation(text: str) -> str:
    for pattern, symbol in _PUNCT_RE:
        text = pattern.sub(symbol, text)
    text = re.sub(r" +([.,!?:;])", r"\1", text)   # space before punctuation
    text = re.sub(r" +\n",         "\n",   text)   # space before newline
    text = re.sub(r"\n +",         "\n",   text)   # space after newline
    text = re.sub(r"\( +",         "(",    text)   # space after open paren
    text = re.sub(r" +\)",         ")",    text)   # space before close paren
    return text.strip()


def clean_whisper_artifacts(text: str) -> str:
    """Remove punctuation artifacts Whisper hallucinates at chunk boundaries."""
    text = re.sub(r"^[,;:]+\s*", "", text)         # leading commas/semicolons/colons
    text = re.sub(r",\s*\.", ".", text)             # ,. → .
    text = re.sub(r"\.\s*,", ".", text)             # ., → .
    text = re.sub(r",{2,}", ",", text)              # multiple commas → one
    text = re.sub(r"\.{2}(?!\.)", ".", text)        # .. → . (but keep ...)
    return text.strip()


# ── Key press command ─────────────────────────────────────────────────────────

# Spoken modifier names → wtype modifier flag
_MOD_MAP = {
    "control": "ctrl", "ctrl": "ctrl",
    "shift": "shift",
    "alt": "alt", "option": "alt",
    "super": "logo", "windows": "logo", "win": "logo", "meta": "logo",
}

# Spoken key names → XKB key name used by wtype
_KEY_MAP: dict[str, str] = {
    # Navigation
    "enter": "Return", "return": "Return",
    "escape": "Escape", "esc": "Escape",
    "tab": "Tab",
    "backspace": "BackSpace", "back space": "BackSpace",
    "delete": "Delete", "del": "Delete",
    "insert": "Insert",
    "home": "Home",
    "end": "End",
    "page up": "Page_Up", "pageup": "Page_Up",
    "page down": "Page_Down", "pagedown": "Page_Down",
    "up": "Up", "down": "Down", "left": "Left", "right": "Right",
    # Whitespace
    "space": "space", "spacebar": "space",
    # Lock / misc
    "caps lock": "Caps_Lock", "capslock": "Caps_Lock",
    "print screen": "Print", "printscreen": "Print",
    "scroll lock": "Scroll_Lock",
    "pause": "Pause",
    "num lock": "Num_Lock",
    # Function keys F1–F12
    **{f"f{i}": f"F{i}" for i in range(1, 13)},
    # Letters a–z (wtype accepts lowercase)
    **{chr(c): chr(c) for c in range(ord("a"), ord("z") + 1)},
    # Digits
    **{str(i): str(i) for i in range(10)},
    # Common symbols
    "minus": "minus", "dash": "minus", "hyphen": "minus",
    "equals": "equal", "equal": "equal",
    "slash": "slash",   "/": "slash",
    "backslash": "backslash", "\\": "backslash",
    "grave": "grave", "backtick": "grave",
    "bracket left": "bracketleft", "left bracket": "bracketleft",
    "bracket right": "bracketright", "right bracket": "bracketright",
    "apostrophe": "apostrophe", "quote": "apostrophe",
}

# Matches: "press [optional modifiers] [key]"
_MOD_WORDS = "|".join(_MOD_MAP)
_CMD_KEY_RE = re.compile(
    rf"^\s*press\s+(?P<mods>(?:(?:{_MOD_WORDS})\s+)*)"
    rf"(?P<key>.+?)[.!?]?\s*$",
    re.IGNORECASE,
)


def _normalize_key_utterance(text: str) -> str:
    """Strip; remove trailing . ! ?; lowercase (matches bare key and press-key tail)."""
    t = text.strip()
    t = re.sub(r"[.!?]+\s*$", "", t).strip()
    return t.lower()


def _send_wtype_key(mods: list[str], wtype_key: str) -> None:
    args: list[str] = []
    for mod in mods:
        args += ["-M", mod]
    args += ["-k", wtype_key]
    for mod in mods:
        args += ["-m", mod]
    subprocess.run(["wtype"] + args, check=False)

    label = "+".join(mods + [wtype_key])
    with LOG.open("a") as f:
        f.write(f"[{datetime.now().strftime('%H:%M:%S')}] [Key: {label}]\n")


def try_key_press(text: str) -> bool:
    """If text is a 'press [key]' command, execute it and return True."""
    m = _CMD_KEY_RE.match(text)
    if not m:
        return False

    mods = [_MOD_MAP[w.lower()] for w in m.group("mods").split() if w]
    key_spoken = m.group("key").strip().lower()
    key = _KEY_MAP.get(key_spoken)
    if key is None:
        return False  # unknown key — fall through to normal typing

    _send_wtype_key(mods, key)
    return True


def try_compact_chord(text: str) -> bool:
    """Match modifier+key without 'press': 'ctrl-c', 'ctrl c', 'control shift t'."""
    spoken = _normalize_key_utterance(text)
    if not spoken:
        return False
    parts = [p for p in re.split(r"[\s-]+", spoken) if p]
    if len(parts) < 2:
        return False

    key: str | None = None
    mods_tokens: list[str]

    cand2 = f"{parts[-2]} {parts[-1]}"
    if cand2 in _KEY_MAP:
        key = _KEY_MAP[cand2]
        mods_tokens = parts[:-2]
    elif parts[-1] in _KEY_MAP:
        key = _KEY_MAP[parts[-1]]
        mods_tokens = parts[:-1]
    else:
        return False

    if not mods_tokens:
        return False

    mods: list[str] = []
    for w in mods_tokens:
        m = _MOD_MAP.get(w)
        if m is None:
            return False
        mods.append(m)

    _send_wtype_key(mods, key)
    return True


def try_bare_key_press(text: str) -> bool:
    """If the whole utterance is exactly a known key name, send it (no 'press' prefix)."""
    spoken = _normalize_key_utterance(text)
    if not spoken:
        return False
    key = _KEY_MAP.get(spoken)
    if key is None:
        return False
    _send_wtype_key([], key)
    return True


# ── Hyprland dispatch commands ───────────────────────────────────────────────

_NUM_WORDS = {
    "one": "1", "two": "2", "three": "3", "four": "4", "five": "5",
    "six": "6", "seven": "7", "eight": "8", "nine": "9", "ten": "10",
}

_CMD_WORKSPACE_GO = re.compile(
    r"^\s*(?:(?:go\s+to|switch\s+to)\s+workspace|workspace)\s+(?P<n>\d+|one|two|three|four|five|six|seven|eight|nine|ten)[.!?]?\s*$",
    re.IGNORECASE,
)
_CMD_WORKSPACE_MOVE = re.compile(
    r"^\s*move\s+(?:window\s+)?to\s+workspace\s+(?P<n>\d+|one|two|three|four|five|six|seven|eight|nine|ten)[.!?]?\s*$",
    re.IGNORECASE,
)
_CMD_CLOSE_WINDOW = re.compile(
    r"^\s*(?:"
    r"close\s+(?:the\s+|this\s+|that\s+)?(?:focused\s+)?window|"
    r"kill\s+(?:the\s+)?(?:active\s+)?window"
    r")[.!?]?\s*$",
    re.IGNORECASE,
)
_CMD_NEXT_WINDOW = re.compile(
    r"^\s*(?:next\s+window|switch\s+window|alt\s+tab)[.!?]?\s*$",
    re.IGNORECASE,
)


def try_hyprland(text: str) -> bool:
    """Handle Hyprland dispatcher commands. Returns True if handled."""
    if _CMD_NEXT_WINDOW.match(text):
        subprocess.run(["hyprctl", "dispatch", "cyclenext"], check=False)
        with LOG.open("a") as f:
            f.write(f"[{datetime.now().strftime('%H:%M:%S')}] [next window]\n")
        return True

    if _CMD_CLOSE_WINDOW.match(text):
        subprocess.run(["hyprctl", "dispatch", "killactive"], check=False)
        with LOG.open("a") as f:
            f.write(f"[{datetime.now().strftime('%H:%M:%S')}] [close window]\n")
        return True

    m = _CMD_WORKSPACE_GO.match(text)
    if m:
        n = _NUM_WORDS.get(m.group("n").lower(), m.group("n"))
        subprocess.run(["hyprctl", "dispatch", "workspace", n], check=False)
        with LOG.open("a") as f:
            f.write(f"[{datetime.now().strftime('%H:%M:%S')}] [workspace {n}]\n")
        return True

    m = _CMD_WORKSPACE_MOVE.match(text)
    if m:
        n = _NUM_WORDS.get(m.group("n").lower(), m.group("n"))
        subprocess.run(["hyprctl", "dispatch", "movetoworkspace", n], check=False)
        with LOG.open("a") as f:
            f.write(f"[{datetime.now().strftime('%H:%M:%S')}] [move window → workspace {n}]\n")
        return True

    return False


# ── Delete command ────────────────────────────────────────────────────────────
_CMD_DELETE = re.compile(r"^\s*(scratch|delete|undo)\s+that[.!?]?\s*$", re.IGNORECASE)
_CMD_DELETE_ALL = re.compile(r"^\s*(scratch|delete|undo)\s+all[.!?]?\s*$", re.IGNORECASE)
_CMD_VERBATIM_ON  = re.compile(r"^\s*verbatim\s+on[.!?]?\s*$",  re.IGNORECASE)
_CMD_VERBATIM_OFF = re.compile(r"^\s*verbatim\s+of+[.!?]?\s*$", re.IGNORECASE)
_CMD_COMMAND_MODE_ON  = re.compile(r"^\s*command\s+mode\s+on[.!?]?\s*$",  re.IGNORECASE)
_CMD_COMMAND_MODE_OFF = re.compile(r"^\s*command\s+mode\s+of+[.!?]?\s*$", re.IGNORECASE)
_CMD_TOGGLE_MODE = re.compile(
    r"^\s*toggle\s+(?P<mode>verbatim|command|normal)\s+mode[.!?]?\s*$",
    re.IGNORECASE,
)
_CMD_AGAIN = re.compile(r"^\s*again[.!?]?\s*$", re.IGNORECASE)
_CMD_DICTATION_OFF = re.compile(
    r"^\s*(?:"
    r"dictation\s+off|"
    r"dictation\s+of\b|"
    r"dication\s+off|"
    r"dication\s+of\b|"
    r"stop\s+dictation|"
    r"turn\s+off\s+dictation|"
    r"end\s+dictation|"
    r"quit\s+dictation"
    r")[.!?]?\s*$",
    re.IGNORECASE,
)
_CMD_DICTATION_HELP = re.compile(
    r"^\s*(?:dictation|dication)\s+help[.!?]?\s*$",
    re.IGNORECASE,
)
_CMD_LAUNCH = re.compile(
    r"^\s*(?:launch|open|start)\s+(?P<alias>.+?)[.!?]?\s*$",
    re.IGNORECASE,
)


def _read_voice_launch_map() -> dict[str, list[str]]:
    """Load voice-launch.json: keys are spoken aliases (lowercased), values are argv lists."""
    if not VOICE_LAUNCH_JSON.is_file():
        return {}
    try:
        raw = json.loads(VOICE_LAUNCH_JSON.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}
    if not isinstance(raw, dict):
        return {}
    out: dict[str, list[str]] = {}
    for k, v in raw.items():
        if not isinstance(k, str) or not k.strip():
            continue
        if not isinstance(v, list) or not v:
            continue
        if not all(isinstance(x, str) for x in v):
            continue
        out[k.strip().lower()] = list(v)
    return out


def try_launch_app(text: str) -> bool:
    """launch|open|start <alias> — spawn argv from whitelist; no shell."""
    m = _CMD_LAUNCH.match(text)
    if not m:
        return False
    alias = re.sub(r"\s+", " ", m.group("alias").strip().lower())
    if not alias:
        return False
    vm = _read_voice_launch_map()
    argv = vm.get(alias)
    if argv is None:
        subprocess.run(
            [
                "notify-send",
                "Dictation",
                f'No launch entry for "{alias}". Add it to {VOICE_LAUNCH_JSON}',
            ],
            check=False,
        )
        return True
    try:
        subprocess.Popen(
            argv,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except FileNotFoundError as e:
        subprocess.run(
            ["notify-send", "Dictation", f"Launch failed: {e}"],
            check=False,
        )
        return True
    with LOG.open("a") as f:
        f.write(f"[{datetime.now().strftime('%H:%M:%S')}] [launch] {alias}: {argv!r}\n")
    return True


def show_dictation_help_menu() -> None:
    """Open wofi dmenu listing special dictation commands (non-blocking for the daemon)."""
    data = ("\n".join(_HELP_MENU_LINES) + "\n").encode()
    try:
        proc = subprocess.Popen(
            [
                "wofi",
                "--show",
                "dmenu",
                "--prompt",
                "Dictation commands",
                "--width",
                "90%",
                "--height",
                "60%",
            ],
            stdin=subprocess.PIPE,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except FileNotFoundError:
        subprocess.run(
            ["notify-send", "Dictation", "wofi not found in PATH; install wofi for dictation help."],
            check=False,
        )
        return
    if proc.stdin:
        proc.stdin.write(data)
        proc.stdin.close()
    with LOG.open("a") as f:
        f.write(f"[{datetime.now().strftime('%H:%M:%S')}] [dictation help]\n")


def try_dictation_help(text: str) -> bool:
    if not _CMD_DICTATION_HELP.match(text):
        return False
    show_dictation_help_menu()
    return True


def try_dictation_stop(text: str) -> bool:
    """Stop dictation by running the same toggle script as the Hyprland keybind."""
    if not _CMD_DICTATION_OFF.match(text):
        return False
    with LOG.open("a") as f:
        f.write(f"[{datetime.now().strftime('%H:%M:%S')}] [dictation off]\n")
    # New session: do not tie this process to the daemon; toggle stops via dictation_rt_stop.
    subprocess.Popen(
        ["/usr/bin/bash", str(TOGGLE_SCRIPT)],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    return True

VERBATIM_FLAG = Path.home() / ".local/share/dictation-verbatim.flag"
COMMAND_MODE_FLAG = Path.home() / ".local/share/dictation-command.flag"


def _icon_args(name: str) -> list[str]:
    """Return ['-i', path] for a breeze-dark/breeze status icon, or [] if not found."""
    for theme in ("breeze-dark", "breeze"):
        p = Path(f"/usr/share/icons/{theme}/status/24/{name}.svg")
        if p.exists():
            return ["-i", str(p)]
    return []


# Icons for each mode (resolved once at import time).
_ICON_NORMAL   = _icon_args("microphone-sensitivity-high")
_ICON_VERBATIM = _icon_args("microphone-sensitivity-medium")
_ICON_COMMAND  = _icon_args("microphone-sensitivity-low")

# Stack of typed payloads (newest last). Each delete pops one utterance.
_typed_stack: list[str] = []

# Index into _typed_stack marking where we were when the last voice command ran.
# "undo all" deletes everything at or above this checkpoint.
_stack_checkpoint: int = 0

_verbatim_mode: bool = False
_command_mode: bool = False


def _set_verbatim(on: bool, *, notify: bool = True) -> None:
    global _verbatim_mode
    _verbatim_mode = on
    if on:
        VERBATIM_FLAG.touch()
    else:
        VERBATIM_FLAG.unlink(missing_ok=True)
    with LOG.open("a") as f:
        f.write(f"[{datetime.now().strftime('%H:%M:%S')}] [verbatim {'on' if on else 'off'}]\n")
    if notify:
        label, icon = ("Mode: Verbatim", _ICON_VERBATIM) if on else ("Mode: Normal", _ICON_NORMAL)
        subprocess.run(["notify-send", "-t", "2000"] + icon + ["Dictation", label], check=False)


def _set_command_mode(on: bool, *, notify: bool = True) -> None:
    global _command_mode
    _command_mode = on
    if on:
        COMMAND_MODE_FLAG.touch()
    else:
        COMMAND_MODE_FLAG.unlink(missing_ok=True)
    with LOG.open("a") as f:
        f.write(f"[{datetime.now().strftime('%H:%M:%S')}] [command mode {'on' if on else 'off'}]\n")
    if notify:
        label, icon = ("Mode: Command", _ICON_COMMAND) if on else ("Mode: Normal", _ICON_NORMAL)
        subprocess.run(["notify-send", "-t", "2000"] + icon + ["Dictation", label], check=False)


def _do_toggle_mode(mode: str) -> None:
    """Toggle the named mode. Works from any current mode. Only one notification is shown."""
    mode = mode.lower()
    if mode == "verbatim":
        if _verbatim_mode:
            _set_verbatim(False)
        else:
            if _command_mode:
                _set_command_mode(False, notify=False)
            _set_verbatim(True)
    elif mode == "command":
        if _command_mode:
            _set_command_mode(False)
        else:
            if _verbatim_mode:
                _set_verbatim(False, notify=False)
            _set_command_mode(True)
    elif mode == "normal":
        if _verbatim_mode:
            _set_verbatim(False)
        elif _command_mode:
            _set_command_mode(False)


# Last executed command (callable). "again" replays this; not set by plain text.
_last_command: object = None


def type_text(text: str) -> None:
    global _typed_stack
    payload = text + " "
    subprocess.run(["wtype", "-d", "40", "--", payload], check=False)
    _typed_stack.append(payload)
    with LOG.open("a") as f:
        f.write(f"[{datetime.now().strftime('%H:%M:%S')}] {text}\n")


def delete_last() -> None:
    global _typed_stack
    if not _typed_stack:
        return
    payload = _typed_stack.pop()
    keys: list[str] = []
    for _ in range(len(payload)):
        keys += ["-k", "BackSpace"]
    subprocess.run(["wtype"] + keys, check=False)
    with LOG.open("a") as f:
        f.write(f"[{datetime.now().strftime('%H:%M:%S')}] [deleted: {payload!r}]\n")


def delete_all() -> None:
    """Delete all typed utterances since the last voice command checkpoint."""
    global _typed_stack, _stack_checkpoint
    if len(_typed_stack) <= _stack_checkpoint:
        return
    to_delete = _typed_stack[_stack_checkpoint:]
    total_chars = sum(len(p) for p in to_delete)
    keys: list[str] = []
    for _ in range(total_chars):
        keys += ["-k", "BackSpace"]
    subprocess.run(["wtype"] + keys, check=False)
    joined = "".join(to_delete)
    _typed_stack = _typed_stack[:_stack_checkpoint]
    with LOG.open("a") as f:
        f.write(f"[{datetime.now().strftime('%H:%M:%S')}] [deleted all: {joined!r}]\n")


# ── Dispatcher ────────────────────────────────────────────────────────────────
def _try_all_commands(text: str) -> bool:
    """Attempt every recognised command. Return True if one matched."""
    global _last_command, _stack_checkpoint
    if _CMD_AGAIN.match(text):
        if _last_command is not None:
            _last_command()
        return True
    if _CMD_DELETE_ALL.match(text):
        delete_all()
        _last_command = delete_all
        return True
    if _CMD_DELETE.match(text):
        delete_last()
        _last_command = delete_last
        return True
    if try_dictation_help(text):
        _stack_checkpoint = len(_typed_stack)
        _last_command = show_dictation_help_menu
        return True
    if try_dictation_stop(text):
        return True
    if try_hyprland(text):
        _stack_checkpoint = len(_typed_stack)
        _last_command = lambda: try_hyprland(text)
        return True
    if try_launch_app(text):
        _stack_checkpoint = len(_typed_stack)
        _last_command = lambda: try_launch_app(text)
        return True
    if try_key_press(text):
        _stack_checkpoint = len(_typed_stack)
        _last_command = lambda: try_key_press(text)
        return True
    if try_compact_chord(text):
        _stack_checkpoint = len(_typed_stack)
        _last_command = lambda: try_compact_chord(text)
        return True
    if try_bare_key_press(text):
        _stack_checkpoint = len(_typed_stack)
        _last_command = lambda: try_bare_key_press(text)
        return True
    return False


def handle(raw: str) -> None:
    global _last_command, _stack_checkpoint
    text = clean_whisper_artifacts(apply_spoken_punctuation(raw))
    if not text:
        return

    # Verbatim mode: "verbatim off" and "toggle * mode" are special; everything else is typed.
    if _verbatim_mode:
        if _CMD_VERBATIM_OFF.match(text):
            _set_verbatim(False)
        elif m := _CMD_TOGGLE_MODE.match(text):
            _do_toggle_mode(m.group("mode"))
        else:
            type_text(text)
        return

    # Mode-toggle commands are always recognised regardless of command mode.
    if _CMD_VERBATIM_ON.match(text):
        _set_verbatim(True)
        return
    if _CMD_COMMAND_MODE_ON.match(text):
        _set_command_mode(True)
        return
    if _CMD_COMMAND_MODE_OFF.match(text):
        _set_command_mode(False)
        return
    if m := _CMD_TOGGLE_MODE.match(text):
        _do_toggle_mode(m.group("mode"))
        return

    # Command mode: run commands; notify if nothing matches; never type text.
    if _command_mode:
        if not _try_all_commands(text):
            subprocess.run(
                ["notify-send", "-t", "3000", "Dictation", f"Command not recognized: {text}"],
                check=False,
            )
            with LOG.open("a") as f:
                f.write(f"[{datetime.now().strftime('%H:%M:%S')}] [unrecognized cmd] {text}\n")
        return

    # Normal mode: try commands first, fall back to typing.
    if not _try_all_commands(text):
        text = re.sub(r" +([/\\])", r"\1", text)
        text = re.sub(r"([/\\]) +", r"\1", text)
        # "space" → literal space; consume flanking whitespace so "A space A" → "A A" not "A   A"
        text = re.sub(r" *\bspace\b *", " ", text, flags=re.IGNORECASE)
        # Strip Whisper's sentence-final dot from slash/backslash commands, e.g. "/clear."
        text = re.sub(r"([/\\]\w+)\.\s*$", r"\1", text)
        type_text(text)


# ── Main ──────────────────────────────────────────────────────────────────────
def main() -> None:
    from RealtimeSTT import AudioToTextRecorder

    recorder = AudioToTextRecorder(
        model="medium",
        language="en",
        device="cuda",
        compute_type="float16",
        silero_sensitivity=0.4,
        webrtc_sensitivity=2,
        post_speech_silence_duration=0.4,
        min_length_of_recording=0.3,
        min_gap_between_recordings=0.01,
        wake_words="",
        spinner=False,
        beam_size=5,
        initial_prompt=(
            "Voice commands: scratch that, delete that, scratch all, undo all, "
            "verbatim on, verbatim off, toggle verbatim mode, command mode on, command mode off, "
            "toggle command mode, toggle normal mode, dictation off, dictation help, "
            "press enter, press escape, press tab, press backspace, press delete, "
            "press control C, press control V, press control Z, press alt F4, "
            "press shift tab, press page up, press page down, "
            "go to workspace one, switch to workspace two, move window to workspace three, "
            "close window, close the window, next window, switch window, "
            "launch, open, start, again, new line, new paragraph."
        ),
    )

    def on_shutdown(sig, frame):
        VERBATIM_FLAG.unlink(missing_ok=True)
        COMMAND_MODE_FLAG.unlink(missing_ok=True)
        recorder.stop()
        sys.exit(0)

    signal.signal(signal.SIGTERM, on_shutdown)
    signal.signal(signal.SIGINT, on_shutdown)

    subprocess.run(
        ["ironbar", "style", "remove-class", "dictation-mic", "loading"],
        check=False, capture_output=True,
    )
    subprocess.run(
        ["ironbar", "style", "add-class", "dictation-mic", "listening"],
        check=False, capture_output=True,
    )

    notif_id_file = Path.home() / ".local/share/dictation-notif.id"
    notif_args: list[str] = []
    try:
        notif_id = notif_id_file.read_text().strip()
        if notif_id:
            notif_args = ["--replace-id", notif_id]
    except OSError:
        pass

    icon = Path("/usr/share/icons/breeze-dark/status/24/microphone-sensitivity-high.svg")
    if not icon.exists():
        icon = Path("/usr/share/icons/breeze/status/24/microphone-sensitivity-high.svg")
    cmd = ["notify-send", "-t", "3000"] + notif_args
    if icon.exists():
        cmd += ["-i", str(icon)]
    cmd += ["Dictation (RT)", "Listening"]
    subprocess.run(cmd, check=False, capture_output=True)

    print("RealtimeSTT daemon ready", flush=True)

    while True:
        text = recorder.text()
        if text:
            handle(text)


if __name__ == "__main__":
    main()
