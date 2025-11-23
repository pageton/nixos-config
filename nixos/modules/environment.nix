# Environment variables and session settings.
# This module configures system-wide environment variables that affect
# application behavior, default programs, and system paths.

{
  environment.sessionVariables = rec {
    # Default terminal emulator for applications that need one
    TERMINAL = "alacritty";

    # Default text editor for applications that need one
    EDITOR = "hx";

    # XDG Base Directory specification for user binaries
    XDG_BIN_HOME = "$HOME/.local/bin";

    # System PATH with additional directories
    PATH = [
      "${XDG_BIN_HOME}" # Include user local bin directory in PATH
    ];
  };
}
