# Android RE agent-specific MCP servers.
# These are only loaded into the android-re agent's runtime config (oc*are, mi*are),
# not shared with other agents (regular opencode, mimo, claude-code, omp).
{
  config,
  constants,
  pkgs,
  ...
}:
let
  # jpype (used by pyghidra) needs libstdc++.so.6 at runtime.
  gccLib = pkgs.stdenv.cc.cc.lib;
  jdkBin = "${pkgs.jdk}/bin";

  # Wrapper that prepends the JDK to PATH so pyghidra can find java.
  pyghidraMcpWrapper = pkgs.writeShellScriptBin "pyghidra-mcp" ''
    export PATH="${jdkBin}:$PATH"
    export GHIDRA_INSTALL_DIR="${pkgs.ghidra-bin}/lib/ghidra"
    export LD_LIBRARY_PATH="${gccLib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    exec uvx pyghidra-mcp "$@"
  '';

  # ReVa (Reverse Engineering Assistant) — AI-optimized Ghidra MCP.
  # Requires the ReVa Ghidra extension JAR on the PyGhidra classpath.
  # PyGhidra does not auto-load system extension JARs in headless mode, so we
  # use a custom Python launcher (scripts/ai/reva-mcp-launcher.py) that
  # explicitly adds the JAR via PyGhidraLauncher.add_class_files().
  revaExtension = pkgs.fetchurl {
    url = "https://github.com/cyberkaida/reverse-engineering-assistant/releases/download/v7.3.0/ghidra_12.1_PUBLIC_20260613_reverse-engineering-assistant.zip";
    hash = "sha256-rCYNj7g5Fos4G2Jgj9mAIuXQS5jkhjn3V0Mqj0JAa0U=";
  };

  # Copy Ghidra into a writable derivation and install the ReVa extension
  # into the system Extensions/Ghidra/ directory.
  ghidraWithReVa = pkgs.runCommand "ghidra-with-reva" { nativeBuildInputs = [ pkgs.unzip ]; } ''
    cp -r ${pkgs.ghidra-bin}/lib/ghidra $out
    chmod -R +w $out
    mkdir -p $out/Extensions/Ghidra
    unzip -o ${revaExtension} -d $out/Extensions/Ghidra/ >/dev/null
  '';

  revaLauncherScript = "${config.home.homeDirectory}/${constants.paths.scripts}/ai/reva-mcp-launcher.py";

  revaMcpWrapper = pkgs.writeShellScriptBin "mcp-reva" ''
    export PATH="${jdkBin}:$PATH"
    export GHIDRA_INSTALL_DIR="${ghidraWithReVa}"
    export LD_LIBRARY_PATH="${gccLib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    exec uvx --from reverse-engineering-assistant --with pyghidra python3 ${revaLauncherScript} "$@"
  '';
in
{
  programs.aiAgents = {
    androidReMcpServers = {
      pyghidra-mcp = {
        enable = true;
        command = "${pyghidraMcpWrapper}/bin/pyghidra-mcp";
        # NOTE: Ghidra's ProjectLocator rejects path segments starting with '.'
        args = [
          "--project-path"
          "${config.home.homeDirectory}/Downloads/android-re-tools/pyghidra-mcp"
        ];
      };

      apktool-mcp-server = {
        enable = true;
        command = "uvx";
        args = [ "apktool-mcp" ];
      };

      reva = {
        enable = true;
        command = "${revaMcpWrapper}/bin/mcp-reva";
        args = [ ];
      };
    };
  };
}
