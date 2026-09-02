# Yazi terminal file manager with image preview and Lua plugins.

{ constants, pkgs, ... }:

{
  # file package provided by home.packages (utilities.nix)
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";

    plugins = {
      inherit (pkgs.yaziPlugins)
        git
        diff
        full-border
        piper
        ouch
        convert
        jump-to-char
        wl-clipboard
        ;
      batch-rename-gui = pkgs.yaziPlugins.mkYaziPlugin {
        pname = "batch-rename-gui.yazi";
        version = "0-unstable-2025-07-08";
        src = pkgs.fetchFromGitHub {
          owner = "pakhromov";
          repo = "batch-rename-gui.yazi";
          rev = "5c2d5aa349948b6ab405a171541faab44751f6a5";
          hash = "sha256-3RviPY3WOyYi5GWXWRYMWp6VLxCe5cuJX7Kb7AyWxLE=";
        };
      };
    };

    initLua = ''
      require("full-border"):setup()
      require("git"):setup()
    '';

    keymap.manager.prepend_keymap = [
      {
        on = [
          "g"
          "d"
        ];
        run = "plugin diff";
        desc = "Diff selected file with hovered file";
      }
      {
        on = [ "C" ];
        run = "plugin ouch";
        desc = "Compress selection";
      }
      {
        on = [ "X" ];
        run = "plugin ouch --args=extract";
        desc = "Extract archive";
      }
      {
        on = [
          "c"
          "p"
        ];
        run = "plugin convert -- --extension='png'";
        desc = "Convert to PNG";
      }
      {
        on = [
          "c"
          "j"
        ];
        run = "plugin convert -- --extension='jpg'";
        desc = "Convert to JPG";
      }
      {
        on = [
          "c"
          "w"
        ];
        run = "plugin convert -- --extension='webp'";
        desc = "Convert to WebP";
      }
      {
        on = [ "F" ];
        run = "plugin jump-to-char";
        desc = "Jump to char";
      }
      {
        on = [ "Y" ];
        run = "plugin wl-clipboard";
        desc = "Copy to clipboard (Wayland)";
      }
      {
        on = [ "B" ];
        run = "plugin batch-rename-gui";
        desc = "Batch rename (GUI)";
      }
    ];

    settings = {
      manager = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
        linemode = "size";
        show_symlink = true;
      };

      preview = {
        max_width = 1000;
        max_height = 1000;
        image_filter = "triangle";
        image_quality = 75;
      };

      opener = {
        edit = [
          {
            run = ''${constants.editor} "$@"'';
            block = false;
            desc = "Open in editor";
          }
        ];
        open = [
          {
            run = ''xdg-open "$@"'';
            desc = "Open with system default";
          }
        ];
      };

      plugin = {
        prepend_fetchers = [
          {
            url = "*";
            run = "git";
            group = "git";
          }
          {
            url = "*/";
            run = "git";
            group = "git";
          }
        ];

        prepend_previewers = [
          {
            url = "*.md";
            run = ''piper -- CLICOLOR_FORCE=1 glow -w=$w -s=dark "$1"'';
          }
        ];

        prepend_openers = [
          {
            url = "*.{zip,tar,gz,bz2,xz,7z,rar}";
            run = "ouch";
          }
        ];
      };
    };
  };
}
