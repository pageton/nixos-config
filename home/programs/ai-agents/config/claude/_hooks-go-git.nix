# Go, Git, and GitHub hooks — ported from ZCode to Claude Code.
#
# SessionStart:     Go project context (gofumpt, go test, golangci-lint)
# UserPromptSubmit: Go workspace + Git/GitHub intent context
# PreToolUse:       Go preflight before git/gh mutations + block destructive GitHub
# PostToolUse:      go mod tidy diff on go.mod/go.sum, actionlint on workflow edits

{ }:

let
  findGoRoot = ''
    GO_ROOT=""
    if command -v git >/dev/null 2>&1; then
      REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
      if [ -n "$REPO_ROOT" ] && { [ -f "$REPO_ROOT/go.mod" ] || [ -f "$REPO_ROOT/go.work" ]; }; then
        GO_ROOT="$REPO_ROOT"
      fi
    fi
    if [ -z "$GO_ROOT" ] && command -v go >/dev/null 2>&1; then
      GOMOD=$(go env GOMOD 2>/dev/null || true)
      if [ -n "$GOMOD" ] && [ "$GOMOD" != "/dev/null" ]; then
        GO_ROOT=$(dirname "$GOMOD")
      else
        GOWORK=$(go env GOWORK 2>/dev/null || true)
        if [ -n "$GOWORK" ] && [ "$GOWORK" != "off" ]; then
          GO_ROOT=$(dirname "$GOWORK")
        fi
      fi
    fi
  '';
in
{
  SessionStart = [
    {
      matcher = "startup|clear|compact";
      hooks = [
        {
          type = "command";
          command = ''
            INPUT=$(cat)
            ${findGoRoot}
            if [ -n "$GO_ROOT" ]; then
              echo "$INPUT" | jq -c --arg context "Go project at $GO_ROOT. Format Go with gofumpt. Run go test ./... before commits. Run golangci-lint before pushes." '. + {hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $context}}'
            else
              echo "$INPUT"
            fi
          '';
        }
      ];
    }
  ];

  UserPromptSubmit = [
    {
      hooks = [
        {
          type = "command";
          command = ''
            INPUT=$(cat)
            PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')
            CONTEXT=""
            ${findGoRoot}
            if [ -n "$GO_ROOT" ]; then
              CONTEXT="Active Go workspace: $GO_ROOT. Use gofumpt, run focused package tests while iterating, run go test ./... before completion."
            fi
            if echo "$PROMPT" | grep -Eiq '(^|[^[:alnum:]_])(git|github|commit|push|pull[ -]?request|merge|release|branch|tag)([^[:alnum:]_]|$)' && command -v git >/dev/null 2>&1; then
              GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
              if [ -n "$GIT_ROOT" ]; then
                BRANCH=$(git -C "$GIT_ROOT" branch --show-current 2>/dev/null || true)
                [ -z "$BRANCH" ] && BRANCH="detached HEAD"
                CHANGED_COUNT=$(git -C "$GIT_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d '[:space:]')
                CONTEXT="$CONTEXT Git/GitHub request on $BRANCH with $CHANGED_COUNT changed paths. Inspect git status and git diff before mutations."
              fi
            fi
            if [ -n "$CONTEXT" ]; then
              echo "$INPUT" | jq -c --arg context "$CONTEXT" '. + {hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $context}}'
            else
              echo "$INPUT"
            fi
          '';
        }
      ];
    }
  ];

  PreToolUse = [
    {
      matcher = "Bash";
      hooks = [
        {
          type = "command";
          timeout = 300000;
          command = ''
            INPUT=$(cat)
            COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
            if ! echo "$COMMAND" | grep -Eq '(^|[[:space:]])(git[[:space:]]+(commit|push)|gh[[:space:]]+pr[[:space:]]+create)([[:space:]]|$)'; then
              echo "$INPUT"; exit 0
            fi
            ${findGoRoot}
            [ -z "$GO_ROOT" ] && { echo "$INPUT"; exit 0; }
            echo "[Hook] Go preflight: go test ./..." >&2
            if ! TEST_OUTPUT=$(cd "$GO_ROOT" && go test ./... 2>&1); then
              echo "[Hook] BLOCKED: Go tests failed" >&2
              printf '%s\n' "$TEST_OUTPUT" | tail -30 >&2
              exit 2
            fi
            if echo "$COMMAND" | grep -Eq '(^|[[:space:]])(git[[:space:]]+push|gh[[:space:]]+pr[[:space:]]+create)([[:space:]]|$)' && command -v golangci-lint >/dev/null 2>&1; then
              echo "[Hook] Go preflight: golangci-lint run" >&2
              if ! LINT_OUTPUT=$(cd "$GO_ROOT" && golangci-lint run 2>&1); then
                echo "[Hook] BLOCKED: golangci-lint failed" >&2
                printf '%s\n' "$LINT_OUTPUT" | tail -30 >&2
                exit 2
              fi
            fi
            echo "$INPUT"
          '';
        }
      ];
    }
    {
      matcher = "Bash";
      hooks = [
        {
          type = "command";
          timeout = 10000;
          command = ''
            INPUT=$(cat)
            COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
            if echo "$COMMAND" | grep -Eq '(^|[[:space:]])gh[[:space:]]+(repo|release)[[:space:]]+delete([[:space:]]|$)|(^|[[:space:]])gh[[:space:]]+api.*(-X|--method)(=|[[:space:]]+)DELETE'; then
              echo "[Hook] BLOCKED: destructive GitHub command detected" >&2
              echo "[Hook] Run it manually outside Claude after reviewing the target and scope." >&2
              exit 2
            fi
            echo "$INPUT"
          '';
        }
      ];
    }
  ];

  PostToolUse = [
    {
      matcher = "Edit|Write";
      hooks = [
        {
          type = "command";
          run_in_background = true;
          timeout = 120000;
          command = ''
            INPUT=$(cat)
            FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
            case "$FILE_PATH" in
              go.mod|go.sum|*/go.mod|*/go.sum) ;;
              *) echo "$INPUT"; exit 0 ;;
            esac
            MODULE_ROOT=$(dirname "$FILE_PATH")
            if [ -f "$MODULE_ROOT/go.mod" ] && command -v go >/dev/null 2>&1; then
              if ! TIDY_OUTPUT=$(cd "$MODULE_ROOT" && go mod tidy -diff 2>&1); then
                echo "[Hook] Go module files are not tidy:" >&2
                printf '%s\n' "$TIDY_OUTPUT" | tail -30 >&2
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
          timeout = 30000;
          command = ''
            INPUT=$(cat)
            FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
            case "$FILE_PATH" in
              .github/workflows/*.yml|.github/workflows/*.yaml|*/.github/workflows/*.yml|*/.github/workflows/*.yaml) ;;
              *) echo "$INPUT"; exit 0 ;;
            esac
            if [ -f "$FILE_PATH" ] && command -v actionlint >/dev/null 2>&1; then
              if ! ACTIONLINT_OUTPUT=$(actionlint "$FILE_PATH" 2>&1); then
                echo "[Hook] GitHub Actions workflow errors:" >&2
                printf '%s\n' "$ACTIONLINT_OUTPUT" | tail -30 >&2
              fi
            fi
            echo "$INPUT"
          '';
        }
      ];
    }
  ];
}
