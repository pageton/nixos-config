# OpenCode permission policies.
#
# Agent definitions (plan/build/review/recon/patch/optimize) were removed:
# opencode falls back to its native agents, and the top-level
# `programs.aiAgents.opencode.permission` (yoloPermission) is merged into them.
# android-re/web-re agents keep their own definitions.

{
  yoloPermission = {
    read = "allow";
    edit = "allow";
    glob = "allow";
    grep = "allow";
    list = "allow";
    bash = "allow";
    task = "allow";
    external_directory = "allow";
    todowrite = "allow";
    question = "allow";
    webfetch = "allow";
    websearch = "allow";
    codesearch = "allow";
    lsp = "allow";
    doom_loop = "allow";
    skill = "allow";
  };
}
