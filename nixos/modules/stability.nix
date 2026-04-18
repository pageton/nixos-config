# System stability, resource limits, and high-performance networking tuning.
{ lib, pkgsStable, ... }:
{
  services = {
    fstrim = {
      enable = true;
      interval = "weekly";
    };

    earlyoom = {
      enable = true;
      freeMemThreshold = 8; # 8% ≈ 2.6GB on 32GB
      freeSwapThreshold = 10;
      enableNotifications = true; # Desktop notification on kill
    };

    # Resolve conflict: earlyoom sets systembus-notify=true, smartd (via Scrutiny) sets false.
    # We want notifications enabled for earlyoom OOM-kill alerts.
    systembus-notify.enable = lib.mkForce true;

    # Enable udisks2 for automatic mounting of removable media (workstations only)
    udisks2.enable = true;

    # DBus packages for GUI keyring and credentials (workstations only)
    dbus = {
      packages = with pkgsStable; [
        gnome-keyring
        gcr
      ];
    };

    # Ensure Secret Service daemon is available and started correctly.
    gnome.gnome-keyring.enable = true;
  };

  # TCP BBR congestion control module — 10-30% throughput improvement on VPN connections
  boot.kernelModules = [ "tcp_bbr" ];

  boot.kernel.sysctl = {
    # Inotify limits for development (VS Code, webpack, rust-analyzer file watchers)
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 1024;

    "fs.file-max" = 1000000;
    "net.core.somaxconn" = 65536;
    "net.core.netdev_max_backlog" = 250000;
    "net.ipv4.tcp_max_syn_backlog" = 65536;
    "net.ipv4.ip_local_port_range" = "1024\t65535";
    "kernel.pid_max" = 4194303;
    "net.ipv4.tcp_fin_timeout" = 15;

    # TCP buffer tuning
    "net.core.rmem_max" = 16777216; # 16 MB
    "net.core.wmem_max" = 16777216; # 16 MB
    "net.ipv4.tcp_rmem" = "4096\t87380\t16777216";
    "net.ipv4.tcp_wmem" = "4096\t65536\t16777216";

    # Memory management
    "vm.swappiness" = 10;
    # Dirty ratios tuned for DRAM-less SSD + LUKS — flush writes sooner in smaller
    # bursts to avoid saturating the device when the SLC cache fills.
    "vm.dirty_ratio" = 5;
    "vm.dirty_background_ratio" = 1;
    "vm.dirty_writeback_centisecs" = 300; # Flush every 3s (default 500 = 5s)
    "vm.dirty_expire_centisecs" = 1500; # Expire dirty pages after 15s (default 3000)
    "vm.vfs_cache_pressure" = 50; # Keep dentries/inodes longer (good for dev work with large codebases)

    # TCP optimizations
    "net.ipv4.tcp_fastopen" = 3; # Client+server TFO (saves 1 RTT on HTTPS connections)
    "net.ipv4.tcp_mtu_probing" = 1; # Discover path MTU (helps on VPN tunnels like Mullvad)

    # TCP BBR
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "30s";
    DefaultTimeoutStartSec = "180s"; # Long enough for heavy user-manager startup on cold boot
    DefaultDeviceTimeoutSec = "30s";
    DefaultLimitNOFILE = 200000;
    DefaultLimitNPROC = 65536;
    # Disable hardware watchdog — prevents "watchdog did not stop!" and 10-min fallback timer
    RuntimeWatchdogSec = "0";
    RebootWatchdogSec = "0";
    KExecWatchdogSec = "0";
  };

  # Keep user-session app scopes from delaying reboot for the default 90s.
  systemd.user.extraConfig = ''
    DefaultTimeoutStopSec=30s
  '';

  # Real-time kit for multimedia tasks (workstations only)
  security.rtkit.enable = true;

  # PAM session limits (consolidated — includes core dump disable from security/hardening.nix)
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "hard";
      item = "core";
      value = "0"; # Disable core dumps (security hardening)
    }
    {
      domain = "*";
      type = "-";
      item = "nofile";
      value = 200000;
    }
    {
      domain = "*";
      type = "-";
      item = "nproc";
      value = 65536;
    }
    {
      domain = "*";
      type = "-";
      item = "stack";
      value = 65536; # 64 MB
    }
  ];
}
