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
  in
  {
    name = name;
    value = {pkgs, ...}: {
      environment.systemPackages = [ pkgs.consul ];

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
        bootstrap_expect = total;
        server = true;
      }) // (optionalAttrs (client) {
        client_addr = "{{ GetInterfaceIP \"eth1\" }} 127.0.0.1";
      });

      networking.firewall.allowedTCPPorts = [ 8300 8301 8302 8500 8600 ];
    };
  };

  makeTestInit = index: { server, client, ... }:
  let
    name = if server then "server${toString index}" else "client${toString index}";
  in
  ''
    ''$${name}->waitForUnit('multi-user.target');
    ''$${name}->waitForUnit('consul.service');
    ''$${name}->waitForOpenPort(8500);
  '';

  makeTestVerify = index: { server, client, ... }:
  let
    name = if server then "server${toString index}" else "client${toString index}";
    total = toString (server_count + client_count + 1);
  in
  ''
    ''$${name}->execute("consul members 1>&2");
    ''$${name}->execute("consul members -status alive | wc -l 1>&2");
    ''$${name}->execute("consul members -status alive | wc -l | grep ${total}");
    ''$${name}->execute("curl localhost:8500/ui/ 1>&2");
  '';

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
