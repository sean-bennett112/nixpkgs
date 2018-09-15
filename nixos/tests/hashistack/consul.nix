import ../make-test.nix ({ pkgs, ... }:
{
  name = "consul";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ lnl7 ];
  };
  machine = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.consul ];

    services.consul.enable = true;
    services.consul.config = {
      bind_addr = "{{ GetPrivateIP }}";
      bootstrap_expect = 1;
      client_addr = "{{ GetPrivateIP }} 127.0.0.1";
      datacenter = "local";
      data_dir = "/var/lib/consul";
      disable_host_node_id = false;
      server = true;
      node_name = "server1";
      ui = true;
    };
    # environment.systemPackages = with pkgs; [
    #   arp-scan
    # ];

    # networking.firewall.enable = false;
    # networking.firewall.allowPing = true;
    # networking.firewall.allowedTCPPorts = [ 4646 4647 4648 8301 8302 8500 8600 ];


  };

  testScript =
    ''
      startAll;

      $machine->waitForUnit('multi-user.target');
      $machine->waitForUnit('consul.service');
      $machine->waitForOpenPort(8500);
      $machine->execute("consul members | grep server1 | grep alive");
    '';
})
