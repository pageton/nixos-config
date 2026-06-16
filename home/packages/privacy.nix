# Privacy and opsec tools for anonymous browsing, secure communication,
# metadata removal, and network privacy.
{
  pkgs,
  pkgsStable,
  constants,
}:
let
  eglWrap = import ../_helpers/_egl-wrap.nix { inherit pkgs constants; };
  inherit (eglWrap) wrapWithMesaEgl;
in
with pkgsStable;
[
  # === Privacy-Focused Browsers (Mesa EGL wrapped for NVIDIA) ===
  # LibreWolf is managed by programs.librewolf module (home/programs/librewolf/)
  pkgs.tor # Tor client and service
  (wrapWithMesaEgl "tor-browser" tor-browser)

  # === DNS Privacy ===
  dnscrypt-proxy # Encrypted DNS client
  unbound # Validating recursive DNS resolver
  i2pd # I2P anonymous network
  onionshare # Secure file sharing via Tor
  # tribler # Anonymous BitTorrent client
  mat2 # Metadata removal tool (anonymization framework)
  exiftool # Read/write metadata in files
  pkgs.signal-desktop # Encrypted messaging
  wire-desktop # Secure messenger
  keepassxc # Cross-platform password manager
  veracrypt # Disk encryption
  socat # Network relay tool
  nmap # Network discovery and security auditing
  tcpdump # Network packet analyzer
  # === Supply-chain and Vulnerability Scanning ===
  gitleaks # Pre-commit/pre-push secret scanning
  trivy # Vulnerability, misconfiguration, and secret scanning
  sbctl # Secure Boot preparation
  tpm2-tools # TPM2 utilities
  srm # Secure file removal
]
