# ZCode (Z.AI desktop app) managed settings.
#
# Values are deep-merged into ~/.zcode/v2/setting.json at activation
# (activation/zcode-setup.nix): managed keys win, everything else the app
# writes survives. Only stable behavior toggles are claimed here — volatile
# UI state (recentProjects, lastWorkspaceSession, desktopWindowSize,
# webRemoteControl* device pairing, locale, provider-family auth state,
# one-time *MigrationInitialized flags) stays app-owned.
# Providers/models are managed separately via programs.aiAgents.zcode.providers
# (defaults in helpers/_zcode-providers.nix).
#
# Restart ZCode after switching to pick up changes — the app holds settings
# in memory.

_: {
  programs.aiAgents.zcode.extraSettings = {
    # Nix manages the AppImage (zcode-update.timer); never let the app
    # self-update.
    autoDownloadAndInstallUpdates = false;

    # Interaction mode: queue tasks instead of the guided flow.
    zcodeInteractionBehavior = "queue";
    askUserQuestionAutoResolutionEnabled = true;
    keepAwakeWhileRunning = false;
    terminalInheritSystemProfile = true;

    # Memory + indexing (repo snapshots, instant grep, native search).
    memoryEnabled = true;
    repoSnapshotIndexingEnabled = true;
    repoSnapshotIndexingUserConfigured = true;
    instantGrepIndexingEnabled = true;
    nativeSearchEnhancementsEnabled = true;

    # Message stream rendering + tool grouping.
    messageStreamShowReasoning = true;
    messageStreamShowTodos = true;
    toolGroupingExploreEnabled = true;
    toolGroupingTerminalEnabled = true;
    toolGroupingChangesEnabled = true;

    # Task auto-archive.
    taskAutoArchiveEnabled = true;
    taskAutoArchiveOlderThanDays = 3;

    # Security/privacy pins.
    embeddedBrowserAllowInsecureCertificates = false;
    modelIoFullRetentionEnabled = false;

    # Builtin CLI providers enabled for the agent.
    enabledBuiltinAgentCliProviders = [ "glm" ];
  };
}
