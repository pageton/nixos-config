{ pkgs, ... }:

with pkgs;
[
  age # File encryption tool (age)
  tree # Directory tree listing tool
  file # File type detection tool
  jq # JSON processor and query tool
  fzf # Fuzzy finder (interactive search)
  direnv # Environment variable manager (per-directory)
  yt-dlp # YouTube and video downloader
  curl # HTTP client (data transfer tool)
  wget # HTTP client (file download tool)
  bc # Arbitrary precision calculator
  fd # Fast and user-friendly file finder
  onefetch # Git repository summary/info tool
  ripgrep # Fast text search tool (grep alternative)
  fselect # File search with SQL-like queries
  tokei # Code statistics tool (lines of code)
  yazi # TUI file manager (fast, ranger-like)
  gh # GitHub CLI tool
  cloudflared # Cloudflare tunnel CLI tool
  lazydocker # Terminal UI for Docker management
]
