# System stability and high-performance networking optimization.
# Ultra-high RPS tuning for load testing and development environments.
{
  pkgsStable,
  lib,
  ...
}: {
  boot.kernel.sysctl = {
    "fs.file-max" = 1000000; # Integer: System-wide file descriptor limit
    "net.core.somaxconn" = 65536; # Integer: Max pending connections
    "net.core.netdev_max_backlog" = 250000; # Integer: Max network queue backlog
    "net.ipv4.tcp_max_syn_backlog" = 65536; # Integer: Max pending SYN connections
    "net.ipv4.ip_local_port_range" = "1024\t65535"; # String: Port range (tab-separated, conservative)
    "kernel.pid_max" = 4194303; # Integer: Maximum process ID

    # Connection reuse and scalability (conservative settings)
    "net.ipv4.tcp_tw_reuse" = 1; # Integer: Reuse TIME_WAIT sockets
    "net.ipv4.tcp_fin_timeout" = 15; # Integer: FIN timeout for closed sockets

    # SYN handling
    "net.ipv4.tcp_syncookies" = lib.mkDefault 1; # Integer: Protects against SYN floods

    # TCP buffer tuning - integers for single values
    "net.core.rmem_max" = 16777216; # Integer: Max receive buffer (16 MB)
    "net.core.wmem_max" = 16777216; # Integer: Max send buffer (16 MB)
    "net.ipv4.tcp_rmem" = "4096\t87380\t16777216"; # String: TCP receive buffer (tab-separated)
    "net.ipv4.tcp_wmem" = "4096\t65536\t16777216"; # String: TCP send buffer (tab-separated)

    # Memory management - integers for single values
    "vm.swappiness" = 10; # Integer: Swap tendency
    "vm.dirty_ratio" = 15; # Integer: Max dirty memory percentage
    "vm.dirty_background_ratio" = 5; # Integer: Background flush threshold
  };

  services = {
    earlyoom = {
      enable = false;
    };

    # Enable udisks2 for automatic mounting of removable media
    udisks2 = {
      enable = true;
    };

    dbus = {
      packages = with pkgsStable; [
        gnome-keyring
        gcr
      ];
    };
  };

  systemd.settings.Manager = {
    DefaultLimitNOFILE = 200000; # Systemd-wide FD limit
    DefaultLimitNPROC = 65536; # Systemd-wide process limit
  };

  # Use systemd.user.extraConfig instead (correct approach)
  systemd.user.extraConfig = ''
    DefaultLimitNOFILE=200000
    DefaultLimitNPROC=65536
  '';

  # PAM session limits
  security.pam.loginLimits = [
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
      value = "unlimited";
    }
  ];
}
