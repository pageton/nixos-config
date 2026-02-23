# Starship cross-shell prompt with Kanagawa theming.
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      format = "$directory$git_branch$git_status$nix_shell$python$nodejs$golang$rust$docker_context$cmd_duration$line_break$character";
      add_newline = false;

      character = {
        success_symbol = "[λ](bold #76946A)"; # autumnGreen
        error_symbol = "[λ](bold #C34043)"; # autumnRed
        vimcmd_symbol = "[](bold #76946A)"; # autumnGreen
      };

      directory = {
        style = "bold #7E9CD8"; # crystalBlue
        truncation_length = 3;
        truncate_to_repo = true;
        fish_style_pwd_dir_length = 1;
      };

      git_branch = {
        symbol = " ";
        style = "bold #6A9589"; # waveAqua1
        format = "[$symbol$branch]($style) ";
      };

      git_status = {
        style = "bold #C0A36E"; # boatYellow2
        format = "[$all_status$ahead_behind]($style) ";
        conflicted = "=";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        untracked = "?";
        stashed = "\\$";
        modified = "!";
        staged = "+";
        renamed = "»";
        deleted = "✘";
      };

      nix_shell = {
        symbol = " ";
        style = "bold #7E9CD8"; # crystalBlue
        format = "[$symbol$state]($style) ";
        heuristic = true;
      };

      python = {
        symbol = " ";
        style = "bold #C0A36E"; # boatYellow2
        format = "[$symbol$version]($style) ";
      };

      nodejs = {
        symbol = " ";
        style = "bold #76946A"; # autumnGreen
        format = "[$symbol$version]($style) ";
      };

      golang = {
        symbol = " ";
        style = "bold #6A9589"; # waveAqua1
        format = "[$symbol$version]($style) ";
      };

      rust = {
        symbol = " ";
        style = "bold #C34043"; # autumnRed
        format = "[$symbol$version]($style) ";
      };

      docker_context = {
        symbol = " ";
        style = "bold #7E9CD8"; # crystalBlue
        format = "[$symbol$context]($style) ";
        only_with_files = true;
      };

      cmd_duration = {
        min_time = 2000;
        style = "bold #FFA066"; # surimiOrange
        format = "[$duration]($style) ";
      };

      aws.disabled = true;
      gcloud.disabled = true;
      azure.disabled = true;
      package.disabled = true;
    };
  };
}
