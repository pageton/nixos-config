# MCP server definitions and logging configuration.

{
  config,
  constants,
  lib,
  pkgs,
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
          # No --autoConnect: let the server launch & manage its own Chrome.
          # --autoConnect requires a manually-started Chrome 144+ with remote
          # debugging enabled (chrome://inspect/#remote-debugging); absent that,
          # the CDP socket drops → "Connection closed" (-32000).
          args = [
            "chrome-devtools-mcp@1.5.0" # Pinned — was @latest, caused registry check on every agent session
          ];
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
          enable = false; # Opt-in — requires Brave Search API key
          command = "bunx";
          args = [ "@brave/brave-search-mcp-server@2.0.85" ];
          env = {
            BRAVE_API_KEY = "__BRAVE_API_KEY_PLACEHOLDER__";
          };
        };

        database = {
          enable = false; # Opt-in — requires DB path or connection string
          command = "bunx";
          args = [ "@executeautomation/database-server@1.1.0" ];
        };
      }
      // lib.optionalAttrs cfg.agentmemory.enable {
        agentmemory = {
          enable = true;
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
