{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.virtualisation.oracleCloudImage;
  defaultConfigFile = pkgs.writeText "configuration.nix" ''
    { ... }:
    {
      imports = [
        <nixpkgs/nixos/modules/virtualisation/oracle-cloud-image.nix>
      ];
    }
  '';
in
{

  imports = [ ./oracle-cloud-config.nix ];

  options = {
    virtualisation.oracleCloudImage.diskSize = mkOption {
      type = with types; either (enum [ "auto" ]) int;
      # Charged by rounded up to the gigabyte - we want to stay comfortably under 1GB if possible
      default = 1024;
      example = 1536;
      description = ''
        Size of disk image. Unit is MB.
      '';
    };

    virtualisation.oracleCloudImage.configFile = mkOption {
      type = with types; nullOr str;
      default = null;
      description = ''
        A path to a configuration file which will be placed at `/etc/nixos/configuration.nix`
        and be used when switching to a new configuration.
        If set to `null`, a default configuration is used, where the only import is
        `<nixpkgs/nixos/modules/virtualisation/oracle-cloud-image.nix>`.
      '';
    };
  };

  #### implementation
  config = {

    system.build.oracleCloudImage = import ../../lib/make-disk-image.nix {
      name = "oracle-cloud-image";
      format = "qcow2";
      partitionTableType = "efi";
      configFile = if cfg.configFile == null then defaultConfigFile else cfg.configFile;
      inherit (cfg) diskSize;
      inherit config lib pkgs;
    };

  };

}
