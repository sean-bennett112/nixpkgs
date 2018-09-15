import ../make-test.nix ({ pkgs, ... }:
{
  # Change to show up in git
  name = "nomad";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ lnl7 ];
  };
  machine = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      consul
      nomad
    ];

    services.consul.enable = true;
    services.consul.config = {
      bootstrap_expect = 1;
      client_addr = "{{ getPrivateIp }} 127.0.0.1";
      datacenter = "local";
      data_dir = "/var/lib/consul";
      server = true;
      node_name = "server1";
      ui = true;
    };

    services.nomad.enable = true;
    services.nomad.config = {
      data_dir = "/var/lib/nomad";
      server = {
        enabled = true;
        bootstrap_expect = 1;
      };
      client = {
        enabled = false;
      };
      consul = {
        address = "localhost:8500";
      };
    };
  };

  testScript =
    ''
      startAll;

      $machine->waitForUnit('multi-user.target');
      $machine->waitForUnit('nomad.service');
      $machine->waitForOpenPort(8302);
      $machine->succeed('nomad status | grep true');
    '';
})
