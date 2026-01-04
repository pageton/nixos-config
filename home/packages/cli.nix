# Command-line interface tools and utilities for file management,
# text processing, system monitoring, and development workflows.
{pkgsStable, ...}:
with pkgsStable; [
  # === File and Directory Management ===
  fd # Modern find replacement with intuitive syntax
  fselect # SQL-like file selection tool
  ncdu # Interactive disk usage analyzer
  dust # Modern du with tree visualization
  duf # Enhanced df with better formatting
  dua # Modern disk usage analyzer

  # === Text Processing and Search ===
  ripgrep # Fast grep replacement with modern features
  fzf # Command-line fuzzy finder
  jq # JSON processor and query tool
  yq # YAML processor similar to jq
  htmlq # HTML processor like jq for HTML
  sd # Modern sed replacement
  choose # Modern cut/awk replacement

  # === System Information and Monitoring ===
  fastfetch # Fast system information display
  microfetch # Minimal system information
  onefetch # Git repository information tool
  tokei # Code statistics and analysis
  procs # Modern process viewer (ps replacement)

  # === Development and Version Control ===
  lazydocker # Terminal UI for Docker management
  gh # GitHub CLI tool
  glab # GitLab CLI tool
  hcloud # Hetzner Cloud CLI
  delta # Modern diff viewer for Git

  # === Media Processing and Download ===
  yt-dlp # YouTube and video downloader
  imagemagick # Image manipulation and processing suite

  # === Performance Measurement and Benchmarking ===
  hyperfine # Command-line benchmarking tool
  flamegraph # Performance visualization tool

  # === HTTP Client Tools ===
  curlie # Modern curl replacement with colors
  xh # Friendly HTTP client

  # === Log Processing and Analysis ===
  angle-grinder # Log processing tool

  # === Network Analysis ===
  wireshark-cli # Network protocol analyzer (CLI)
  mitmproxy # HTTP proxy for debugging and analysis

  # === Container Analysis ===
  dive # Docker image layer analyzer

  # === Backup and Storage ===
  restic # Modern backup program
  borgbackup # Deduplicating backup program

  # === Data Format Utilities ===
  fx # Interactive JSON viewer and processor

  # === Terminal Theming ===
  vivid # LS_COLORS theme generator

  # === General Utilities ===
  bc # Arbitrary precision calculator
  rsync # Fast file synchronization tool

  # === File Watching and Automation ===
  watchexec # Execute commands on file changes
  entr # Run commands when files change

  # === File Type Detection ===
  file # File type detection tool

  # === Tunneling ===
  cloudflared # Cloudflare tunnel CLI tool
  ngrok # Open source tunneling application
  localtunnel # Local HTTP tunnel
]
