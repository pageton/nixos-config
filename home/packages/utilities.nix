# General utility packages and system tools including archive management,
# system utilities, security tools, and development helpers.
{pkgsStable, ...}:
with pkgsStable; [
  # === Core GNU Utilities ===
  coreutils # Basic file, shell, and text manipulation utilities
  findutils # File search utilities (find, xargs, locate)
  diffutils # File comparison utilities

  # === Archive and Compression Tools ===
  gzip # GNU compression utility
  bzip2 # Bzip2 compression utility
  xz # High-ratio compression utility
  zip # ZIP compression and archiving
  unzip # ZIP archive extraction
  p7zip # 7-Zip compression and encryption
  unrar # RAR archive extraction
  file-roller # Archive manager with GUI
  xarchiver # Lightweight archive manager

  # === Essential System Process Management ===
  lsof # List open files and network connections
  procps # Process utilities (ps, top, kill, etc.)
  psmisc # Additional process utilities (killall, pgrep, pstree)
  util-linux # System utilities (lsblk, mount, dmesg, etc.)

  # === XDG and Desktop Integration ===
  xdg-utils # XDG base directory utilities
  desktop-file-utils # Desktop file management utilities

  # === Security and Credential Management ===
  libsecret # Secret/password management library
  sops # Encrypted secrets management

  # === Media Optimization ===
  optipng # PNG image optimization
  jpegoptim # JPEG image optimization

  # === Terminal Image Display ===
  ueberzugpp # Terminal image viewer and display

  # === System Management and Device Handling ===
  udisks # Storage device management and auto-mounting
  udiskie # Automatic disk mounting for USB drives with notifications

  # === Audio Control ===
  pavucontrol # PulseAudio volume control GUI
  easyeffects # Audio effects for PipeWire applications

  # === Development and Debugging Utilities ===
  hexdump # Hexadecimal file dumper
  xxd # Hex dump utility (part of vim)
  tree # Directory tree visualization

  # === Application Packaging ===
  appimage-run # Run AppImage applications with proper FHS environment
]
