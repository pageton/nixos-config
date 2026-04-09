# Environment variables and session settings.
{ user, constants, ... }:
{
  environment.sessionVariables = rec {
    # Default terminal emulator for applications that need one
    TERMINAL = constants.terminal;

    # Default text editor for applications that need one
    EDITOR = constants.editor;

    # Fix Java Swing/AWT applications (e.g. BurpSuite) on Wayland
    _JAVA_AWT_WM_NONREPARENTING = "1";

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
    PATH = [ "${XDG_BIN_HOME}" ];
  };
}
