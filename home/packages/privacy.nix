# Privacy and opsec tools for anonymous browsing, secure communication,
# metadata removal, and network privacy.
{
  pkgs,
  pkgsStable,
}:
with pkgs;
with pkgsStable; [
  # === Privacy-Focused Browsers ===
  # librewolf # Privacy-focused Firefox fork
  tor # Tor client and service
  tor-browser # Tor Browser Bundle

  # === DNS Privacy ===
  dnscrypt-proxy # Encrypted DNS client
  unbound # Validating recursive DNS resolver

  # === Network Anonymity ===
  i2pd # I2P anonymous network
  onionshare # Secure file sharing via Tor
  tribler # Anonymous BitTorrent client

  # === Metadata Removal ===
  mat2 # Metadata removal tool (anonymization framework)
  exiftool # Read/write metadata in files

  # === Secure Communication ===
  signal-desktop # Encrypted messaging
  wire-desktop # Secure messenger

  # === Password and Key Management ===
  keepassxc # Cross-platform password manager
  veracrypt # Disk encryption
  socat # Network relay tool

  # === Network Analysis ===
  nmap # Network discovery and security auditing
  tcpdump # Network packet analyzer
]
