# Session lifecycle hooks — start, end, compact, notifications, permissions, failures,
# AGENTS.md context loader, git diff summary.

{ mkPassthroughHook }:

{
  PermissionRequest = [
    (mkPassthroughHook {
      body = ''
        TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // .tool // "unknown"')
        DECISION_HINT=$(echo "$INPUT" | jq -r '.permission_mode // .mode // "unknown"')
        echo "[Hook] Permission request: $TOOL_NAME (mode: $DECISION_HINT)" >&2
      '';
    })
  ];

  PermissionDenied = [
    (mkPassthroughHook {
      body = ''
        TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // .tool // "unknown"')
        echo "[Hook] Permission denied: $TOOL_NAME" >&2
      '';
    })
  ];

  # --- Notification Hooks ---
  Notification = [
    {
      hooks = [
        {
          type = "command";
          command = ''
            msg=$(cat | jq -r '.message // "Needs your attention"')
            notify-send -i dialog-information "Claude Code" "$msg" 2>/dev/null || true
          '';
        }
      ];
    }
  ];

  # --- Stop Hooks ---
  Stop = [
    {
      hooks = [
        {
          type = "command";
          command = ''
            reason=$(cat | jq -r '.stop_reason // "completed"')
            notify-send -i dialog-information "Claude Code" "Task $reason" 2>/dev/null || true
          '';
        }
      ];
    }
    # Git diff summary
    (mkPassthroughHook {
      body = ''
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
          DIFF_STAT=$(git diff --stat 2>/dev/null | tail -1)
          if [ -n "$DIFF_STAT" ]; then
            echo "[Hook] Session changes: $DIFF_STAT" >&2
          fi
          DIFF_CACHED=$(git diff --cached --stat 2>/dev/null | tail -1)
          if [ -n "$DIFF_CACHED" ]; then
            echo "[Hook] Staged changes: $DIFF_CACHED" >&2
          fi
        fi
      '';
    })
  ];

  StopFailure = [
    {
      hooks = [
        {
          type = "command";
          command = ''
            reason=$(cat | jq -r '.stop_reason // .reason // "failed"')
            notify-send -i dialog-error "Claude Code" "Task $reason" 2>/dev/null || true
          '';
        }
      ];
    }
  ];

  # --- PostToolUseFailure Hooks ---
  PostToolUseFailure = [
    (mkPassthroughHook {
      body = ''
        TOOL=$(echo "$INPUT" | jq -r '.tool_name // .tool // "unknown"')
        ERROR=$(echo "$INPUT" | jq -r '.error // "no error"' | head -5)
        echo "[Hook] Tool FAILED: $TOOL — $ERROR" >&2
      '';
    })
  ];

  # --- Session Lifecycle Hooks ---
  SessionStart = [
    # AGENTS.md context loader
    (mkPassthroughHook {
      body = ''
        echo "[Hook] Scanning for AGENTS.md files..." >&2

        AGENTS_CONTENT=""

        # Walk up from CWD to root
        scan_dir="$PWD"
        while [ "$scan_dir" != "/" ]; do
          if [ -f "$scan_dir/AGENTS.md" ]; then
            CONTENT=$(head -100 "$scan_dir/AGENTS.md" 2>/dev/null)
            if [ -n "$CONTENT" ]; then
              AGENTS_CONTENT="$scan_dir/AGENTS.md:
        $CONTENT

        ---
        $AGENTS_CONTENT"
            fi
          fi
          scan_dir=$(dirname "$scan_dir")
        done

        # Check common subdirectories in CWD
        for subdir in src docs .claude .github; do
          if [ -f "$PWD/$subdir/AGENTS.md" ]; then
            CONTENT=$(head -50 "$PWD/$subdir/AGENTS.md" 2>/dev/null)
            if [ -n "$CONTENT" ]; then
              AGENTS_CONTENT="$PWD/$subdir/AGENTS.md:
        $CONTENT

        ---
        $AGENTS_CONTENT"
            fi
          fi
        done

        if [ -n "$AGENTS_CONTENT" ]; then
          echo "[Hook] Active AGENTS.md rules:" >&2
          echo "$AGENTS_CONTENT" | head -200 >&2
        else
          echo "[Hook] No AGENTS.md files found" >&2
        fi
      '';
    })
    # Session state restore
    {
      hooks = [
        {
          type = "command";
          command = ''
            SESSION_DIR="$HOME/.claude/session-state"
            if [ -f "$SESSION_DIR/last-session.json" ]; then
              echo "[Hook] Loaded previous session context" >&2
              cat "$SESSION_DIR/last-session.json" >&2
            fi
            cat
          '';
        }
      ];
    }
  ];

  SessionEnd = [
    (mkPassthroughHook {
      body = ''
        SESSION_DIR="$HOME/.claude/session-state"
        mkdir -p "$SESSION_DIR"
        GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        echo "$INPUT" | jq --arg cwd "$PWD" --arg branch "$GIT_BRANCH" '{
          timestamp: now,
          reason: (.reason // .stop_reason // "other"),
          cwd: $cwd,
          git_branch: $branch
        }' > "$SESSION_DIR/last-session.json" 2>/dev/null || true
      '';
    })
  ];

  SubagentStop = [
    (mkPassthroughHook {
      body = ''
        AGENT_NAME=$(echo "$INPUT" | jq -r '.agent_name // .agent // "unknown"')
        STATUS=$(echo "$INPUT" | jq -r '.status // .stop_reason // "completed"')
        echo "[Hook] Subagent finished: $AGENT_NAME ($STATUS)" >&2
      '';
    })
  ];

  # --- PreCompact Hook ---
  PreCompact = [
    (mkPassthroughHook {
      body = ''
        SESSION_DIR="$HOME/.claude/session-state"
        mkdir -p "$SESSION_DIR"
        echo "[Hook] Saving state before compaction..." >&2
        date -Iseconds > "$SESSION_DIR/last-compact.txt"

        # Save git state
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
          git diff --stat > "$SESSION_DIR/pre-compact-diff.txt" 2>/dev/null || true
          git status --short > "$SESSION_DIR/pre-compact-status.txt" 2>/dev/null || true
        fi
      '';
    })
  ];

  PostCompact = [
    (mkPassthroughHook {
      body = ''
        SESSION_DIR="$HOME/.claude/session-state"
        mkdir -p "$SESSION_DIR"
        date -Iseconds > "$SESSION_DIR/last-post-compact.txt"
        echo "[Hook] Context compaction completed" >&2
      '';
    })
  ];
}
