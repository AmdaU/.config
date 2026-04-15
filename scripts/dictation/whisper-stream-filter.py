#!/usr/bin/env python3
"""Parse whisper-stream stdout and emit only newly transcribed text.

whisper-stream writes each step as:
    ESC[2K CR <spaces> ESC[2K CR <transcription text> LF

We extract the transcription from each line, then output only the
words that weren't in the previous step's output (rolling-window dedup).
"""
import re
import sys

ANSI_RE = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
SENTENCE_BOUNDARY_RE = re.compile(r'([.?!])([A-Za-z])')
SKIP = {'[BLANK_AUDIO]', '[Start speaking]', ''}


def strip_ansi(text: str) -> str:
    return ANSI_RE.sub('', text)


def extract_transcription(line: str) -> str:
    """Pull the transcription out of a CR-overwritten line."""
    # Split on CR; the transcription is in the last non-empty segment
    for part in reversed(line.split('\r')):
        cleaned = strip_ansi(part).strip()
        if cleaned not in SKIP:
            return cleaned
    return ''


def find_new_suffix(typed: str, new: str) -> str:
    """Return words in `new` that extend beyond `typed`.

    Finds the longest suffix of `typed` words that appears as a
    prefix of `new` words, then returns the remainder.
    """
    typed_words = typed.split()
    new_words = new.split()
    if not typed_words or not new_words:
        return new

    best = 0
    for start in range(len(typed_words)):
        suffix = typed_words[start:]
        n = len(suffix)
        if n <= best:
            continue
        if len(new_words) >= n and new_words[:n] == suffix:
            best = n

    return ' '.join(new_words[best:])


def main() -> None:
    typed_text = ''

    for raw_line in sys.stdin:
        transcription = extract_transcription(raw_line)
        if not transcription:
            continue

        new_part = find_new_suffix(typed_text, transcription).strip()
        if new_part:
            new_part = SENTENCE_BOUNDARY_RE.sub(r'\1 \2', new_part)
            print(new_part, flush=True)
            typed_text = transcription


if __name__ == '__main__':
    main()
