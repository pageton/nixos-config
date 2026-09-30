# Git configuration — identity, GPG signing, and opt-in secret scanning hooks.
# Identity comes from shared/constants.nix (single source of truth).
# Adapted from yzua/nixos-config home-manager git module (SSH signing → GPG).

{
  pkgs,
  constants,
  ...
}:

{
  programs.git = {
    enable = true;
    # Git is already installed via programs/terminal; HM owns only the settings.
    package = null;

    # Only universally disposable editor/OS files belong in a global ignore.
    ignores = [
      ".DS_Store"
      "Thumbs.db"
      "*~"
      "*.swp"
      "*.swo"
      ".#*"
    ];

    # GPG signing key from constants; passphrase preset by gpg.nix at login.
    signing = {
      key = constants.user.signingKey;
      signByDefault = true;
    };
    settings.user = {
      inherit (constants.user) name email;
    };

    # Git aliases restored from the old tools/git.nix module.
    settings.alias = {
      # Init
      i = "init";
      # Status and Logs
      st = "status";
      co = "checkout";
      br = "branch";
      lg = "log --oneline --graph --decorate";
      lga = "log --oneline --graph --decorate --all";

      # Add, Commit, Push, Pull
      ad = "add";
      cm = "commit -m";
      amend = "commit --amend --no-edit";
      pl = "pull";
      ps = "push";

      # Diff and Restore
      df = "diff";
      dft = "diff --cached"; # Diff staged changes
      rs = "restore";
      rst = "restore --staged"; # Restore staged changes

      # Reset and Rebase
      rb = "rebase";
      rbi = "rebase -i"; # Interactive rebase
      rset = "reset";
      rseth = "reset --hard"; # Hard reset

      # Tags
      tg = "tag";
      tga = "tag -a"; # Annotated tag

      # Clean
      cl = "clean -fd"; # Force clean untracked files and directories

      # Submodules
      sm = "submodule";
      smu = "submodule update --init --recursive";

      # Remote
      rmt = "remote";
      rmtv = "remote -v"; # Show remote URLs

      # Cherry-pick and Stash
      cp = "cherry-pick";
      stsh = "stash";
      stshl = "stash list";
      stsha = "stash apply";
      stshd = "stash drop";

      # Git Config
      cfg = "config --list";
      cfgg = "config --global --list";

      # Git Ignore
      ign = "!git check-ignore -v"; # Check ignored files
    };

    # GitHub-specific email override when the remote matches.
    includes = [
      {
        condition = "hasconfig:remote.*.url:https://github.com/**";
        contents.user.email = constants.user.githubEmail;
      }
      {
        condition = "hasconfig:remote.*.url:git@github.com:*/**";
        contents.user.email = constants.user.githubEmail;
      }
    ];

    # Secret scanning runs only in repos that opt in via a root .gitleaks.toml,
    # then chains the repo's own pre-commit hook if one exists.
    hooks.pre-commit = pkgs.writeShellScript "git-pre-commit" ''
      set -eu

      repo_root="$(git rev-parse --show-toplevel)"
      if [ -f "$repo_root/.gitleaks.toml" ]; then
        ${pkgs.gitleaks}/bin/gitleaks git --staged --no-banner --redact \
          --config "$repo_root/.gitleaks.toml" "$repo_root"
      fi

      # A global hooksPath otherwise hides the repository's own hook.
      local_hook="$(git rev-parse --git-common-dir)/hooks/pre-commit"
      if [ -x "$local_hook" ]; then
        "$local_hook" "$@"
      fi
    '';

    # Enforce conventional commit subjects (Merge/Revert/fixup exempt),
    # then chain the repo's own commit-msg hook if one exists.
    hooks.commit-msg = pkgs.writeShellScript "git-conventional-commit-msg" ''
      set -eu

      IFS= read -r subject < "$1" || true
      case "$subject" in
        Merge\ *|Revert\ *|fixup!\ *|squash!\ *|amend!\ *|Initial\ commit) ;;
        *)
          pattern='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert|wip)(\([^()]+\))?!?: .+'
          if ! [[ "$subject" =~ $pattern ]]; then
            printf 'Expected a conventional commit: <type>[optional scope][!]: <description>\n' >&2
            printf 'Types: feat fix docs style refactor perf test build ci chore revert wip\n' >&2
            exit 1
          fi
          ;;
      esac

      # core.hooksPath otherwise hides a repository's own commit-msg hook.
      local_hook="$(git rev-parse --git-common-dir)/hooks/commit-msg"
      if [ -x "$local_hook" ]; then
        "$local_hook" "$@"
      fi
    '';
  };
}
