# Single source of truth for model identifiers used across AI agent configs.
# When upgrading a model, change it here — all consumers pick it up automatically.

{
  # Anthropic Claude models (OpenCode-style with provider prefix)
  claude-opus = "opencode/claude-opus-4-6";
  claude-sonnet = "opencode/claude-sonnet-4-6";
  claude-haiku = "opencode/claude-haiku-4-5";

  # Anthropic Claude models (raw IDs for pi and other agents)
  claude-opus-raw = "claude-opus-4-6";
  claude-sonnet-raw = "claude-sonnet-4-6";
  claude-haiku-raw = "claude-haiku-4-5";
  claude-sonnet-default = "claude-sonnet-4-20250514";

  # OpenAI models
  gpt-default = "openai/gpt-5.5";
  gpt-low = "openai/gpt-5.5-spark";
  gpt-xhigh = "openai/gpt-5.1-codex-max";

  # OpenAI models (raw IDs)
  gpt-default-raw = "openai-codex/gpt-5.5";
  gpt-low-raw = "gpt-5.5-spark";

  # Provider-specific aliases
  openrouter = "openrouter/openrouter/hunter-alpha";
  openrouter-raw = "openrouter/hunter-alpha";

  # ZAI / other
  glm = "zai-coding-plan/glm-5.1";
  glm-raw = "zai/glm-5.1";
  gemini = "google/gemini-3-pro-preview";
  gemini-raw = "google/gemini-3-pro-preview";
  zen = "opencode/minimax-m2.5-free";
  zen-raw = "opencode-zen/minimax-m2.5-free";

  # Aider (uses Anthropic model IDs without provider prefix)
  aider-model = "claude-sonnet-4-6";
  aider-editor = "claude-haiku-4-5";
}
