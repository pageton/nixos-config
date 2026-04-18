# Hardware support — audio, Bluetooth, GPU drivers, input, power, and peripherals.
{
  imports = [
    ../audio.nix # PipeWire with ALSA/Pulse/JACK compat, RNNoise suppression
    ../android.nix # ADB and Android debugging tools
    ../bluetooth.nix # BlueZ + Blueman (opt-in via mySystem.bluetooth)
    ../graphics.nix # NVIDIA proprietary driver, VA-API, Wayland env vars
    ../libinput.nix # libinput for touchpad/mouse handling
    ../upower.nix # Power statistics and battery reporting
    ../thermal.nix # AMD Ryzen thermal management via thermald
  ];
}
