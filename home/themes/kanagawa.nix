{
  lib,
  pkgs,
  config,
  inputs,
  system,
  ...
}: {
  options.theme = lib.mkOption {
    type = lib.types.attrs;
    default = {
      rounding = 15;
      gaps-in = 8;
      gaps-out = 8 * 2;
      active-opacity = 1.0;
      inactive-opacity = 1.0;
      blur = true;
      border-size = 3;
      animation-speed = "medium"; # "fast" | "medium" | "slow"
      fetch = "none"; # "nerdfetch" | "neofetch" | "pfetch" | "none"
      textColorOnWallpaper = config.lib.stylix.colors.base05; # Color of the text displayed on the wallpaper (Lockscreen, display manager, ...)

      bar = {
        # Hyprpanel
        position = "top"; # "top" | "bottom"
        transparent = true;
        transparentButtons = false;
        floating = true;
      };
    };
    description = "Theme configuration options";
  };

  config.stylix = {
    enable = true;
    enableReleaseChecks = false;

    targets = {
      # Enable core desktop theming
      gtk.enable = true; # Apply theme to GTK applications
      qt.enable = true; # Apply theme to Qt applications
      helix.enable = false;
      neovim.enable = false;
      nvf.enable = false;
      alacritty.enable = false;
      hyprpanel.enable = false;
      waybar.enable = false;
      nixcord.enable = false;
      # Configure Zen Browser theming
      zen-browser = {
        enable = true; # Enable Zen Browser theming
        profileNames = ["default"]; # Apply to default profile
      };
    };

    # Kanagawa Wave
    # See https://tinted-theming.github.io/tinted-gallery/ for more schemes
    base16Scheme = {
      base00 = "1F1F28"; # Default Background (sumiInk1)
      base01 = "16161D"; # Lighter Background (sumiInk0)
      base02 = "223249"; # Selection Background (winterBlue)
      base03 = "54546D"; # Comments, Invisibles (sumiInk6)
      base04 = "727169"; # Dark Foreground (oldWhite)
      base05 = "DCD7BA"; # Default Foreground (fujiWhite)
      base06 = "C8C093"; # Light Foreground (oldWhite lighter)
      base07 = "717C7C"; # Light Background
      base08 = "C34043"; # Variables, XML Tags (autumnRed)
      base09 = "FFA066"; # Integers, Boolean, Constants (surimiOrange)
      base0A = "C0A36E"; # Classes, Search Text (boatYellow2)
      base0B = "76946A"; # Strings, Diff Inserted (autumnGreen)
      base0C = "6A9589"; # Support, RegExp (waveAqua1)
      base0D = "7E9CD8"; # Functions, Methods, Accent (crystalBlue)
      base0E = "957FB8"; # Keywords, Diff Changed (oniViolet)
      base0F = "D27E99"; # Deprecated (sakuraPink)
    };

    icons = {
      enable = true;
      package = pkgs.gruvbox-plus-icons;
      dark = "Gruvbox-Plus-Dark";
      light = "Gruvbox-Plus-Light";
    };

    cursor = {
      name = "phinger-cursors-light";
      package = pkgs.phinger-cursors;
      size = 20;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrains Mono Nerd Font";
      };
      sansSerif = {
        package = pkgs.source-sans-pro;
        name = "Source Sans Pro";
      };
      serif = config.stylix.fonts.sansSerif;
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 13;
        desktop = 13;
        popups = 13;
        terminal = 13;
      };
    };

    polarity = "dark";
    image = "${
      inputs.nix-wallpaper.packages.${system}.default.override {
        backgroundColor = "#1F1F28"; # sumiInk1
        logoColors = {
          color0 = "#7E9CD8"; # crystalBlue
          color1 = "#957FB8"; # oniViolet
          color2 = "#7E9CD8"; # crystalBlue
          color3 = "#957FB8"; # oniViolet
          color4 = "#7E9CD8"; # crystalBlue
          color5 = "#957FB8"; # oniViolet
        };
      }
    }/share/wallpapers/nixos-wallpaper.png";
  };
}
