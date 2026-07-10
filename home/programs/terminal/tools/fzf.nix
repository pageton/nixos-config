# Fzf configuration using Stylix theme colors.

_:

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    # Atuin owns Ctrl-R (sourced after fzf); suppress fzf's history widget to
    # clear the Home-Manager Ctrl-R conflict warning. fzf keeps Ctrl-T / Alt-C.
    historyWidget.command = "";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];
  };
}
