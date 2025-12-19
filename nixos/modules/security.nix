# System security hardening module.
{pkgs, ...}: {
  # Enable automatic system updates for security patches
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    dates = "daily";
  };

  # Harden the kernel and system
  boot.kernel.sysctl = {
    # Prevent SYN flood attacks
    "net.ipv4.tcp_syncookies" = 1;
    # Less strict reverse path filtering for desktop networks
    "net.ipv4.conf.all.rp_filter" = 2; # Loose mode (better for home networks)
    "net.ipv4.conf.default.rp_filter" = 2;
    # Ignore ICMP broadcasts to avoid participation in Smurf attacks
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    # Ignore bogus ICMP errors
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    # Enable source route verification
    "net.ipv4.conf.all.secure_redirects" = 1;
    "net.ipv4.conf.default.secure_redirects" = 1;
    # Don't log Martian packets (reduces log noise)
    "net.ipv4.conf.all.log_martians" = 0;
    # Protect against core dumps
    "kernel.core_pattern" = "|/bin/false";
  };

  # Security-focused system packages (optimized for desktop)
  environment.systemPackages = with pkgs; [
    lynis # Security auditing
  ];

  # Hardening: Disable core dumps
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "hard";
      item = "core";
      value = "0";
    }
  ];

  # Harden the system against attacks
  security = {
    # AppArmor confinement (additional security layer)
    apparmor.enable = true;

    # Protect system files
    protectKernelImage = true;

    # Allow users in wheel group to use sudo
    sudo = {
      enable = true;
      wheelNeedsPassword = true;
    };
  };

  # Network security: Enable and configure firewall properly
  networking = {
    firewall = {
      enable = true;
      # Log dropped packets for monitoring
      logRefusedConnections = true;
      # Drop packets instead of rejecting for stealth
      rejectPackets = false;
      # Allow loopback traffic
      allowedTCPPorts = [];
      allowedUDPPorts = [5353]; # mDNS for local network discovery
      # Allow specific services that need network access
      allowedTCPPortRanges = [];
      allowedUDPPortRanges = [];
    };
  };

  # Services configuration
  services = {
    # Avahi network discovery (local network discovery - fixed)
    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
        userServices = true;
      };
      # Allow on all interfaces for proper network discovery
      # allowInterfaces = [ "lo" ]; # REMOVED: This was causing network instability
    };

    # System monitoring - prometheus removed due to service failures
    # prometheus.exporters = {
    #   node = {
    #     enable = true;
    #     enabledCollectors = [
    #       "systemd"
    #       "processes"
    #       "network"
    #     ];
    #     port = 9100;
    #     listenAddress = "127.0.0.1";
    #   };
    # };
  };

  # Systemd service hardening for better security
  systemd = {
    # Global systemd hardening (network-friendly timeouts)
    settings = {
      Manager = {
        DefaultTimeoutStopSec = "30s"; # Increased from 10s to allow proper service shutdown
        DefaultTimeoutStartSec = "30s"; # Increased from 10s to allow network services to start properly
        DefaultDeviceTimeoutSec = "30s"; # Increased from 10s for network devices
      };
    };

    timers = {
      # Weekly security audit
      security-audit = {
        description = "Weekly security audit";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
          Unit = "security-audit.service";
        };
      };
    };

    services = {
      security-audit = {
        description = "Run security audit tasks";
        serviceConfig = {
          Type = "oneshot";
          # Systemd hardening for the security service itself
          PrivateNetwork = true;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "strict";
          ReadWritePaths = ["/tmp"];
          ExecStart = ''
            ${pkgs.bash}/bin/bash -c "
              echo 'Starting security audit...'

              # Run Lynis security audit (fixed path)
              echo 'Running Lynis audit...'
              ${pkgs.lynis}/bin/lynis audit system --quiet

              echo 'Security audit completed!'
            "
          '';
        };
      };
    };
  };
}
