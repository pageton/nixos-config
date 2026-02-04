{
  lib,
  pkgs,
  hostname,
  ...
}: {
  imports = lib.optional (hostname != "server") ./languages.nix;
  programs.helix = lib.mkIf (hostname != "server") {
    enable = true;
    package = pkgs.helix;
    settings = {
      theme = "kanagawa";
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
          mode.normal = "NORMAL";
          mode.insert = "INSERT";
          mode.select = "SELECT";
        };
      };
      keys.normal = {
        space.w = ":write";
        space.q = ":quit";
        space.f = ":fmt";
        space.r = ":config-reload";
        g.a = "code_action";

        V = [
          "select_mode"
          "extend_to_line_bounds"
        ];

        C-k = [
          "extend_to_line_bounds"
          "delete_selection"
          "move_line_up"
          "paste_clipboard_before"
        ];

        D = [
          "extend_to_line_bounds"
          "delete_selection"
        ];

        C-j = [
          "extend_to_line_bounds"
          "delete_selection"
          "paste_clipboard_after"
        ];
        A-q = [":reflow"];
        C-y = ["scroll_up"];
        C-e = ["scroll_down"];

        p = [
          "delete_selection"
          "paste_clipboard_before"
        ];

        c = [
          "yank_to_clipboard"
          "delete_selection"
        ];

        y = ["yank_to_clipboard"];

        R = "redo";

        space.space = {
          b = ":sh git blame -L %{cursor_line},%{cursor_line} %{buffer_name}";
        };

        C-n = "file_picker";
        C-p = "file_picker";

        A-c = {
          u = ":pipe ccase -t upper";
          l = ":pipe ccase -t lower";
          t = ":pipe ccase -t title";
          c = ":pipe ccase -t camel";
          p = ":pipe ccase -t pascal";
          s = ":pipe ccase -t snake";
          k = ":pipe ccase -t kebab";
        };

        g.D = "no_op";
        space.i = ":toggle-option lsp.display-inlay-hints";

        g.d = {
          c = ["goto_definition"];
          v = [
            "vsplit"
            "jump_view_up"
            "goto_definition"
          ];
          h = [
            "hsplit"
            "jump_view_up"
            "goto_definition"
          ];
        };
      };
      keys.insert = {
        j.k = "normal_mode";
        C-c = "toggle_comments";
        C-l = "move_char_right";
        C-h = "move_char_left";
        C-k = "move_line_up";
        C-j = "move_line_down";
        up = "no_op";
        down = "no_op";
        left = "no_op";
        right = "no_op";
        pageup = "no_op";
        pagedown = "no_op";
        home = "no_op";
        end = "no_op";
      };

      keys.select = {
        A-c = {
          u = ":pipe ccase -t upper";
          l = ":pipe ccase -t lower";
          t = ":pipe ccase -t title";
          c = ":pipe ccase -t camel";
          p = ":pipe ccase -t pascal";
          s = ":pipe ccase -t snake";
          k = ":pipe ccase -t kebab";
        };
        y = ["yank_to_clipboard"];
        C-k = [
          "extend_to_line_bounds"
          "delete_selection"
          "move_line_up"
          "paste_clipboard_before"
        ];

        C-j = [
          "extend_to_line_bounds"
          "delete_selection"
          "paste_clipboard_after"
        ];

        p = [
          "delete_selection"
          "paste_clipboard_before"
        ];

        c = [
          "yank_to_clipboard"
          "delete_selection"
        ];

        d = ["delete_selection"];

        A-q = [":reflow"];

        g.f = {
          c = ["goto_file"];
          v = [
            "vsplit"
            "jump_view_up"
            "goto_file"
          ];

          h = [
            "hsplit"
            "jump_view_up"
            "goto_file"
          ];
        };
      };
    };
  };
}
