{
  pkgs,
  lib,
  hostname,
  ...
}: {
  imports = lib.optional (hostname != "server") ./languages.nix;

  programs.helix = lib.mkIf (hostname != "server") {
    enable = true;
    package = pkgs.helix;
    settings = {
      theme = "catppuccin_mocha";
      editor = {
        file-picker = {
          hidden = false;
          ignore = false;
          git-ignore = true;
        };
        whitespace.render = {
          newline = "none";
          space = "all";
          tab = "all";
        };
        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };
        cursor-shape = {
          normal = "block";
          insert = "bar";
          select = "block";
        };
        line-number = "relative";
        end-of-line-diagnostics = "hint";
        cursorline = true;
        color-modes = true;
        indent-guides.render = true;
        inline-diagnostics.cursor-line = "hint";
        scroll-lines = 6;
        statusline = {
          left = [
            "mode"
            "spacer"
            "version-control"
            "file-name"
            "file-modification-indicator"
          ];
          right = [
            "diagnostics"
            "workspace-diagnostics"
            "selections"
            "position"
            "file-encoding"
            "file-type"
          ];
          mode = {
            normal = "NORMAL";
            insert = "INSERT";
            select = "SELECT";
          };
        };
      };
      # باقي الـ keys كما هي...
      keys = {
        # ... كل الـ keys التي كتبتها
      };
    };
  };
}
