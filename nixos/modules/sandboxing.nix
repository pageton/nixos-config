# Sandbox and isolation module for application containment.
# Provides Firejail and bubblewrap for secure application sandboxing.
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Custom module options for sandboxing configuration
  options.mySystem.sandboxing = {
    enable = lib.mkEnableOption "application sandboxing with Firejail and bubblewrap";

    enableUserNamespaces = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable unprivileged user namespaces for Firejail and bubblewrap";
    };

    enableWrappedBinaries = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Firejail's wrapped binaries for automatic sandboxing";
    };
  };

  # Configuration applied when sandboxing is enabled
  config = lib.mkIf config.mySystem.sandboxing.enable {
    # Firejail - Linux namespaces and seccomp-bpf sandbox
    programs.firejail = {
      enable = true;
      wrappedBinaries = lib.mkIf config.mySystem.sandboxing.enableWrappedBinaries {};
    };

    # Remove Firejail's librewolf and tor-browser profiles (don't work with NixOS paths)
    environment = {
      etc."firejail/librewolf.profile".enable = false;
      etc."firejail/tor-browser.profile".enable = false;

      # System packages for sandboxing
      systemPackages = with pkgs; [
        firejail # Application sandboxing tool
        bubblewrap # User-space sandbox tool (provides bwrap command)
        squashfsTools # For Firejail squashfs profiles
      ];
    };

    # User namespaces for unprivileged operation
    boot.kernel.sysctl = lib.mkIf config.mySystem.sandboxing.enableUserNamespaces {
      "kernel.unprivileged_userns_clone" = 1;
      "user.max_user_namespaces" = 256;
    };
  };
}
