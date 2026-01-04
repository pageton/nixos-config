# Virtualisation (Docker, VirtualBox, libvirt) configuration.
{
  config,
  lib,
  pkgsStable,
  user,
  ...
}: let
  cfg = config.mySystem.virtualisation;
in {
  options.mySystem.virtualisation = {
    enable = lib.mkEnableOption "Docker, VirtualBox, libvirt virtualisation";
  };

  config = lib.mkIf cfg.enable {
    # Kernel modules required for virtualization
    boot.kernelModules = [
      "kvm-intel" # Intel KVM support
      "kvm" # Kernel Virtual Machine support
    ];

    # Enable IP forwarding for container networking
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    virtualisation = {
      # Docker container runtime
      docker = {
        enable = true;
        enableOnBoot = false; # Enable Docker socket but not daemon
      };

      # VirtualBox virtualization platform
      virtualbox.host.enable = true;
      virtualbox.host.enableExtensionPack = true; # Enable USB and PXE boot support

      # Libvirt virtualization API
      libvirtd.enable = true;

      # QEMU/KVM configuration for libvirt
      libvirtd.qemu = {
        package = pkgsStable.qemu_kvm; # QEMU with KVM acceleration
        swtpm.enable = true; # Software TPM for VMs
      };

      incus = {
        enable = false;
        ui.enable = false;
      }; # Incus UI for managing virtual machines
    };

    # Add user to virtualization groups for proper access
    users.users."${user}" = {
      isNormalUser = true;
      extraGroups = [
        "docker" # Access to Docker daemon
        "vboxusers" # Access to VirtualBox VMs
        "libvirtd" # Access to libvirt VMs
        "kvm" # Access to KVM for hardware acceleration
        "incus-admin" # Access to Incus UI
        "incus" # Access to Incus VMs
      ];
    };

    # NVIDIA Container Toolkit for GPU support in Docker
    hardware.nvidia-container-toolkit.enable = true;

    # Install virtualization management tools
    environment.systemPackages = with pkgsStable; [
      virtualbox # VirtualBox command-line tools and GUI
      virt-manager # GUI for managing libvirt/QEMU/KVM virtual machines
      nvidia-container-toolkit # NVIDIA Container Toolkit CLI tools
      swtpm # Software TPM for VMs
    ];

    networking = {
      firewall = {
        # Allow libvirt default bridge through the firewall
        trustedInterfaces = [
          "virbr0"
          "incusbr0"
        ];

        # Allow DHCP and DNS for Incus containers
        allowedUDPPorts = [
          53
          67
        ];
        allowedUDPPortRanges = [
          {
            from = 67;
            to = 67;
          } # DHCP server
          {
            from = 53;
            to = 53;
          } # DNS server
        ];
      };

      # Enable NFTables for firewalling
      nftables.enable = true;
    };

    # Enable virt-manager desktop integration if needed
    programs.virt-manager.enable = true;
  };
}
