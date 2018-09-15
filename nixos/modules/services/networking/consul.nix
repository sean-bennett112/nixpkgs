{ config, lib, pkgs, utils, ... }:

with lib;

let

  cfg = config.services.consul;

in
{
  options = {

    services.consul = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enables the consul daemon.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.consul;
        defaultText = "pkgs.consul";
        description = ''
          The package used for the Consul agent and CLI.
        '';
      };

      leaveOnStop = mkOption {
        type = types.bool;
        default = false;
        description = ''
          If enabled, causes a leave action to be sent when closing consul.
          This allows a clean termination of the node, but permanently removes
          it from the cluster. You probably don't want this option unless you
          are running a node which going offline in a permanent / semi-permanent
          fashion.
        '';
      };

      dropPrivileges = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether the consul agent should be run as a non-root consul user.

          Note that it is recommended to run Consul as a non-root user.
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

      users.users."consul" = {
        description = "Consul agent daemon user";
        uid = config.ids.uids.consul;
        # The shell is needed for health checks
        shell = "/run/current-system/sw/bin/bash";
      };

      environment = {
        etc."consul.json".text = builtins.toJSON cfg.config;
        systemPackages = [ cfg.package ];
      };

      systemd.services.consul = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        # bindsTo = [ "network-online.target" ];
        restartTriggers = [ config.environment.etc."consul.json".source ];

        serviceConfig = {
          ExecStart = "@${cfg.package.bin}/bin/consul consul agent -config-file /etc/consul.json";
          ExecReload = "${cfg.package.bin}/bin/consul reload";
          PermissionsStartOnly = true;
          User = if cfg.dropPrivileges then "consul" else null;
          Restart = "on-failure";
          TimeoutStartSec = "0";
          Type = "notify";
        } // (optionalAttrs (cfg.leaveOnStop) {
          ExecStop = "${cfg.package.bin}/bin/consul leave";
        });
      };
    }]
  );
}