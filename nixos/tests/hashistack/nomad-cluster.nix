import ../make-test.nix ({ pkgs, lib, ... }:

with lib;

let
  server_count = 3;
  client_count = 3;

  servers = imap1 (index: value: { server = true; client = false; }) (range 1 server_count);
  clients = imap1 (index: value: { server = false; client = true; }) (range 1 client_count);
  spec = servers ++ clients;

  makeConsulConfig = i: total: { server, client, ... }:
  let
    index = toString i;
    name = if server then "server${index}" else "client${index}";
    join_list = imap1 (index: value: "192.168.1.${toString index}") (range 1 total);
    consul_ports = [ 8300 8301 8302 8500 8600 ];
    nomad_ports = [ 4646 4647 4648 ];
  in
  {
    name = name;
    value = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        consul
        nomad
      ];

      services.consul.enable = true;
      services.consul.config = {
        bind_addr = "{{ GetInterfaceIP \"eth1\" }}";
        datacenter = "local";
        data_dir = "/var/lib/consul";
        disable_host_node_id = false;
        retry_join = join_list;
        node_name = name;
        ui = true;
      } // (optionalAttrs (server) {
        bootstrap_expect = server_count;
        server = true;
      }) // (optionalAttrs (client) {
        client_addr = "{{ GetInterfaceIP \"eth1\" }} 127.0.0.1";
      });

      services.nomad.enable = true;
      services.nomad.config = {
        bind_addr = "0.0.0.0";#"{{ GetInterfaceIP \"eth1\" }}";
        data_dir = "/var/lib/nomad";
        datacenter = "local";
        consul = {
          address = "localhost:8500";
        };
        name = name;
        consul.server_auto_join = true;
        server = {
          enabled = true;
          bootstrap_expect = total;
        };
      };
      # } // (optionalAttrs (server) {
      #   consul.server_auto_join = true;
      #   server = {
      #     enabled = true;
      #     bootstrap_expect = server_count;
      #   };
      # }) // (optionalAttrs (client) {
      #   consul.client_auto_join = true;
      #   client = {
      #     enabled = true;
      #     network_interface = "eth1";
      #   };
      # });
      systemd.services.nomad.after = [ "network-online.target" "consul.service" ];
      systemd.services.nomad.requires = [ "network-online.target" "consul.service" ];

      networking.firewall.enable = false;
      networking.firewall.allowedTCPPorts = consul_ports ++ nomad_ports;
      networking.firewall.allowedUDPPorts = consul_ports ++ nomad_ports;
    };
  };

  makeTestInit = index: { server, client, ... }:
  let
    name = if server then "server${toString index}" else "client${toString index}";
  in
  ''
    ''$${name}->waitForUnit('multi-user.target');
    ''$${name}->waitForUnit('consul.service');
    ''$${name}->waitForUnit('nomad.service');
  '';
    # ''$${name}->execute("systemctl cat nomad 1>&2");
    # ''$${name}->execute("ls -alh /etc/nomad* 1>&2");
    # ''$${name}->execute("cat /etc/nomad.json 1>&2");
    # ''$${name}->execute("ifconfig -a 1>&2");
    # ''$${name}->execute("ip link show 1>&2");
    # ''$${name}->execute("which ip 1>&2");
    # ''$${name}->execute("echo \$PATH 1>&2");
    # ''$${name}->execute("nomad version 1>&2");
    # ''$${name}->waitForOpenPort(8500);
    # ''$${name}->waitForOpenPort(4646);

  makeTestVerify = index: { server, client, ... }:
  let
    name = if server then "server${toString index}" else "client${toString index}";
    total = toString (server_count + client_count + 1);
  in
  ''
    ''$${name}->execute("consul members 1>&2");
    ''$${name}->execute("consul members -status alive | wc -l | grep ${total}");
    ''$${name}->execute("curl 192.168.1.1:4646/v1/agent/health 1>&2");
    ''$${name}->execute("curl 192.168.1.2:4646/v1/agent/health 1>&2");
    ''$${name}->execute("nomad server members 1>&2");
    ''$${name}->execute("nomad node status 1>&2");
    ''$${name}->execute("consul catalog services 1>&2");
  '';
    # ''$${name}->execute("curl localhost:8500/ui/ 1>&2");
    # ''$${name}->execute("curl localhost:4646/ui/ 1>&2");

  nodes = listToAttrs (imap1 (index: value: makeConsulConfig index (server_count + client_count) value) spec);
  test_init = concatStrings (imap1 (index: value: makeTestInit index value) spec);
  test_verify = concatStrings (imap1 (index: value: makeTestVerify index value) spec);
in
{
  name = "consul";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ lnl7 ];
  };

  nodes = nodes;

  testScript =
    ''
      startAll;

      ${test_init}
      ${test_verify}
    '';
})
