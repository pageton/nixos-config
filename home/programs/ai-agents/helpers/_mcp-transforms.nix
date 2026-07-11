# MCP server transformation functions.
#
# Each AI agent expects a different MCP server config shape. The transforms below
# convert a shared internal representation into each agent's native format.
#
# Internal representation (defined in config.mcpServers):
#   { enable, type, command, args, url, env, headers }
#   type "local"  → stdio/local server (command + args)
#   type "remote" → HTTP/SSE server (url + optional headers)
#
# Agent-specific output shapes:
#
#   Claude (.mcp.json):
#     local:  { command = "..."; args = [...]; }   (stdio is implicit)
#     remote: { type = "http"; url = "..."; }
#
#   OpenCode / MiMoCode:
#     local:  { type = "local"; command = [ prog arg ... ]; }
#     remote: { type = "remote"; url = "..."; }
#     env key: "environment"
#
#   Antigravity:
#     local:  { command = "..."; args = [...]; }
#     remote: { httpUrl = "..."; }                  (uses httpUrl, not type)
#
#   omp (Oh My Pi):
#     local:  { type = "stdio"; command = "..."; args = [...]; }
#     remote: { type = "http"; url = "..."; }

{ cfg, lib }:

let
  inherit (cfg) mcpServers androidReMcpServers webReMcpServers;
  sharedMcpServers = mcpServers;

  # Headers are shared across all remote transforms — apply once in the factory.
  withOptionalHeaders =
    attrs: server:
    attrs // (lib.optionalAttrs (server.headers or null != null) { inherit (server) headers; });

  mkMcpTransform =
    {
      localAttrs,
      remoteAttrs,
      envKey ? "env",
      servers ? sharedMcpServers,
      includeRemoteHeaders ? true,
    }:
    lib.mapAttrs (
      _: server:
      let
        isLocal = (server.type or "local") == "local";
        remoteBase = remoteAttrs server;
        base =
          if isLocal then
            localAttrs server
          else if includeRemoteHeaders then
            withOptionalHeaders remoteBase server
          else
            remoteBase;
        envAttrs = lib.optionalAttrs (server.env or { } != { }) { ${envKey} = server.env; };
      in
      base // envAttrs
    ) (lib.filterAttrs (_: s: s.enable) servers);

  claudeMcpServers = mkMcpTransform {
    localAttrs = server: {
      inherit (server) command;
      args = server.args or [ ];
    };
    remoteAttrs = server: {
      type = "http";
      inherit (server) url;
    };
  };

  opencodeMcpServers = mkMcpTransform {
    localAttrs = server: {
      type = "local";
      command = [ server.command ] ++ (server.args or [ ]);
    };
    remoteAttrs = server: {
      type = "remote";
      inherit (server) url;
    };
    envKey = "environment";
  };

  antigravityMcpServers = mkMcpTransform {
    localAttrs = server: {
      inherit (server) command;
      args = server.args or [ ];
    };
    remoteAttrs = server: { httpUrl = server.url; };
  };

  # Oh My Pi (omp) MCP schema: stdio { type, command, args, env } or http { type, url, headers }.
  # Mirrors the Claude .mcp.json shape (command is a string, args an array).
  ompMcpServers = mkMcpTransform {
    localAttrs = server: {
      type = "stdio";
      inherit (server) command;
      args = server.args or [ ];
    };
    remoteAttrs = server: {
      type = "http";
      inherit (server) url;
    };
  };

  opencodeAndroidReMcpServers = mkMcpTransform {
    localAttrs = server: {
      type = "local";
      command = [ server.command ] ++ (server.args or [ ]);
    };
    remoteAttrs = server: {
      type = "remote";
      inherit (server) url;
    };
    envKey = "environment";
    servers = androidReMcpServers;
  };

  opencodeWebReMcpServers = mkMcpTransform {
    localAttrs = server: {
      type = "local";
      command = [ server.command ] ++ (server.args or [ ]);
    };
    remoteAttrs = server: {
      type = "remote";
      inherit (server) url;
    };
    envKey = "environment";
    servers = webReMcpServers;
  };

  # MiMo uses the same MCP format as OpenCode (shared codebase).
  mimoMcpServers = opencodeMcpServers;
in

{
  inherit
    sharedMcpServers
    claudeMcpServers
    opencodeMcpServers
    antigravityMcpServers
    opencodeAndroidReMcpServers
    opencodeWebReMcpServers
    mimoMcpServers
    ompMcpServers
    ;
}
