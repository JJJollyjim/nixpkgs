{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.metricbeat;

  metricbeatYml = pkgs.writeText "metricbeat.yml" ''
    name: ${cfg.name}
    tags: ${builtins.toJSON cfg.tags}

    ${cfg.extraConfig}
  '';

in
{
  options = {

    services.metricbeat = {

      enable = mkEnableOption "metricbeat";

      package = mkOption {
        type = types.package;
        default = pkgs.metricbeat;
        defaultText = "pkgs.metricbeat";
        example = literalExample "pkgs.metricbeat7";
        description = ''
          The metricbeat package to use
        '';
      };

      name = mkOption {
        type = types.str;
        default = "metricbeat";
        description = "Name of the beat";
      };

      tags = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Tags to place on the shipped events";
      };

      stateDir = mkOption {
        type = types.str;
        default = "/var/lib/metricbeat";
        description = "The state directory. metricbeat's own logs and other data are stored here.";
      };

      extraConfig = mkOption {
        type = types.lines;
        description = "Any other configuration options you want to add";
      };

    };
  };

  config = mkIf cfg.enable {

    systemd.tmpfiles.rules = [
      "d '${cfg.stateDir}' - nobody nogroup - -"
    ];

    systemd.services.metricbeat = with pkgs; {
      description = "metricbeat log shipper";
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        mkdir -p "${cfg.stateDir}"/{data,logs}
      '';
      serviceConfig = {
        User = "nobody";
        ExecStart = "${cfg.package}/bin/metricbeat -c \"${metricbeatYml}\" -path.data \"${cfg.stateDir}/data\" -path.logs \"${cfg.stateDir}/logs\"";
      };
    };
  };
}
