# Link pinned skill bundles into agents' global skill directories.

{
  lib,
  pkgs,
  mattPocockSkills,
  chromeDevToolsMcp,
  uiUxProMaxSkills,
  ...
}:

let
  # Discover all upstream SKILL.md bundles (including newly added ones on a
  # targeted input update), keeping their companion scripts/assets together.
  skillFiles = builtins.filter (file: builtins.baseNameOf file == "SKILL.md") (
    lib.filesystem.listFilesRecursive (mattPocockSkills + "/skills")
  );

  # ui-ux-pro-max bundles SKILL.md commands around Claude's plugin-root
  # placeholder, which only resolves inside a Claude plugin install. skills.sh
  # rewrote it at activation time; with store links we bake a hermetic
  # interpreter and script path into the file at build time instead.
  uiUxSrc = uiUxProMaxSkills + "/.claude/skills/ui-ux-pro-max";
  patchedUiUx = pkgs.runCommand "ui-ux-pro-max-skill" { } ''
    cp -r ${uiUxSrc} $out
    chmod -R u+w $out
    substituteInPlace $out/SKILL.md \
      --replace-fail 'python "''${CLAUDE_PLUGIN_ROOT}/.claude/skills/ui-ux-pro-max/scripts/search.py"' \
        '${pkgs.python3}/bin/python3 -B ${uiUxSrc}/scripts/search.py'
  '';

  skills =
    map (file: {
      # The directory name is plain text, not a reference to a store path.
      name = builtins.unsafeDiscardStringContext (builtins.baseNameOf (builtins.dirOf file));
      source = builtins.dirOf file;
    }) skillFiles
    ++ [
      # chrome-devtools-mcp ships several bundles; link only the CLI skill that
      # matches the pinned chrome-devtools binary on PATH (chrome-devtools/).
      {
        name = "chrome-devtools-cli";
        source = chromeDevToolsMcp + "/skills/chrome-devtools-cli";
      }
      {
        name = "app-design";
        source = ./skills/app-design;
      }
    ]
    # UI design skills (banner, brand, design-system, slides, …); upstream
    # installs every bundle under .claude/skills (skills.sh name = "*").
    ++
      map
        (file: {
          name = builtins.unsafeDiscardStringContext (builtins.baseNameOf (builtins.dirOf file));
          source =
            let
              dir = builtins.dirOf file;
            in
            if builtins.baseNameOf dir == "ui-ux-pro-max" then patchedUiUx else dir;
        })
        (
          builtins.filter (file: builtins.baseNameOf file == "SKILL.md") (
            lib.filesystem.listFilesRecursive (uiUxProMaxSkills + "/.claude/skills")
          )
        );
  skillNames = map (skill: skill.name) skills;

  # Shared by Codex (including the ChatGPT desktop Codex surface), OpenCode,
  # Pi, and Copilot. Claude Code and Antigravity require their own global dirs.
  destinations = [
    ".agents/skills"
    ".claude/skills"
    ".gemini/config/skills"
    ".gemini/antigravity-cli/skills"
  ];
in
{
  assertions = [
    {
      assertion = skills != [ ] && builtins.length skillNames == builtins.length (lib.unique skillNames);
      message = "Installed skills must contain SKILL.md files with unique directory names";
    }
  ];

  # Individual links leave manually installed skills and agent configs alone.
  home.file = lib.listToAttrs (
    lib.concatMap (
      destination:
      map (skill: {
        name = "${destination}/${skill.name}";
        value.source = skill.source;
      }) skills
    ) destinations
  );
}
