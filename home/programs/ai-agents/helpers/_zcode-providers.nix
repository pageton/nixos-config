# ZCode (~/.zcode/v2/config.json) managed provider registry.
#
# ZCode supports exactly two provider kinds:
#   anthropic        -> baseURL + "/v1/messages"
#   openai-compatible -> baseURL + "/chat/completions"
# OpenCode Zen free models only answer on chat/completions (the Anthropic-style
# /zen/v1/messages returns 400 for them), so the Zen entry MUST stay
# openai-compatible. Live free-model list: GET https://opencode.ai/zen/v1/models
# (rotates: deepseek-v4-flash-free absent 2026-08, present again 2026-09).
# OpenRouter free tiers: GET https://openrouter.ai/api/v1/models (pricing 0/0).
# NOTE: paid DeepSeek goes through the dedicated api.deepseek.com provider below.
{
  opencodeZen = {
    name = "OpenCode Zen";
    kind = "openai-compatible";
    baseURL = "https://opencode.ai/zen/v1";
    models = {
      "big-pickle" = {
        context = 200000;
        output = 32000;
        input = [ "text" ];
        reasoning = true;
      };
      "laguna-s-2.1-free" = {
        context = 256000;
        output = 32000;
        input = [ "text" ];
        reasoning = true;
      };
      "mimo-v2.5-free" = {
        context = 200000;
        output = 32000;
        input = [ "text" ];
        reasoning = true;
      };
      "hy3-free" = {
        context = 190000;
        output = 64000;
        input = [ "text" ];
        reasoning = true;
      };
      "nemotron-3-ultra-free" = {
        context = 1000000;
        output = 128000;
        input = [ "text" ];
        reasoning = true;
      };
      "nemotron-3.5-lightning-free" = {
        context = 262144;
        output = 262144;
        input = [ "text" ];
        reasoning = true;
      };
    };
  };

  openrouter = {
    name = "OpenRouter";
    kind = "anthropic";
    baseURL = "https://openrouter.ai/api";
    # Merged (not replaced) into any existing OpenRouter provider entry, so
    # UI-added models survive activation.
    models = {
      "cohere/north-mini-code:free" = {
        context = 256000;
        output = 64000;
        input = [ "text" ];
        reasoning = true;
      };
      "dots-studio/dots-3-note-preview:free" = {
        context = 512000;
        output = 512000;
        input = [
          "text"
          "image"
        ];
        reasoning = true;
      };
      "google/gemma-4-26b-a4b-it:free" = {
        context = 262144;
        output = 32768;
        input = [
          "image"
          "text"
          "video"
        ];
        reasoning = true;
      };
      "google/gemma-4-31b-it:free" = {
        context = 262144;
        output = 32768;
        input = [
          "image"
          "text"
          "video"
        ];
        reasoning = true;
      };
      "liquid/lfm-2.5-2.6b:free" = {
        context = 128000;
        output = 8192;
        input = [ "text" ];
        reasoning = true;
      };
      "nvidia/nemotron-3-nano-30b-a3b:free" = {
        context = 256000;
        output = 256000;
        input = [ "text" ];
        reasoning = true;
      };
      "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free" = {
        context = 256000;
        output = 65536;
        input = [
          "text"
          "audio"
          "image"
          "video"
        ];
        reasoning = true;
      };
      "nvidia/nemotron-3-super-120b-a12b:free" = {
        context = 262144;
        output = 262144;
        input = [ "text" ];
        reasoning = true;
      };
      "nvidia/nemotron-3-ultra-550b-a55b:free" = {
        context = 1000000;
        output = 65536;
        input = [ "text" ];
        reasoning = true;
      };
      "nvidia/nemotron-3.5-lightning:free" = {
        context = 1000000;
        output = 65536;
        input = [ "text" ];
        reasoning = true;
      };
      "nvidia/nemotron-nano-12b-v2-vl:free" = {
        context = 128000;
        output = 128000;
        input = [
          "image"
          "text"
          "video"
        ];
        reasoning = true;
      };
      "nvidia/nemotron-nano-9b-v2:free" = {
        context = 128000;
        output = 128000;
        input = [ "text" ];
        reasoning = true;
      };
      "openai/gpt-oss-20b:free" = {
        context = 131072;
        output = 32768;
        input = [ "text" ];
        reasoning = true;
      };
      "openrouter/free" = {
        context = 200000;
        output = 200000;
        input = [
          "text"
          "image"
        ];
        reasoning = true;
      };
      "poolside/laguna-s-2.1:free" = {
        context = 262144;
        output = 32768;
        input = [ "text" ];
        reasoning = true;
      };
      "poolside/laguna-xs-2.1:free" = {
        context = 262144;
        output = 32768;
        input = [ "text" ];
        reasoning = true;
      };
      "z-ai/glm-5.2:free" = {
        context = 256000;
        output = 256000;
        input = [ "text" ];
        reasoning = true;
      };
    };
  };

  deepseek = {
    name = "deepseek";
    kind = "anthropic";
    baseURL = "https://api.deepseek.com/anthropic";
    # Merged into any existing DeepSeek provider entry. V4 family only —
    # legacy aliases (deepseek-chat, deepseek-reasoner) are intentionally
    # not registered.
    models = {
      deepseek-v4-flash = {
        context = 1000000;
        output = 384000;
        input = [ "text" ];
        reasoning = true;
        reasoningDefault = "max";
      };
      deepseek-v4-flash-0731 = {
        context = 1000000;
        output = 384000;
        input = [ "text" ];
        reasoning = true;
        reasoningDefault = "max";
      };
      deepseek-v4-flash-0731-fast = {
        context = 1000000;
        output = 384000;
        input = [ "text" ];
        reasoning = true;
        reasoningDefault = "max";
      };
      deepseek-v4-flash-latest = {
        context = 1000000;
        output = 384000;
        input = [ "text" ];
        reasoning = true;
        reasoningDefault = "max";
      };
      deepseek-v4-flash-vision-exp = {
        context = 1000000;
        output = 384000;
        input = [
          "text"
          "image"
        ];
        reasoning = true;
        reasoningDefault = "max";
      };
      deepseek-v4-pro = {
        context = 1000000;
        output = 384000;
        input = [ "text" ];
        reasoning = true;
        reasoningDefault = "max";
      };
      deepseek-v4-pro-0423 = {
        context = 1000000;
        output = 384000;
        input = [ "text" ];
        reasoning = true;
        reasoningDefault = "max";
      };
      deepseek-v4-pro-0813 = {
        context = 1000000;
        output = 384000;
        input = [ "text" ];
        reasoning = true;
        reasoningDefault = "max";
      };
    };
  };
}
