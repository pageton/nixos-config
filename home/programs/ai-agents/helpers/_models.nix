# Single source of truth for model identifiers used across AI agent configs.
# When upgrading a model, change it here — all consumers pick it up automatically.
{
  # Anthropic Claude models (OpenCode-style with provider prefix)
  claude-opus = "opencode/claude-opus-4-7";
  claude-sonnet = "opencode/claude-sonnet-4-7";
  claude-haiku = "opencode/claude-haiku-4-5";

  # Anthropic Claude models (raw IDs for agents that need them)
  claude-opus-raw = "claude-opus-4-7";
  claude-sonnet-raw = "claude-sonnet-4-7";
  claude-haiku-raw = "claude-haiku-4-5";
  claude-sonnet-default = "claude-sonnet-4-20250514";

  # OpenAI models
  gpt-default = "openai/gpt-5.5";
  "gpt-5.4" = "openai/gpt-5.4";
  gpt-low = "openai/gpt-5.5-spark";
  gpt-xhigh = "openai/gpt-5.1-codex-max";

  # OpenAI models (raw IDs)
  gpt-default-raw = "openai-codex/gpt-5.5";
  gpt-low-raw = "gpt-5.5-spark";

  # Provider-specific aliases
  openrouter = "openrouter/tencent/hy3-preview:free";
  openrouter-raw = "openrouter/tencent/hy3-preview:free";

  # ZAI / other
  glm = "zai-coding-plan/glm-5.2";
  "glm-5" = "zai-coding-plan/glm-5";
  glm-raw = "zai/glm-5.2";
  gemini = "google/gemini-3-pro-preview";
  gemini-raw = "google/gemini-3-pro-preview";
  zen = "opencode/minimax-m2.5-free";
  zen-raw = "opencode-zen/minimax-m2.5-free";
  gemini-pro = "gemini-3-pro-preview";
  gemini-flash = "gemini-2.5-flash";
  gemini-flash-lite = "gemini-2.5-flash-lite";
  "kimi-k2.5" = "moonshotai/kimi-k2.5";
  "kimi-k2.5-raw" = "kimi-for-coding/k2p5";
  "minimax-m2.7" = "opencode/minimax-m2.7";
  "minimax-m2.7-highspeed" = "opencode/minimax-m2.7-highspeed";
  grok-code-fast-1 = "xai/grok-code-fast-1";

  # DeepSeek models
  deepseek-pro-raw = "deepseek/deepseek-v4-pro";
  deepseek-flash-raw = "deepseek/deepseek-v4-flash";
  deepseek-pro = "deepseek/deepseek-v4-pro";
  deepseek-flash = "deepseek/deepseek-v4-flash";

  # Xiaomi MiMo models (OpenCode uses xiaomi-token-plan-sgp provider from models.dev)
  mimo-pro = "xiaomi-token-plan-sgp/mimo-v2.5-pro";
  mimo-default = "xiaomi-token-plan-sgp/mimo-v2.5-pro";
  mimo-lite = "xiaomi-token-plan-sgp/mimo-v2.5";
  mimo-flash = "xiaomi-token-plan-sgp/mimo-v2-flash";
  # Claude Code uses bare model names with the Anthropic-compatible endpoint
  mimo-cc-pro = "mimo-v2.5-pro";
  mimo-cc-lite = "mimo-v2.5";

  # Aider (uses Anthropic model IDs without provider prefix)
  aider-model = "claude-sonnet-4-7";
  aider-editor = "claude-haiku-4-5";
}
