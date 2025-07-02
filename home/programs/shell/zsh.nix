{ config, ... }:

{
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";

    oh-my-zsh = {
      enable = true;
      custom = builtins.toString ./custom_omz_dir;
      theme = "oxide";

      plugins = [
        "git"
        "sudo"
      ];
    };
  };
}
