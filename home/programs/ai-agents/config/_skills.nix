# Skill installations for all AI agents.
# Imported by config/defaults.nix.
{
  skills = [
    # ── Real tools ────────────────────────────────────────────────────────
    {
      repo = "vercel-labs/agent-browser";
      skill = "agent-browser";
    }
    {
      repo = "callstackincubator/agent-device";
      skill = "agent-device";
    }
    {
      repo = "microsoft/playwright-cli";
      skill = "playwright-cli";
    }
    {
      repo = "ChromeDevTools/chrome-devtools-mcp";
      skill = "chrome-devtools-cli";
    }

    # ── Anthropic official ────────────────────────────────────────────────
    {
      repo = "anthropics/skills";
      skill = "webapp-testing";
    }
    {
      repo = "anthropics/skills";
      skill = "frontend-design";
    }
    {
      repo = "anthropics/skills";
      skill = "mcp-builder";
    }
    {
      repo = "anthropics/skills";
      skill = "skill-creator";
    }
    {
      repo = "anthropics/skills";
      skill = "web-artifacts-builder";
    }

    # ── Matt Pocock methodology — all installable skills ────────────────────
    "mattpocock/skills"

    # ── Vercel skills ─────────────────────────────────────────────────────
    "vercel-labs/agent-skills"
    {
      repo = "vercel-labs/skills";
      skill = "find-skills";
    }

    # ── Supercent UI/UX design skills ─────────────────────────────────────
    {
      repo = "supercent-io/skills-template";
      skill = "adapt";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "animate";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "arrange";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "audit";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "bolder";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "clarify";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "colorize";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "critique";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "delight";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "distill";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "extract";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "harden";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "normalize";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "onboard";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "optimize";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "overdrive";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "polish";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "quieter";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "responsive-design";
    }
    {
      repo = "supercent-io/skills-template";
      skill = "typeset";
    }

    # ── Samber Golang skills ──────────────────────────────────────────────
    "samber/cc-skills-golang"

    # ── TON blockchain ────────────────────────────────────────────────────
    {
      repo = "ton-org/skills";
      skill = "ton-balance";
    }
    {
      repo = "ton-org/skills";
      skill = "ton-cli";
    }
    {
      repo = "ton-org/skills";
      skill = "ton-create-wallet";
    }
    {
      repo = "ton-org/skills";
      skill = "ton-docs";
    }
    {
      repo = "ton-org/skills";
      skill = "ton-manage-wallets";
    }
    {
      repo = "ton-org/skills";
      skill = "ton-nfts";
    }
    # Broken: ton-proof skill does not exist in ton-connect/kit.
    # Available skills: add-action-and-hook, add-ui-component.
    # {
    #   repo = "ton-connect/kit";
    #   skill = "ton-proof";
    # }
    {
      repo = "ton-org/skills";
      skill = "ton-send";
    }
    {
      repo = "ton-org/skills";
      skill = "ton-swap";
    }
    {
      repo = "ton-org/skills";
      skill = "ton-xstocks";
    }

    # ── Obra superpowers (methodology & workflow) ─────────────────────────
    "obra/superpowers"

    # ── Impeccable design system ──────────────────────────────────────────
    "pbakaus/impeccable"

    # ── Everything Claude Code ────────────────────────────────────────────
    {
      repo = "affaan-m/everything-claude-code";
      skill = "everything-claude-code";
    }
    {
      repo = "affaan-m/everything-claude-code";
      skill = "bun-runtime";
    }
    {
      repo = "affaan-m/everything-claude-code";
      skill = "security-review";
    }

    # ── Coding methodology — multi-agent ──────────────────────────────────
    {
      repo = "michaelboeding/skills";
      skill = "debug-council";
    }
    {
      repo = "michaelboeding/skills";
      skill = "parallel-builder";
    }

    # ── Architecture & code structure ─────────────────────────────────────
    {
      repo = "michaelshimeles/skills";
      skill = "code-structure";
    }

    # ── Practical dev tools ───────────────────────────────────────────────
    {
      repo = "mxyhi/ok-skills";
      skill = "gh-fix-ci";
    }
    {
      repo = "mxyhi/ok-skills";
      skill = "find-docs";
    }

    # ── Security ──────────────────────────────────────────────────────────
    {
      repo = "TerminalSkills/skills";
      skill = "security-audit";
    }

    # ── Reverse engineering ───────────────────────────────────────────────
    {
      repo = "wshobson/agents";
      skill = "protocol-reverse-engineering";
    }

    # ── Documentation discipline ──────────────────────────────────────────
    {
      repo = "github/awesome-copilot";
      skill = "documentation-writer";
    }
    {
      repo = "github/awesome-copilot";
      skill = "create-readme";
    }
    {
      repo = "softaworks/agent-toolkit";
      skill = "crafting-effective-readmes";
    }
    "addyosmani/agent-skills"
    {
      repo = "narlyseorg/superhackers";
      skill = "assessment-orchestrator";
    }
    {
      repo = "narlyseorg/superhackers";
      skill = "security-assessment";
    }

    # ── Reverse engineering & security research ───────────────────────────
    # Broken upstream: SKILL.md missing required "name" field in frontmatter.
    # {
    #   repo = "SimoneAvogadro/android-reverse-engineering-skill";
    #   skill = "android-reverse-engineering";
    # }
    # Broken: no valid SKILL.md found in Eyali1001/apkre.
    # {
    #   repo = "Eyali1001/apkre";
    #   skill = "apk-audit";
    # }
    {
      repo = "P4nda0s/reverse-skills";
      skill = "rev-frida";
    }

    # ── Web scraping ────────────────────────────────────────────────────────
    {
      repo = "apify/agent-skills";
      skill = "apify-ultimate-scraper";
    }

    # ── Cloud & infra ─────────────────────────────────────────────────────
    {
      repo = "cloudflare/skills";
      skill = "cloudflare";
    }
    {
      repo = "Jeffallan/claude-skills";
      skill = "postgres-pro";
    }
    {
      repo = "squirrelscan/skills";
      skill = "audit-website";
    }

    # ── Framework-specific ────────────────────────────────────────────────
    {
      repo = "yusukebe/hono-skill";
      skill = "hono";
    }
    {
      repo = "shadcn-ui/ui";
      skill = "shadcn";
    }
    {
      repo = "google-labs-code/stitch-skills";
      skill = "design-md";
    }
    {
      repo = "nextlevelbuilder/ui-ux-pro-max-skill";
      skill = "ui-ux-pro-max";
    }

    # ── Telegram ──────────────────────────────────────────────────────────
    {
      repo = "PBnicad/telegram-bot-grammy-skill";
      skill = "telegram-bot-grammy";
    }
    {
      repo = "sickn33/antigravity-awesome-skills";
      skill = "telegram-mini-app";
    }

    # ── Agent multiplexer ─────────────────────────────────────────────────
    {
      repo = "ogulcancelik/herdr";
      skill = "herdr";
    }

    # ── Various utilities ─────────────────────────────────────────────────
    {
      repo = "Yeachan-Heo/oh-my-claudecode";
      skill = "autoresearch";
    }
    {
      repo = "Yeachan-Heo/oh-my-claudecode";
      skill = "ultrawork";
    }
    {
      repo = "Yeachan-Heo/oh-my-claudecode";
      skill = "deepinit";
    }
    {
      repo = "xixu-me/skills";
      skill = "develop-userscripts";
    }
    {
      repo = "xixu-me/skills";
      skill = "github-actions-docs";
    }
    {
      repo = "xixu-me/skills";
      skill = "openclaw-secure-linux-cloud";
    }
    {
      repo = "xixu-me/skills";
      skill = "opensource-guide-coach";
    }
    {
      repo = "xixu-me/skills";
      skill = "readme-i18n";
    }
    {
      repo = "xixu-me/skills";
      skill = "running-claude-code-via-litellm-copilot";
    }
    {
      repo = "xixu-me/skills";
      skill = "secure-linux-web-hosting";
    }
    {
      repo = "xixu-me/skills";
      skill = "skills-cli";
    }
    {
      repo = "xixu-me/skills";
      skill = "use-my-browser";
    }

    # ── Telegram — mtgo library + CLI ─────────────────────────────────────
    {
      repo = "mtgo-labs/mtgo";
      skill = "mtgo";
    }
    {
      repo = "mtgo-labs/mtgo-cli";
      skill = "mtgo-cli";
    }

    # ── Telegram development (gotg-cli) ───────────────────────────────────
    {
      repo = "pageton/gotg-cli";
      skill = "tg-dev-agent";
    }

    # ── Speckit spec-driven development ────────────────────────────────────
    "dceoy/speckit-agent-skills"
  ];
}
