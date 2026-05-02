# Single source of truth for model identifiers used across AI agent configs.
# When upgrading a model, change it here — all consumers pick it up automatically.
{
  # Anthropic Claude models (OpenCode-style with provider prefix)
  claude-opus = "opencode/claude-opus-4-7";
  claude-sonnet = "opencode/claude-sonnet-4-7";
  claude-haiku = "opencode/claude-haiku-4-5";

  # Anthropic Claude models (raw IDs for pi and other agents)
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
  openrouter = "openrouter/tencent/hun3-review:free";
  openrouter-raw = "openrouter/tencent/hun3-review:free";

  # ZAI / other
  glm = "zai-coding-plan/glm-5.1";
  "glm-5" = "zai-coding-plan/glm-5";
  glm-raw = "zai/glm-5.1";
  gemini = "google/gemini-3-pro-preview";
  gemini-raw = "google/gemini-3-pro-preview";
  zen = "opencode/minimax-m2.5-free";
  zen-pi = "minimax-m2.5-free";
  zen-raw = "opencode-zen/minimax-m2.5-free";
  gemini-pro = "gemini-3-pro-preview";
  gemini-flash = "gemini-2.5-flash";
  gemini-flash-lite = "gemini-2.5-flash-lite";
  "kimi-k2.5" = "moonshotai/kimi-k2.5";
  "kimi-k2.5-raw" = "kimi-for-coding/k2p5";
  "minimax-m2.7" = "opencode/minimax-m2.7";
  "minimax-m2.7-highspeed" = "opencode/minimax-m2.7-highspeed";
  grok-code-fast-1 = "xai/grok-code-fast-1";

  # Aider (uses Anthropic model IDs without provider prefix)
  aider-model = "claude-sonnet-4-7";
  aider-editor = "claude-haiku-4-5";

  # oh-my-pi (provider-prefixed IDs match models.yml provider definitions)
  omp-default = "zai/glm-5.1";
  omp-plan = "zai/glm-5.1";
  omp-smol = "zai/glm-5-turbo";
}
