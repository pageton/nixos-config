# Skill installations for all AI agents.
# Imported by config/defaults.nix.
#
# TON skills (ton-org/skills): wallets + docs.
# To install skills temporarily: just skill-add <repo>
# To restore permanently: add repos below + just skills-rebuild + nh home switch
{
  skills = [
    {
      repo = "ton-org/skills";
      skill = "wallets";
    }
    {
      repo = "ton-org/skills";
      skill = "docs";
    }
  ];
}
