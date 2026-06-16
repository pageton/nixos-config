# Antigravity CLI (agy) model, theme, hooks, and settings configuration.
# agy reads from ~/.gemini/settings.json — inherits the Gemini CLI config layout.

{ config, lib, ... }:

let
  formatters = import ../../helpers/_formatters.nix;
  destructiveRules = import ../../helpers/_destructive-rules.nix;

  formatterCaseBranches = builtins.concatStringsSep "\n                    " (
    map (
      f:
      let
        extPattern = builtins.concatStringsSep "|" (map (e: "*.${e}") f.extensions);
      in
      ''${extPattern}) command -v ${f.tool} >/dev/null 2>&1 && ${f.command} "$FILE_PATH" 2>/dev/null ;;''
    ) formatters.formatters
  );

  autoFormatHook = ''INPUT=$(cat); FILE_PATH=$(echo "$INPUT" | jq -r '.arguments.path // ""'); if [ -n "$FILE_PATH" ]; then case "$FILE_PATH" in ${formatterCaseBranches} esac; fi; echo "$INPUT"'';

  catppuccinTheme = {
    name = "Catppuccin Mocha";
    type = "custom";
    background = {
      primary = "#1E1E2E";
      diff = {
        added = "#313244";
        removed = "#45475A";
      };
    };
    border = {
      default = "#585B70";
      focused = "#89B4FA";
    };
    status = {
      error = "#F38BA8";
      success = "#A6E3A1";
      warning = "#F9E2AF";
    };
    text = {
      accent = "#CBA6F7";
      link = "#89B4FA";
      primary = "#CDD6F4";
      secondary = "#A6ADC8";
    };
    ui = {
      comment = "#A6ADC8";
      gradient = [
        "#F38BA8"
        "#FAB387"
        "#F9E2AF"
      ];
      symbol = "#94E2D5";
    };
  };
in
{
  programs.aiAgents.antigravity = {
    enable = true;

    theme = "Catppuccin Mocha";

    extraSettings = {
      codeExecution = true;
      searchGrounding = true;

      context = {
        discoveryMaxDirs = 300;
        fileFiltering = {
          enableFuzzySearch = true;
          enableRecursiveFileSearch = true;
          respectGeminiIgnore = true;
          respectGitIgnore = true;
        };
        fileName = [
          "GEMINI.md"
          "AGENTS.md"
        ];
        importFormat = "markdown";
        loadMemoryFromIncludeDirectories = true;
      };

      experimental = {
        enableAgents = true;
        worktrees = true;
      };

      general = {
        checkpointing.enabled = false;
        defaultApprovalMode = "auto_edit";
        enableAutoUpdate = true;
        enableAutoUpdateNotification = true;
        plan.modelRouting = true;
        sessionRetention = {
          enabled = true;
          maxAge = "30d";
        };
        vimMode = true;
      };

      hooks = {
        AfterTool = [
          {
            hooks = [
              {
                name = "auto-format";
                command = autoFormatHook;
                timeout = 10000;
                type = "command";
              }
            ];
            matcher = "write_file|replace";
          }
        ];
      };

      model = {
        compressionThreshold = 0.75;
        name = "gemini-3-pro-preview";
      };

      modelConfigs.customAliases = {
        auto.modelConfig = {
          generateContentConfig = { };
          model = "auto";
        };
        code.modelConfig = {
          generateContentConfig = {
            maxOutputTokens = 65536;
            thinkingConfig.thinkingLevel = "HIGH";
          };
          model = "gemini-3-pro-preview";
        };
        deep.modelConfig = {
          generateContentConfig.thinkingConfig.thinkingLevel = "HIGH";
          model = "gemini-3-pro-preview";
        };
        fast.modelConfig = {
          generateContentConfig = {
            maxOutputTokens = 8192;
            temperature = 0;
          };
          model = "gemini-2.5-flash-lite";
        };
        flash.modelConfig = {
          generateContentConfig = {
            maxOutputTokens = 16384;
            temperature = 0;
          };
          model = "gemini-2.5-flash";
        };
      };

      policyPaths = [ "$HOME/.gemini/policies" ];

      privacy.usageStatisticsEnabled = false;

      security = {
        auth.selectedType = "gemini-api-key";
        folderTrust.enabled = true;
      };

      skills.enabled = true;

      tools = {
        sandbox = false;
        sandboxNetworkAccess = false;
        shell.showColor = true;
        useRipgrep = true;
      };

      ui = {
        hideBanner = true;
        hideTips = true;
        showLineNumbers = true;
        theme = "Catppuccin Mocha";
        customThemes.Catppuccin-Mocha = catppuccinTheme;
      };
    };
  };
}
