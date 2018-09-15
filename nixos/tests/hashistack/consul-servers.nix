import ../make-test.nix ({ pkgs, ... }:
{
  name = "consul";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ lnl7 ];
  };

  nodes = {
    server1 = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.consul ];

      services.consul.enable = true;
      services.consul.config = {
        bind_addr = "{{ GetInterfaceIP \"eth1\" }}";
        bootstrap_expect = 3;
        client_addr = "{{ GetInterfaceIP \"eth1\" }} 127.0.0.1";
        datacenter = "local";
        data_dir = "/var/lib/consul";
        disable_host_node_id = false;
        retry_join = [ "192.168.1.2" "192.168.1.3" ];
        # retry_join = [ "{{ GetInterfaceIPs \"eth1\" }}" ];
        server = true;
        node_name = "server1";
        ui = true;
      };

      networking.firewall.allowedTCPPorts = [ 8301 8302 8500 8600 ];


    };

    server2 = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.consul ];

      services.consul.enable = true;
      services.consul.config = {
        bind_addr = "{{ GetInterfaceIP \"eth1\" }}";
        bootstrap_expect = 3;
        client_addr = "{{ GetInterfaceIP \"eth1\" }} 127.0.0.1";
        datacenter = "local";
        data_dir = "/var/lib/consul";
        disable_host_node_id = false;
        retry_join = [ "192.168.1.1" "192.168.1.3" ];
        # retry_join = [ "{{ GetInterfaceIPs \"eth1\" }}" ];
        server = true;
        node_name = "server2";
        ui = true;
      };

      networking.firewall.allowedTCPPorts = [ 8301 8302 8500 8600 ];


    };

    server3 = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.consul ];

      services.consul.enable = true;
      services.consul.config = {
        bind_addr = "{{ GetInterfaceIP \"eth1\" }}";
        bootstrap_expect = 3;
        client_addr = "{{ GetInterfaceIP \"eth1\" }} 127.0.0.1";
        datacenter = "local";
        data_dir = "/var/lib/consul";
        disable_host_node_id = false;
        retry_join = [ "192.168.1.1" "192.168.1.2" ];
        # retry_join = [ "{{ GetInterfaceIPs \"eth1\" }}" ];
        server = true;
        node_name = "server3";
        ui = true;
      };

      networking.firewall.allowedTCPPorts = [ 8301 8302 8500 8600 ];


    };
  };

  testScript =
    ''
      startAll;

      $server1->waitForUnit('multi-user.target');
      $server1->waitForUnit('consul.service');
      $server1->waitForOpenPort(8500);
      $server2->waitForUnit('multi-user.target');
      $server2->waitForUnit('consul.service');
      $server2->waitForOpenPort(8500);
      $server3->waitForUnit('multi-user.target');
      $server3->waitForUnit('consul.service');
      $server3->waitForOpenPort(8500);
      $server1->execute("consul members 1>&2");
      $server1->execute("consul members | grep server1 | grep alive");
      $server1->execute("consul members | grep server2 | grep alive");
      $server1->execute("consul members | grep server3 | grep alive");
      $server2->execute("consul members 1>&2");
      $server2->execute("consul members | grep server1 | grep alive");
      $server2->execute("consul members | grep server2 | grep alive");
      $server2->execute("consul members | grep server3 | grep alive");
      $server3->execute("consul members 1>&2");
      $server3->execute("consul members | grep server1 | grep alive");
      $server3->execute("consul members | grep server2 | grep alive");
      $server3->execute("consul members | grep server3 | grep alive");
    '';
})
