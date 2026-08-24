#!/usr/bin/env python3
"""Seed Noctalia's app-managed wallpaper state from the declarative config.

Noctalia v5 (rev a9cd1c8+) resolves the effective wallpaper ONLY from
~/.local/state/noctalia/settings.toml ([wallpaper.default] /
[wallpaper.monitors.*]); the base config.toml [wallpaper.default] key is
tolerated but inert (upstream schema marks it "app-managed state, not
settings"). This script seeds that state layer so the declarative
nix-wallpaper derivation actually applies, including on fresh profiles.

Policy:
- Explicit user selections (any non-/nix/store path, e.g. ~/Pictures/...)
  are never touched — GUI choices always win.
- Store-pathed values previously seeded by us are updated to the current
  derivation, so palette/nix-wallpaper changes propagate on next switch.
- Noctalia's state-file watcher applies changes live; no reload nudge needed.
"""

import json
import os
import sys
import tomllib
from pathlib import Path

OURS_PREFIX = "/nix/store/"


def wallpaper_paths(data):
    wp = data.get("wallpaper")
    if not isinstance(wp, dict):
        return []
    paths = []
    for key in ("default", "last"):
        table = wp.get(key)
        if isinstance(table, dict) and isinstance(table.get("path"), str):
            paths.append(table["path"])
    monitors = wp.get("monitors")
    if isinstance(monitors, dict):
        for table in monitors.values():
            if isinstance(table, dict) and isinstance(table.get("path"), str):
                paths.append(table["path"])
    return paths


def has_default_table(data):
    wp = data.get("wallpaper")
    return isinstance(wp, dict) and isinstance(wp.get("default"), dict)


def write_atomic(state, content):
    tmp = state.with_suffix(".tmp")
    tmp.write_text(content)
    os.replace(tmp, state)


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: noctalia-wallpaper-seed.py <wallpaper-path>")
    desired = sys.argv[1]
    state = Path(
        os.environ.get("NOCTALIA_STATE", Path.home() / ".local/state/noctalia/settings.toml")
    )

    text = state.read_text() if state.exists() else ""
    data = {}
    if text:
        try:
            data = tomllib.loads(text)
        except tomllib.TOMLDecodeError as exc:
            sys.exit(f"noctalia wallpaper seed: {state} unparseable ({exc}); not touching it")

    present = wallpaper_paths(data)
    if any(not p.startswith(OURS_PREFIX) for p in present):
        return  # explicit user selection — stay out of the way

    stale = {p for p in present if p.startswith(OURS_PREFIX) and p != desired}
    if stale:
        new_text = text
        for old in sorted(stale):
            new_text = new_text.replace(json.dumps(old), json.dumps(desired))
        if new_text != text:
            write_atomic(state, new_text)
            print(f"noctalia wallpaper seed: updated {sorted(stale)} -> {desired}")
            return
        print(
            f"noctalia wallpaper seed: WARNING stale paths {sorted(stale)} "
            "not found verbatim in state file; leaving untouched"
        )
        return

    if desired in present:
        return  # already seeded

    if has_default_table(data):
        # Default exists with a different quoting style; appending would duplicate the table.
        print("noctalia wallpaper seed: WARNING [wallpaper.default] already present; leaving untouched")
        return

    state.parent.mkdir(parents=True, exist_ok=True)
    write_atomic(
        state,
        text.rstrip("\n") + "\n[wallpaper.default]\npath = %s\n" % json.dumps(desired),
    )
    print(f"noctalia wallpaper seed: set default -> {desired}")


if __name__ == "__main__":
    main()
