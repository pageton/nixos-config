# Development tools and programming languages for software development,
# debugging, database management, and reverse engineering.
{
  pkgs,
  pkgsStable,
  constants,
}:
let
  zedNvidiaXwayland = pkgs.symlinkJoin {
    name = "zed-editor-nvidia-xwayland";
    paths = [ pkgsStable.zed-editor ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/zeditor \
        --set WAYLAND_DISPLAY "" \
        --set ZED_DEVICE_ID 0x2484 \
        --set VK_LOADER_LAYERS_DISABLE "~implicit~explicit"
    '';
  };
in
with pkgs;
with pkgsStable;
[
  # === Integrated Development Environments ===
  vscode-fhs # Visual Studio Code editor (FHS wrapper for extension compatibility)
  zedNvidiaXwayland # Zed editor, forced away from unstable NVIDIA Wayland path
  sqlitebrowser # SQLite database browser GUI
  pkgs.redisinsight # Redis GUI

  # === API Development and Testing ===
  burpsuite # Web application security testing tool
  postman # API development platform
  bruno # Open-source API client (Postman alternative)
  insomnia # REST API client

  # === C/C++ Development ===
  gcc # GNU C compiler and toolchain
  gdb # GNU debugger
  cmake # Cross-platform build system
  gnumake # GNU make build automation
  valgrind # Memory debugging and profiling
  strace # System call tracer
  ltrace # Library call tracer

  # === Database Systems and Clients ===
  sqlite # SQLite database engine
  postgresql # PostgreSQL database client
  redis # Redis key-value store client
  dbeaver-bin # Universal database management tool

  # === Build Systems and Task Runners ===
  just # Modern command runner

  # === Version Control ===
  git-lfs # Git Large File Storage

  # === Container and Orchestration ===
  docker-compose # Docker container orchestration

  # === Documentation and Conversion ===
  pandoc # Universal document converter
  tectonic # Modern LaTeX engine (for snacks.image LaTeX rendering)
  mermaid-cli # Mermaid diagram CLI renderer (for snacks.image)

  # === Parser and Syntax Tools ===
  tree-sitter # Tree-sitter CLI for parser generation

  # === Rust Development ===
  rustc # Rust programming language compiler
  cargo # Rust package manager and build tool

  # === Reverse Engineering and Dynamic Analysis ===
  frida-tools # Dynamic instrumentation toolkit for reverse engineering
  ghidra-bin # NSA reverse engineering framework (GUI + headless)
  radare2 # CLI reverse engineering framework
  cutter # radare2 GUI frontend
  binwalk # Firmware/blob analysis and extraction tool
  scrcpy # Screen mirroring for Android devices (ADB-based)

  # Security and pattern analysis
  yara # Pattern matching engine for malware/rules detection
  hashid # Hash type identification from hash strings
  cewl # Custom wordlist generator by spidering target sites
]
