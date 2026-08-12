# Uses pkgs (unstable) — porsmo, watson, and timewarrior are not in pkgsStable.

# Productivity tools for time tracking and focus management.
{ pkgs, ... }: with pkgs;
[
  porsmo # CLI Pomodoro timer
  watson # Project-based time tracking
  timewarrior # Taskwarrior companion
]
