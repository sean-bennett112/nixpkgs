import ./make-test.nix ({ pkgs, ... }:
{
  # Change to show up in git
  name = "vault";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ lnl7 ];
  };
  machine = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.vault ];
    environment.variables.VAULT_ADDR = "http://127.0.0.1:8200";
    services.vault.enable = true;
    services.vault.config = {

    };
  };

  testScript =
    ''
      startAll;

      $machine->waitForUnit('multi-user.target');
      $machine->waitForUnit('vault.service');
      $machine->waitForOpenPort(8200);
      $machine->succeed('vault operator init');
      $machine->succeed('vault status | grep Sealed | grep true');
    '';
})
