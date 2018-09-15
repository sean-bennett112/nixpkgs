{ config, lib, pkgs, utils, ... }:

with lib;

let

  cfg = config.services.nomad;

in
{
  options = {

    services.nomad = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enables the nomad daemon.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.nomad;
        defaultText = "pkgs.nomad";
        description = ''
          The package used for the Nomad agent and CLI.
        '';
      };

      config = mkOption {
        default = { };
        description = ''
          Configuration options which are serialized to json and set
          to the config.json file.
        '';
      };
    };
  };

  config = mkIf cfg.enable (
    mkMerge [{

      users.users."nomad" = {
        description = "Nomad agent daemon user";
      };

      environment = {
        etc."nomad.json".text = builtins.toJSON cfg.config;
        systemPackages = [ cfg.package ];
      };

      systemd.services.nomad = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        requires = [ "network-online.target" ];
        # bindsTo = [ "network-online.target" ];
        restartTriggers = [ config.environment.etc."nomad.json".source ];

        serviceConfig = {
          ExecStart = "@${cfg.package.bin}/bin/nomad nomad agent -config /etc/nomad.json";
          ExecReload = "${cfg.package.bin}/bin/nomad reload";
          PermissionsStartOnly = true;
          # User = "nomad";
          Restart = "on-failure";
          TimeoutStartSec = "0";
        };
      };
    }]
  );
}