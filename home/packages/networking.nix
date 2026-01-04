# Networking and network analysis tools for network analysis, monitoring,
# debugging, security testing, and connectivity management.
{pkgsStable, ...}:
with pkgsStable; [
  # === Core Networking and Security ===
  openssl # OpenSSL cryptographic library
  openssl.dev # OpenSSL development headers
  openssh # OpenSSH connectivity tools
  networkmanager # Network connection manager

  # === HTTP Clients and Download Tools ===
  wget # File downloader
  curl # Command-line HTTP client
  httpie # Modern HTTP client with colors

  # === Network Scanning and Reconnaissance ===
  masscan # Fast internet-scale port scanner
  zmap # Internet-wide network scanner

  # === Network Monitoring and Analysis ===
  iftop # Real-time network bandwidth monitor
  nethogs # Network usage by process
  nload # Network load monitor
  vnstat # Network traffic statistics
  bandwhich # Network utilization by socket

  # === DNS and Domain Utilities ===
  dnsutils # DNS utilities
  whois # Domain registration information
  dog # Modern DNS lookup tool

  # === Network Debugging and Packet Analysis ===
  netcat # Networking utility for reading/writing network connections

  # === VPN and Secure Tunneling ===
  openvpn # OpenVPN client
  wireguard-tools # WireGuard VPN tools

  # === Network Performance and Diagnostics ===
  iperf3 # Network bandwidth measurement
  mtr # Network diagnostic tool (traceroute + ping)
  traceroute # Network route tracing

  # === Text-Based Web Browsers ===
  lynx # Advanced text-based web browser
  w3m # Another text-based web browser

  # === Network Security ===
  hydra # Network login cracker
]
