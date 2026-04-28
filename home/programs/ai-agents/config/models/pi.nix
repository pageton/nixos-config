# Oh My Pi (omp) coding agent default configuration.

{ ... }:

{
  programs.aiAgents.pi = {
    enable = true;

    # Extensions are deployed to ~/.omp/agent/extensions/ by files.nix.
    # Must use absolute ~/ path because PI_CODING_AGENT_DIR overrides the
    # agent directory to a profile dir (~/.omp/profiles/<name>/), which breaks
    # auto-discovery and relative path resolution.
    extensions = [ "~/.omp/agent/extensions" ];

    # Skills are deployed to ~/.omp/agent/skills/ by files.nix (custom skills)
    # and skills.nix (mirrored from ~/.claude/skills/). Same absolute path
    # fix needed as extensions.
    skills = [ "~/.omp/agent/skills" ];

    # Load pi-skills package (brave-search, browser-tools, gccli, gdcli, gmcli, transcribe, vscode, youtube-transcript)
    # These become /skill:<name> commands in omp automatically.
    packages = [ "pi-skills" ];
  };
}
