# Git version control configuration.
# This module configures Git with user settings, GPG signing, global ignores,
# and useful aliases for efficient development workflow.
{
  programs.git = {
    enable = true;
    signing = {
      key = "5684AD6E4045F283";
      signByDefault = true;
    };

    ignores = [
      ".cache/"
      ".DS_Store"
      ".idea/"
      "*.swp"
      "*.elc"
      "auto-save-list"
      ".direnv/"
      "node_modules"
      "result"
      "result-*"
    ];

    settings = {
      user = {
        name = "Sadiq";
        email = "pageton@proton.me";
      };
      core = {
        editor = "nvim";
      };
      init = {
        defaultBranch = "main";
      };
      pull.rebase = false;
      push.autoSetupRemote = true;
      merge.conflictStyle = "diff3";
      credential.helper = "!gh auth git-credential";

      alias = {
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
    };
  };
}
