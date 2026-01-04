# Environment variables and session settings.
{user, ...}: {
  environment.sessionVariables = rec {
    # Default terminal emulator for applications that need one
    TERMINAL = "alacritty";

    # Default text editor for applications that need one
    EDITOR = "nvim";

    # XDG Base Directory specification for user binaries
    XDG_BIN_HOME = "$HOME/.local/bin";

    # XDG data directories - include Flatpak exports for app launchers
    # This ensures wofi and other launchers can find Flatpak applications
    XDG_DATA_DIRS = [
      "/var/lib/flatpak/exports/share"
      "/home/${user}/.local/share/flatpak/exports/share"
      "/run/current-system/sw/share"
    ];

    # System PATH with additional directories
    PATH = ["${XDG_BIN_HOME}"];
  };
}
