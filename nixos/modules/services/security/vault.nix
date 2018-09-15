{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.vault;

  # configFile = pkgs.writeText "vault.hcl" ''
  #   listener "tcp" {
  #     address = "${cfg.address}"
  #     ${if (cfg.tlsCertFile == null || cfg.tlsKeyFile == null) then ''
  #         tls_disable = "true"
  #       '' else ''
  #         tls_cert_file = "${cfg.tlsCertFile}"
  #         tls_key_file = "${cfg.tlsKeyFile}"
  #       ''}
  #     ${cfg.listenerExtraConfig}
  #   }
  #   storage "${cfg.storageBackend}" {
  #     ${optionalString (cfg.storagePath   != null) ''path = "${cfg.storagePath}"''}
  #     ${optionalString (cfg.storageConfig != null) cfg.storageConfig}
  #   }
  #   ${optionalString (cfg.telemetryConfig != "") ''
  #       telemetry {
  #         ${cfg.telemetryConfig}
  #       }
  #     ''}
  #   ${cfg.extraConfig}
  # '';
in

{
  options = {
    services.vault = {
      enable = mkEnableOption "Vault daemon";

      package = mkOption {
        type = types.package;
        default = pkgs.vault;
        defaultText = "pkgs.vault";
        description = "This option specifies the vault package to use.";
      };

      config = mkOption {
        default = {};
        description = ''
          Configuration options which are serialized to json and set
          to the config.json file.
        '';
      };
    };
  };

  config = mkIf cfg.enable (
    mkMerge [{
      # assertions = [
      #   { assertion = cfg.storageBackend == "inmem" -> (cfg.storagePath == null && cfg.storageConfig == null);
      #     message = ''The "inmem" storage expects no services.vault.storagePath nor services.vault.storageConfig'';
      #   }
      #   { assertion = (cfg.storageBackend == "file" -> (cfg.storagePath != null && cfg.storageConfig == null)) && (cfg.storagePath != null -> cfg.storageBackend == "file");
      #     message = ''You must set services.vault.storagePath only when using the "file" backend'';
      #   }
      # ];

      users.users.vault = {
        name = "vault";
        group = "vault";
        uid = config.ids.uids.vault;
        description = "Vault daemon user";
      };
      users.groups.vault.gid = config.ids.gids.vault;

      environment = {
        etc."vault.json".text = builtins.toJSON cfg.config;
        systemPackages = [ cfg.package ];
      };

      systemd.services.vault = {
        description = "Vault server daemon";

        wantedBy = ["multi-user.target"];
        after = [ "network-online.target" ];
            # ++ optional (config.services.consul.enable && cfg.storageBackend == "consul") "consul.service";

        restartIfChanged = false; # do not restart on "nixos-rebuild switch". It would seal the storage and disrupt the clients.

        # preStart = optionalString (cfg.storagePath != null) ''
        #   install -d -m0700 -o vault -g vault "${cfg.storagePath}"
        # '';

        serviceConfig = {
          User = "vault";
          Group = "vault";
          PermissionsStartOnly = true;
          ExecStart = "${cfg.package}/bin/vault server -config /etc/vault.json";#${configFile}";
          PrivateDevices = true;
          PrivateTmp = true;
          ProtectSystem = "full";
          ProtectHome = "read-only";
          AmbientCapabilities = "cap_ipc_lock";
          NoNewPrivileges = true;
          KillSignal = "SIGINT";
          TimeoutStopSec = "30s";
          Restart = "on-failure";
          StartLimitInterval = "60s";
          StartLimitBurst = 3;
        };

        # unitConfig.RequiresMountsFor = optional (cfg.storagePath != null) cfg.storagePath;
      };
    }]
  );
}
