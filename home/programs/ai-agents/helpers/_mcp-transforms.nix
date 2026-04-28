# MCP server transformation functions.

{ cfg, lib }:

let
  sharedMcpServers = cfg.mcpServers;

  # Headers are shared across all remote transforms — apply once in the factory.
  withOptionalHeaders =
    attrs: server:
    attrs // (lib.optionalAttrs (server.headers or null != null) { inherit (server) headers; });

  mkMcpTransform =
    {
      localAttrs,
      remoteAttrs,
      envKey ? "env",
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
    ) (lib.filterAttrs (_: s: s.enable) sharedMcpServers);

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

  geminiMcpServers = mkMcpTransform {
    localAttrs = server: {
      inherit (server) command;
      args = server.args or [ ];
    };
    remoteAttrs = server: { httpUrl = server.url; };
  };

  # Forge uses the same .mcp.json format as Claude but its rmcp HTTP client doesn't send
  # Accept: text/event-stream, causing 400 errors on remote MCP servers that require it.
  # Use mcp-remote as a local stdio proxy for remote servers instead.
  #
  # Header values use {env:VAR} syntax in shared config. mcp-remote expects headers
  # in the form "Name: value" and expands environment variables from the env block.
  # For example, "Bearer {env:ZAI_API_KEY}" becomes "Bearer ${ZAI_API_KEY}".
  # Activation later patches __ZAI_API_KEY_PLACEHOLDER__ with the decrypted secret.
  forgeRemoteToLocal =
    server:
    let
      toShellEnvExpansion = val: builtins.replaceStrings [ "{env:" "}" ] [ "\${" "}" ] val;
      extractEnvVars = val: builtins.match ".*[{]env:([A-Za-z_][A-Za-z0-9_]*)[}].*" val;
      headerEntries = lib.flatten (
        lib.mapAttrsToList (
          name: value:
          let
            match = extractEnvVars value;
          in
          lib.optional (match != null) {
            arg = "${name}: ${toShellEnvExpansion value}";
            envName = builtins.elemAt match 0;
          }
        ) (server.headers or { })
      );
      headerArgs = lib.concatMap (e: [
        "--header"
        e.arg
      ]) headerEntries;
      headerEnv = builtins.listToAttrs (
        map (e: {
          name = e.envName;
          value = "__${e.envName}_PLACEHOLDER__";
        }) headerEntries
      );
    in
    {
      command = "npx";
      args = [
        "mcp-remote"
        server.url
      ]
      ++ headerArgs;
      env = headerEnv;
    };

  forgeMcpServers = mkMcpTransform {
    localAttrs = server: {
      inherit (server) command;
      args = server.args or [ ];
    };
    remoteAttrs = forgeRemoteToLocal;
    includeRemoteHeaders = false;
  };

  # OMP native MCP server config (mcp.json format).
  # OMP discovers ~/.omp/agent/mcp.json automatically and supports
  # stdio, http, and sse transports natively.
  ompMcpServers = mkMcpTransform {
    localAttrs = server: {
      inherit (server) command;
      args = server.args or [ ];
    };
    remoteAttrs = server: {
      type = "http";
      inherit (server) url;
    };
  };

in
{
  inherit
    sharedMcpServers
    claudeMcpServers
    opencodeMcpServers
    geminiMcpServers
    forgeMcpServers
    ompMcpServers
    ;
}