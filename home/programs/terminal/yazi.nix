# Yazi file manager configuration.
# This module configures Yazi, a terminal file manager written in Rust
{
  # Enable Yazi terminal file manager
  programs.yazi = {
    enable = true; # Enable Yazi file manager
    enableZshIntegration = true; # Enable Zsh shell integration

    settings = {
      mgr = {
        sort_by = "mtime";
        sort_dir_first = true;
        show_hidden = true;
      };

      theme = {
        manager = {
          cwd = {
            fg = "#d65d0e";
            bold = true;
          };
          hovered = {
            bg = "#3c3836";
            bold = true;
          };
          preview_hovered = {
            bg = "#3c3836";
          };
          selected = {
            fg = "#ebdbb2";
            bg = "#b16286";
            bold = true;
          };
        };

        status = {
          progress = {
            fg = "#282828";
            bg = "#b8bb26";
          };
          permissions = {
            fg = "#bdae93";
          };
        };

        select = {
          active = {
            fg = "#b8bb26";
            bold = true;
          };
        };

        input = {
          active = {
            fg = "#b8bb26";
            bold = true;
          };
          border = {
            fg = "#b8bb26";
          };
        };

        completion = {
          active = {
            fg = "#ebdbb2";
            bg = "#504945";
          };
          border = {
            fg = "#a89984";
          };
        };

        tasks = {
          border = {
            fg = "#fabd2f";
          };
          title = {
            fg = "#fabd2f";
          };
        };

        header = {
          message = {
            fg = "#ebdbb2";
          };
        };

        border = {
          style = {
            fg = "#a89984";
          };
        };

        filetype = {
          "rust" = {
            fg = "#fe8019";
          };
          "go" = {
            fg = "#83a598";
          };
          "javascript" = {
            fg = "#fabd2f";
          };
          "typescript" = {
            fg = "#fabd2f";
          };
          "python" = {
            fg = "#83a598";
          };
          "nix" = {
            fg = "#83a598";
          };
          "lua" = {
            fg = "#b16286";
          };
          "html" = {
            fg = "#fb4934";
          };
          "css" = {
            fg = "#83a598";
          };
          "json" = {
            fg = "#fabd2f";
          };
          "yaml" = {
            fg = "#fabd2f";
          };
          "toml" = {
            fg = "#fabd2f";
          };
          "markdown" = {
            fg = "#ebdbb2";
          };
          "pdf" = {
            fg = "#b16286";
          };
          "zip" = {
            fg = "#fb4934";
          };
          "tar" = {
            fg = "#fb4934";
          };
          "gz" = {
            fg = "#fb4934";
          };
          "image" = {
            fg = "#b16286";
          };
          "video" = {
            fg = "#b16286";
          };
          "audio" = {
            fg = "#b16286";
          };
          "directory" = {
            fg = "#83a598";
            bold = true;
          };
          "file" = {
            fg = "#ebdbb2";
          };
        };
      };
    };
  };
}
