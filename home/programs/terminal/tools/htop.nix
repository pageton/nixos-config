# Htop (interactive process viewer) configuration.

{
  programs.htop = {
    enable = true; # Enable htop for process monitoring

    settings = {
      tree_view = 1; # Enable tree view to show process hierarchy
    };
  };
}
