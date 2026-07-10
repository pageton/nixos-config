# Android RE agent-specific MCP servers.
# These are only loaded into the android-re agent's runtime config,
# not shared with other agents (build, plan, review, etc.).
{ config, pkgs, ... }:
let
  # jpype (used by pyghidra) needs libstdc++.so.6 at runtime.
  # On NixOS the FHS path is not available to uvx, so we inject
  # LD_LIBRARY_PATH from the system gcc lib output.
  gccLib = pkgs.stdenv.cc.cc.lib;

  # Ghidra requires java on PATH — uvx launches in a minimal env without it.
  jdkBin = "${pkgs.jdk}/bin";

  # Wrapper that prepends the JDK to PATH so pyghidra can find java.
  pyghidraMcpWrapper = pkgs.writeShellScriptBin "pyghidra-mcp" ''
    export PATH="${jdkBin}:$PATH"
    export GHIDRA_INSTALL_DIR="${pkgs.ghidra-bin}/lib/ghidra"
    export LD_LIBRARY_PATH="${gccLib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    exec uvx pyghidra-mcp "$@"
  '';
in
{
  programs.aiAgents = {
    androidReMcpServers = {
      pyghidra-mcp = {
        enable = true;
        command = "${pyghidraMcpWrapper}/bin/pyghidra-mcp";
        args = [
          "--project-path"
          "${config.xdg.dataHome}/pyghidra-mcp/android-re"
        ];
      };

      apktool-mcp-server = {
        enable = true;
        command = "uvx";
        args = [ "apktool-mcp" ];
      };
    };
  };
}
