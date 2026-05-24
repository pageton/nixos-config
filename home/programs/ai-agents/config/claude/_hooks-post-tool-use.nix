# PostToolUse hooks — auto-formatting, PR detection, console.log warnings, TypeScript checking,
# TODO/FIXME tracker, smart test runner, dependency change guard.

{
  mkFormatterHook,
  formatterRegistry,
  mkCommandHook,
}:

{
  PostToolUse = formatterRegistry.mkClaudeFormatterHooks mkFormatterHook ++ [
    {
      matcher = "Bash";
      hooks = [
        {
          type = "command";
          command = ''
            INPUT=$(cat)
            COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
            if echo "$COMMAND" | grep -Eq 'gh pr create'; then
              PR_URL=$(echo "$INPUT" | jq -r '(.tool_response.output // .tool_response.stdout // .tool_output.output // "")' | grep -oE 'https://github.com/[^/]+/[^/]+/pull/[0-9]+' || true)
              if [ -n "$PR_URL" ]; then
                echo "[Hook] PR created: $PR_URL" >&2
              fi
            fi
            echo "$INPUT"
          '';
        }
      ];
    }
    {
      matcher = "Edit|Write";
      hooks = [
        {
          type = "command";
          run_in_background = true;
          timeout = 20000;
          command = ''
            INPUT=$(cat)
            FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
            if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
              MATCHES=$(grep -n "console\.log" "$FILE_PATH" 2>/dev/null | head -5)
              if [ -n "$MATCHES" ]; then
                echo "[Hook] WARNING: console.log found in $FILE_PATH" >&2
                echo "$MATCHES" >&2
              fi
            fi
            echo "$INPUT"
          '';
        }
      ];
    }
    {
      matcher = "Edit|Write";
      hooks = [
        {
          type = "command";
          command = ''
            INPUT=$(cat)
            FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
            if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
              case "$FILE_PATH" in
                *.ts|*.tsx|*.mts|*.cts) ;;
                *) echo "$INPUT"; exit 0 ;;
              esac
              DIR=$(dirname "$FILE_PATH")
              while [ "$DIR" != "/" ] && [ ! -f "$DIR/tsconfig.json" ]; do
                DIR=$(dirname "$DIR")
              done
              if [ -f "$DIR/tsconfig.json" ]; then
                TSC_OUT=$(cd "$DIR" && npx tsc --noEmit --pretty false 2>&1 | grep "$FILE_PATH" | head -10) || true
                if [ -n "$TSC_OUT" ]; then
                  echo "[Hook] TypeScript errors:" >&2
                  echo "$TSC_OUT" >&2
                fi
              fi
            fi
            echo "$INPUT"
          '';
        }
      ];
    }

    # --- TODO/FIXME tracker ---
    {
      matcher = "Edit|Write";
      hooks = [
        {
          type = "command";
          run_in_background = true;
          timeout = 10000;
          command = ''
            INPUT=$(cat)
            FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

            if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
              TODOS=$(grep -n 'TODO\|FIXME\|HACK\|XXX' "$FILE_PATH" 2>/dev/null | head -10)
              if [ -n "$TODOS" ]; then
                SESSION_DIR="$HOME/.claude/session-state"
                mkdir -p "$SESSION_DIR"
                TODO_FILE="$SESSION_DIR/todo-tracker.txt"
                echo "[$(date -Iseconds)] $FILE_PATH" >> "$TODO_FILE"
                echo "$TODOS" >> "$TODO_FILE"
                echo "---" >> "$TODO_FILE"
                echo "[Hook] TODO/FIXME tracked in $FILE_PATH" >&2
              fi
            fi
            echo "$INPUT"
          '';
        }
      ];
    }

    # --- Dependency change guard ---
    {
      matcher = "Edit|Write";
      hooks = [
        {
          type = "command";
          timeout = 15000;
          command = ''
            INPUT=$(cat)
            FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

            case "$FILE_PATH" in
              */package.json|*/Cargo.toml|*/go.mod|*/flake.nix|*/flake.lock|*/mix.exs|*/pyproject.toml|*/requirements.txt)
                echo "[Hook] WARNING: dependency file modified — $FILE_PATH" >&2
                echo "[Hook] Run full test suite and check for breaking changes." >&2
                ;;
            esac

            echo "$INPUT"
          '';
        }
      ];
    }

    # --- Smart test runner (background, project-aware) ---
    {
      matcher = "Edit|Write";
      hooks = [
        {
          type = "command";
          run_in_background = true;
          timeout = 60000;
          command = ''
            INPUT=$(cat)
            FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

            if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
              echo "$INPUT"; exit 0
            fi

            # Skip non-source files
            case "$FILE_PATH" in
              *.go|*.rs|*.ts|*.tsx|*.test.*|*.spec.*|*.nix) ;;
              *) echo "$INPUT"; exit 0 ;;
            esac

            DIR="$(dirname "$FILE_PATH")"
            while [ "$DIR" != "/" ]; do
              if [ -f "$DIR/go.mod" ]; then
                echo "[Hook] Running Go tests..." >&2
                (cd "$DIR" && go test ./... 2>&1 | tail -10 >&2) || true
                break
              elif [ -f "$DIR/Cargo.toml" ]; then
                echo "[Hook] Running Rust tests..." >&2
                (cd "$DIR" && cargo test 2>&1 | tail -10 >&2) || true
                break
              elif [ -f "$DIR/package.json" ] && grep -q '"test"' "$DIR/package.json" 2>/dev/null; then
                if [ -f "$DIR/pnpm-lock.yaml" ]; then
                  echo "[Hook] Running pnpm tests..." >&2
                  (cd "$DIR" && pnpm test 2>&1 | tail -10 >&2) || true
                elif [ -f "$DIR/yarn.lock" ]; then
                  echo "[Hook] Running yarn tests..." >&2
                  (cd "$DIR" && yarn test 2>&1 | tail -10 >&2) || true
                else
                  echo "[Hook] Running npm tests..." >&2
                  (cd "$DIR" && npm test 2>&1 | tail -10 >&2) || true
                fi
                break
              elif [ -f "$DIR/flake.nix" ]; then
                echo "[Hook] Running nix flake check..." >&2
                (cd "$DIR" && nix flake check 2>&1 | tail -10 >&2) || true
                break
              fi
              DIR=$(dirname "$DIR")
            done

            echo "$INPUT"
          '';
        }
      ];
    }
  ];
}
