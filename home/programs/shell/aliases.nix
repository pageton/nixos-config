{
  programs.zsh.shellAliases =
    let
      editor = "nvim";
    in
    {
      # navigation
      ls = "eza --icons --group-directories-first";
      ll = "eza -l --icons --group-directories-first --header";
      la = "eza -la --icons --group-directories-first --header";
      lt = "eza --tree --level=2 --icons";
      etree = "eza --tree --level=1 --icons";
      cd = "z";
      ci = "zi";
      c = "clear";

      # Quick navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";

      # Enhanced search and text processing
      find = "fd";
      grep = "rg";
      hq = "htmlq";
      cat = "bat --style=auto";
      less = "bat --style=auto --paging=always";

      # Advanced search
      rgi = "rg -i"; # case insensitive
      rgf = "rg --files-with-matches"; # only show filenames
      rgc = "rg --count"; # count matches

      # Code info
      tk = "tokei";
      tf = "tokei --files";

      # Files
      fs = "fselect";

      # Editors
      n = "${editor}";
      v = "${editor}";
      se = "sudoedit";

      # System info
      ff = "fastfetch";
      mf = "microfetch";
      of = "onefetch";

      # General tools
      lg = "lazygit";
      ld = "lazydocker";

      # AI tools
      gemi = "gemini";
      open = "opencode";

      # Nix tools
      ns = "nix-shell";
      nd = "nix develop --command zsh";
      nfu = "nix flake update";
      nfs = "nix flake show";
      nfi = "nix flake init";

      # System management
      reboot = "sudo reboot";
      shutdown = "sudo shutdown now";

      # Process management
      psg = "ps aux | grep";
      killall = "pkill -f";

      # Network utilities
      ports = "lsof -i -P -n | grep LISTEN";
      myip = "curl -s https://ipinfo.io/ip";
      localip = "ip route get 1.1.1.1 | awk '{print $7}'";

      # Disk usage
      du1 = "du -h --max-depth=1";
      ducks = "du -cks * | sort -rn | head";
    };
}
