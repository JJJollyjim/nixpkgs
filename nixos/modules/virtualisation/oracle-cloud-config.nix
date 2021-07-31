{ config, lib, pkgs, ... }:
with lib;
{
  imports = [
    ../profiles/qemu-guest.nix
  ];


  fileSystems."/" = {
    fsType = "ext4";
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
  };

  boot.growPartition = true;
  boot.initrd.availableKernelModules = [ "virtio_pci" ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  systemd.services.fetch-instance-ssh-keys = {
    description = "Fetch host keys and authorized_keys for root user";

    wantedBy = [ "sshd.service" ];
    before = [ "sshd.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.wget ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.runCommand "fetch-instance-ssh-keys" { } ''
        cp ${./fetch-oracle-instance-ssh-keys.bash} $out
        chmod +x $out
        ${pkgs.shfmt}/bin/shfmt -i 4 -d $out
        ${pkgs.shellcheck}/bin/shellcheck $out
        patchShebangs $out
      '';
      PrivateTmp = true;
      StandardError = "journal+console";
      StandardOutput = "journal+console";
    };
  };

  # Generate a systemd-boot menu.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Allow root logins only using SSH keys
  # and disable password authentication in general
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "prohibit-password";
  services.openssh.passwordAuthentication = mkDefault false;

  # Rely on OCI's firewall instead
  networking.firewall.enable = mkDefault false;

  networking.useDHCP = true;

  # OCI has its own NTP server provided by the hypervisor
  networking.timeServers = [ "169.254.169.254" ];

  systemd.services.print-host-key =
    { description = "Print SSH Host Key";
      wantedBy = [ "multi-user.target" ];
      after = [ "sshd.service" ];
      script =
        ''
          # Print the host public key on the console so that the user
          # can obtain it securely by parsing the output of
          # oci compute console-history.
          echo "-----BEGIN SSH HOST KEY FINGERPRINTS-----" > /dev/console
          for i in /etc/ssh/ssh_host_*_key.pub; do
              ${config.programs.ssh.package}/bin/ssh-keygen -l -f $i > /dev/console
          done
          echo "-----END SSH HOST KEY FINGERPRINTS-----" > /dev/console
        '';
      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = true;
    };
}
