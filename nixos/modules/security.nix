# Kernel and system security hardening.
# Merged from: hardening, firewall, opsec, services, audit, aide.
{
  lib,
  pkgs,
  user,
  ...
}:
let
  aideConf = pkgs.writeText "aide.conf" ''
    database_in=file:/var/lib/aide/aide.db
    database_out=file:/var/lib/aide/aide.db.new
    database_new=file:/var/lib/aide/aide.db.new

    # Rule definitions
    NORMAL = p+i+n+u+g+s+m+c+sha256
    DIR = p+i+n+u+g
    LOG = p+u+g+i+n+S

    # Critical system paths
    /etc NORMAL
    /boot NORMAL

    # User-sensitive files
    /home/${user}/.gnupg NORMAL
    /home/${user}/.ssh NORMAL
    /home/${user}/.config/sops NORMAL

    # Skip noisy directories
    !/etc/adjtime
    !/etc/resolv.conf
    !/etc/mtab
    !/var
    !/nix
    !/proc
    !/sys
    !/dev
    !/run
    !/tmp
  '';
in
{
  # graphene-hardened removed — crashes glycin/bwrap image loaders (Loupe, Nautilus
  # thumbnails) because the allocator is preloaded system-wide via ld-nix.so.preload
  # and glycin-image-rs sandbox children die with coredump signals.

  boot = {
    # === Boot Kernel Parameters ===
    kernelParams = [
      "page_alloc.shuffle=1"
      "randomize_kstack_offset=on"
      "vsyscall=none"
      "slab_nomerge"
      "init_on_alloc=1"
      "init_on_free=1"
      "module.sig_enforce=1"
      "lockdown=integrity"
      "loglevel=4"
      "mem_sleep_default=deep"
      "random.trust_cpu=off"
    ];

    # === Blacklisted Kernel Modules ===
    blacklistedKernelModules = [
      # Obscure network protocols (common exploit targets)
      "dccp"
      "sctp"
      "rds"
      "tipc"
      # FireWire/Thunderbolt (DMA attack vectors)
      "firewire-core"
      "firewire-ohci"
      "firewire-sbp2"
      "thunderbolt"
      # Virtual device attack surface
      "vivid" # Virtual video test driver (kernel attack surface)
      # Obscure filesystems
      "cramfs"
      "hfs"
      "hfsplus"
      "udf"
    ];

    # === Kernel sysctl Hardening ===
    kernel.sysctl = {
      # Network Security
      "net.ipv4.tcp_syncookies" = 1; # SYN flood protection
      "net.ipv4.conf.all.rp_filter" = 2; # Loose mode — strict (1) breaks Docker/Mullvad routing
      "net.ipv4.conf.default.rp_filter" = 2;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1; # Smurf attack prevention
      "net.ipv4.icmp_ignore_bogus_error_responses" = 1;

      # Disable ICMP redirects (MITM prevention)
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;

      # Disable source routing (IP spoofing prevention)
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.default.accept_source_route" = 0;

      "net.ipv4.conf.all.log_martians" = 1; # Log spoofed packets

      # IPv6 privacy extensions (defense-in-depth — IPv6 disabled in networking.nix)
      "net.ipv6.conf.all.use_tempaddr" = lib.mkForce 2;
      "net.ipv6.conf.default.use_tempaddr" = lib.mkForce 2;

      # Kernel Protection
      "kernel.kptr_restrict" = 2; # Hide kernel pointers
      "kernel.dmesg_restrict" = 1; # Root-only dmesg
      "kernel.yama.ptrace_scope" = 1; # Parent-only ptrace
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.core.bpf_jit_harden" = 2;
      "kernel.core_pattern" = "|/bin/false";
      "kernel.sysrq" = 176; # Allow sync (16) + reboot (128) only — emergency recovery without full SysRq
      "fs.suid_dumpable" = 0;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;
      "fs.protected_hardlinks" = 1; # Prevent hardlink-based privilege escalation
      "fs.protected_symlinks" = 1; # Prevent symlink-based privilege escalation

      # PRIVACY: Prevent remote uptime fingerprinting
      "net.ipv4.tcp_timestamps" = 0;
      "kernel.perf_event_paranoid" = 3; # Prevent side-channel attacks

      # Operational security: Prevent runtime kernel replacement
      "kernel.kexec_load_disabled" = 1;

      # Exploit surface reduction
      "kernel.io_uring_disabled" = 2;
      "vm.unprivileged_userfaultfd" = 0;
      "kernel.ftrace_enabled" = 1; # Required by Netdata, perf, bpftrace — access gated by perf_event_paranoid=3

      # TCP SACK disabling — reduces TCP stack attack surface
      "net.ipv4.tcp_sack" = 0;
      "net.ipv4.tcp_dsack" = 0;
      "net.ipv4.tcp_fack" = 0;

      # ASLR hardening
      "vm.mmap_rnd_bits" = 28;
      "vm.mmap_rnd_compat_bits" = 8;

      # IPv6: disable router advertisements (rogue RA mitigation)
      "net.ipv6.conf.all.accept_ra" = 0;

      # Performance event restrictions
      "kernel.perf_cpu_time_max_percent" = 1;
      "kernel.perf_event_max_sample_rate" = 1;
    };
  };

  # === Security Packages ===
  environment.systemPackages = with pkgs; [
    lynis # Security auditing
    mat2 # Metadata removal (images, PDFs, office docs)
    exiftool
    aide # File integrity monitoring
  ];

  # SSH managed by networking.nix — not overridden here.

  # === Security Settings ===
  security = {
    apparmor.enable = true;
    lockKernelModules = false;
    protectKernelImage = true;

    sudo = {
      enable = true;
      wheelNeedsPassword = true;
      execWheelOnly = true;
      extraConfig = ''
        # SECURITY: Log all sudo commands for audit trail
        Defaults use_pty
        Defaults log_input
        Defaults log_output
        Defaults logfile="/var/log/sudo.log"
      '';
    };

    # Audit disabled — AppArmor + auditd kernel interaction causes
    # audit_log_subj_ctx panics on newer kernels
    auditd.enable = false;
    audit.enable = false;
  };

  # === /proc Hardening — Hide other users' processes ===
  fileSystems."/proc" = {
    device = "proc";
    fsType = "proc";
    options = [
      "defaults"
      "hidepid=2"
    ];
    neededForBoot = true;
  };

  # === Core Dumps ===
  systemd.coredump.enable = false;

  # === Network Firewall ===
  # Consolidated here from networking.nix — single source of truth for firewall rules.
  networking.firewall = {
    enable = true;
    logRefusedConnections = true;
    rejectPackets = false; # Drop instead of reject for stealth
    allowedTCPPorts = [ ]; # No public-facing ports — SSH restricted to Tailscale below
    allowedUDPPorts = [ ];
    allowedTCPPortRanges = [ ];
    interfaces."lo".allowedTCPPortRanges = [
      {
        from = 1024;
        to = 65535;
      }
    ]; # Dev servers on loopback only
    interfaces."tailscale0".allowedTCPPorts = [ 22 ]; # SSH via Tailscale only
    allowedUDPPortRanges = [ ];
  };

  # === Hostname Leak Prevention (nftables OUTPUT chain) ===
  networking.nftables.tables."hostname-leak-prevention" = {
    family = "inet";
    content = ''
      chain output {
        type filter hook output priority 0; policy accept;
        udp dport 5355 drop comment "Block LLMNR"
        udp dport 137-138 drop comment "Block NetBIOS (UDP)"
        tcp dport 139 drop comment "Block NetBIOS (TCP)"
        tcp dport 445 drop comment "Block SMB"
      }
    '';
  };

  services = {
    # Modern dbus-broker (faster and more secure than dbus-daemon)
    dbus.implementation = "broker";

    # Journald hardening — rate limiting, storage caps, no forwarding
    journald.extraConfig = ''
      RateLimitIntervalSec=30s
      RateLimitBurst=200
      SystemMaxUse=500M
      SystemMaxFileSize=50M
      SystemKeepFree=1G
      MaxRetentionSec=7day
      ForwardToSyslog=no
      ForwardToWall=no
      Compress=yes
      SplitMode=uid
    '';
  };

  # === Security Audit Timer ===
  systemd = {
    timers.security-audit = {
      description = "Weekly security audit";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        Unit = "security-audit.service";
      };
    };

    services.security-audit = {
      description = "Run Lynis security audit";
      serviceConfig = {
        Type = "oneshot";
        # NOTE: PrivateNetwork omitted so Lynis can audit network config
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ "/tmp" ];
        ExecStart = pkgs.writeShellScript "security-audit.sh" ''
          #!${pkgs.bash}/bin/bash
          echo 'Running Lynis audit...'
          ${pkgs.lynis}/bin/lynis audit system --quiet
          echo 'Security audit completed!'
        '';
      };
    };

    # === AIDE File Integrity Monitoring ===
    timers.aide-check = {
      description = "Weekly AIDE file integrity check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "2h";
        Unit = "aide-check.service";
      };
    };

    services.aide-check = {
      description = "Run AIDE file integrity check";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "aide-check.sh" ''
          set -euo pipefail
          AIDE_DB="/var/lib/aide"
          mkdir -p "$AIDE_DB"

          if [[ ! -f "$AIDE_DB/aide.db" ]]; then
            echo "Initializing AIDE database..."
            ${pkgs.aide}/bin/aide --config=${aideConf} --init
            mv "$AIDE_DB/aide.db.new" "$AIDE_DB/aide.db"
            echo "AIDE database initialized"
          else
            echo "Running AIDE integrity check..."
            if ! ${pkgs.aide}/bin/aide --config=${aideConf} --check; then
              echo "WARNING: AIDE detected file integrity changes!" >&2
              exit 1
            fi
            echo "AIDE check passed — no changes detected"
          fi
        '';
      };
    };
  };
}
