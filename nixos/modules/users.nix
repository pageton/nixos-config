# User and authentication configuration.
# This module configures user accounts, default shells, and system group memberships
{
  config,
  pkgs,
  user,
  ...
}:
{
  # Enable Zsh as the system-wide default shell
  programs.zsh.enable = true;

  users = {
    # Set Zsh as the default shell for all users
    defaultUserShell = pkgs.zsh;

    # Configure the main user account
    users.${user} = {
      isNormalUser = true; # Create a normal user account (not system account)

      # Additional groups for enhanced permissions and functionality
      extraGroups = [
        "networkmanager" # Access to NetworkManager for network configuration
        "wheel" # Sudo privileges for system administration
        "video" # Access to video devices (NVIDIA control, webcam, etc.)
        "input" # Access to input devices (keyboard, mouse, touchpad)
        "render" # Access to GPU rendering (NVIDIA, AMD, Intel)
        "audio" # Access to audio devices
        "i2c" # Access to I2C devices (some hardware sensors)
        "optical" # Access to optical drives
        "scanner" # Access to scanners
        "lp" # Access to printers
        "dialout" # Access to serial ports (Arduino, etc.)
        "uucp" # Access to serial devices
        "plugdev" # Access to pluggable devices (USB, etc.)
      ];
    };
  };

  system.activationScripts.ssh-authorized-keys = {
    deps = [ "setupSecrets" ];
    text = ''
      mkdir -p /home/${user}/.ssh
      chmod 700 /home/${user}/.ssh
      cp -f ${config.sops.secrets.ssh-public-key.path} /home/${user}/.ssh/authorized_keys.tmp
      chmod 600 /home/${user}/.ssh/authorized_keys.tmp
      chown ${user}:users /home/${user}/.ssh/authorized_keys.tmp
      mv -f /home/${user}/.ssh/authorized_keys.tmp /home/${user}/.ssh/authorized_keys
    '';
  };
}
