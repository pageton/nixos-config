# Shared error detection pattern for AI agent log analysis.
# Source this file to get consistent error matching across all consumers.
# Usage: source "${SCRIPT_DIR}/../lib/error-patterns.sh"

# Broad pattern: keyword matches + log-level prefixes (used by Codex, Claude debug, OpenCode).
# shellcheck disable=SC2034
ERROR_PATTERN='\b(error|panic|fatal|exception|failed|invalid|deprecated|certificate|ssl|tls)\b| WARN | ERROR '
