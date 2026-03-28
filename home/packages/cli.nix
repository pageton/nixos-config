# Command-line interface tools and utilities for file management,
# text processing, system monitoring, and development workflows.
# NOTE: fzf and carapace are managed by programs.* modules.
#       yt-dlp is firejail-wrapped at system level.

{ pkgsStable, ... }:
with pkgsStable;
[
  # === Backup and Storage ===
  borgbackup # Deduplicating backup program
  restic # Modern backup program

  # === Container Analysis ===
  dive # Docker image layer analyzer

  # === Data Format Utilities ===
  fx # Interactive JSON viewer and processor

  # === Documentation ===
  glow # Terminal Markdown renderer
  tealdeer # Fast tldr pages client

  # === File and Directory Management ===
  duf # Enhanced df with better formatting
  dust # Modern du with tree visualization
  fd # Modern find replacement with intuitive syntax
  fselect # SQL-like file selection tool
  trash-cli # Safe rm replacement (for snacks.explorer)

  # === General Utilities ===
  actionlint # GitHub Actions linter
  bc # Arbitrary precision calculator
  codespell # Spell checker for source code
  rsync # Fast file synchronization tool
  typos # Source code spell checker
  watchexec # Execute commands on file changes

  # === HTTP Client Tools ===
  xh # Friendly HTTP client

  # === Log Processing and Analysis ===
  angle-grinder # Log processing tool

  # === Media Processing ===
  imagemagick # Image manipulation and processing suite

  # === Network Analysis ===
  mitmproxy # HTTP proxy for debugging and analysis
  wireshark-cli # Network protocol analyzer (CLI)

  # === Nix Tooling ===
  nix-diff # Derivation-level diff between NixOS generations
  nvd # Nix version diff tool

  # === Performance Measurement and Benchmarking ===
  flamegraph # Performance visualization tool
  hyperfine # Command-line benchmarking tool

  # === Shell UI ===
  gum # TUI components for shell scripts

  # === System Information and Monitoring ===
  fastfetch # Fast system information display
  microfetch # Minimal system information
  onefetch # Git repository information tool
  procs # Modern process viewer (ps replacement)
  tokei # Code statistics and analysis

  # === Terminal Effects ===
  cmatrix # Matrix rain terminal effect
  peaclock # Terminal clock

  # === Terminal Theming ===
  vivid # LS_COLORS theme generator

  # === Text Processing and Search ===
  ast-grep # AST-aware structural code search
  choose # Modern cut/awk replacement
  htmlq # HTML processor like jq for HTML
  jq # JSON processor and query tool
  ripgrep # Fast grep replacement with modern features
  sd # Modern sed replacement
  semgrep # Semantic code analysis and search
  yq # YAML processor similar to jq

  # === Version Control ===
  git-absorb # Auto-fixup commits into their targets
  git-cliff # Auto-generate changelogs from conventional commits
  git-crypt # Transparent file encryption in repos
  git-extras # 60+ git utilities (git-summary, git-effort, git-standup, etc.)
  glab # GitLab CLI tool
  hcloud # Hetzner Cloud CLI
  lazydocker # Terminal UI for Docker management
  serie # Git log TUI viewer
]
