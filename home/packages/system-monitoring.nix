# System monitoring and diagnostic tools.
{ pkgsStable, ... }:
with pkgsStable;
[
  # === Benchmarking ===
  stress-ng # CPU/memory/IO stress testing
  sysbench # Multi-threaded benchmark tool

  # === Container Monitoring ===
  ctop # Container metrics (like htop for containers)

  # === GPU Monitoring ===
  nvitop # Interactive NVIDIA GPU process viewer

  # === Hardware Information ===
  dmidecode # DMI/SMBIOS hardware info
  hwinfo # Hardware detection tool
  inxi # System information script
  lshw # Hardware lister

  # === Log Analysis ===
  lnav # Advanced log file navigator

  # === Memory Analysis ===
  smem # Memory reporting tool (per-process PSS/USS)

  # === Performance Analysis ===
  inotify-tools # Filesystem event monitoring
  perf-tools # Performance analysis tools

  # === Storage Monitoring ===
  hdparm # Hard disk parameter utility
  sdparm # SCSI disk parameter utility
]
