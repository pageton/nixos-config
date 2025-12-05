# Virtualisation (Docker) configuration.
# This module enables various virtualization technologies for running
{
  pkgsStable,
  user,
  ...
}:
{
  virtualisation = {
    # Docker container runtime
    docker = {
      enable = true;
      enableOnBoot = false; # Enable Docker socket but not daemon
    };
  };

  # Add user to virtualization groups for proper access
  users.users."${user}" = {
    isNormalUser = true;
    extraGroups = [
      "docker" # Access to Docker daemon
    ];
  };

  # NVIDIA Container Toolkit for GPU support in Docker
  hardware.nvidia-container-toolkit.enable = true;

  # Install virtualization management tools
  environment.systemPackages = with pkgsStable; [
    nvidia-container-toolkit # NVIDIA Container Toolkit CLI tools
  ];
}
