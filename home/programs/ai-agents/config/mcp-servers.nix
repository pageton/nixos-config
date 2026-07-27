# MCP server definitions and logging configuration.

{
  config,
  constants,
  lib,
  ...
}:

let
  cfg = config.programs.aiAgents;
  zai = import ../helpers/_zai-services.nix { inherit constants; };

  mkZaiRemoteMcp = path: {
    enable = true;
    type = "remote";
    url = "${zai.baseUrl}/${path}/mcp";
    headers = {
      Authorization = "Bearer {env:ZAI_API_KEY}";
    };
  };

  # Derive Z.AI MCP server entries from the services registry — single source of truth.
  zaiMcpServers = builtins.listToAttrs (
    map (svc: {
      name = svc.mcpKey;
      value = mkZaiRemoteMcp svc.name;
    }) zai.services
  );

  # Allowed paths for terminal and filesystem MCP servers.
  mcpAllowedPaths = [
    "${config.home.homeDirectory}/Documents"
    "${config.home.homeDirectory}/Downloads"
    "${config.home.homeDirectory}/.cache/android-re"
  ];

in
{
  programs.aiAgents = {
    mcpServers =
      zaiMcpServers
      // {
        context7 = {
          enable = true;
          command = "bunx";
          args = [
            "@upstash/context7-mcp@2.1.2"
            "--api-key"
            "__CONTEXT7_API_KEY_PLACEHOLDER__"
          ];
        };

        github = {
          enable = true;
          command = "github-mcp-server";
          args = [
            "stdio"
            "--toolsets=default,actions,code_security,dependabot,secret_protection"
          ];
          env = {
            GITHUB_PERSONAL_ACCESS_TOKEN = "__GITHUB_TOKEN_PLACEHOLDER__"; # patched at activation via gh auth token
          };
        };

        semgrep = {
          enable = true;
          command = "semgrep";
          args = [ "mcp" ];
        };

        chrome-devtools = {
          enable = true;
          command = "bunx";
          args = [ "chrome-devtools-mcp@1.5.0" ];
        };

        sequential-thinking = {
          enable = true;
          command = "bunx";
          args = [ "@modelcontextprotocol/server-sequential-thinking@2026.7.4" ];
        };

        playwright = {
          enable = true;
          command = "bunx";
          args = [ "@playwright/mcp@latest" ];
        };

        brave-search = {
          enable = false;
          command = "bunx";
          args = [ "@brave/brave-search-mcp-server@2.0.85" ];
          env = {
            # Set BRAVE_API_KEY manually after enabling this server.
            BRAVE_API_KEY = "";
          };
        };

        database = {
          enable = false;
          command = "bunx";
          args = [ "@executeautomation/database-server@1.1.0" ];
        };

        # ── General-purpose MCP servers (available to all agents) ──

        terminal = {
          enable = true;
          command = "bunx";
          args = [
            "@dillip285/mcp-terminal"
            "--allowed-paths"
            "${builtins.concatStringsSep ":" mcpAllowedPaths}"
          ];
        };

        tmux = {
          enable = true;
          command = "bunx";
          args = [
            "tmux-mcp"
            "--shell-type=zsh"
          ];
        };

        ripgrep = {
          enable = true;
          command = "bunx";
          args = [ "mcp-ripgrep" ];
        };

        fetch = {
          enable = true;
          command = "uvx";
          args = [ "mcp-server-fetch" ];
        };

        superpowers = {
          enable = true;
          command = "bunx";
          args = [ "superpowers-mcp" ];
        };

        ssh = {
          enable = false;
          command = "bunx";
          args = [ "@fangjunjie/ssh-mcp-server" ];
        };

        filesystem = {
          enable = true;
          command = "bunx";
          args = [ "@modelcontextprotocol/server-filesystem" ] ++ mcpAllowedPaths;
        };

        # ── TON Blockchain MCP ──

        ton = {
          enable = true;
          command = "npx";
          args = [
            "-y"
            "@ton/mcp@alpha"
          ];
        };

      }
      // lib.optionalAttrs cfg.agentmemory.enable {
        agentmemory = {
          enable = true;
          timeout = cfg.agentmemory.timeout;
          command = "bunx";
          args = [
            "--silent"
            "@agentmemory/mcp@${cfg.agentmemory.version}"
          ];
          env = {
            AGENTMEMORY_URL = cfg.agentmemory.url;
          };
        };
      }
      // lib.optionalAttrs cfg.codegraph.enable {
        codegraph = {
          enable = true;
          command = "codegraph";
          args = [
            "serve"
            "--mcp"
          ];
        };
      }
      // lib.optionalAttrs cfg.serena.enable {
        serena = {
          enable = true;
          command = "serena";
          args = [
            "start-mcp-server"
            "--context"
            "claude-code"
            "--project-from-cwd"
          ];
        };
      };

    logging = {
      enable = true;
      directory = "${config.xdg.dataHome}/ai-agents/logs";
      notifyOnError = true;
      retentionDays = 30;

      enableOtel = false;
    };
  };
}
