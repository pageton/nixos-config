{lib, ...}: {
  disko.devices = {
    disk.disk1 = {
      type = "disk";
      device = lib.mkDefault "/dev/sda";

      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };

          # EFI System Partition
          esp = {
            name = "ESP";
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };

          # Root volume (LVM)
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "lvm_pv";
              vg = "vg0";
            };
          };
        };
      };
    };

    lvm_vg.vg0 = {
      type = "lvm_vg";
      lvs = {
        root = {
          size = "100%FREE";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = ["defaults"];
          };
        };
      };
    };
  };
}
