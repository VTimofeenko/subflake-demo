{
  description = "Development flake";

  inputs = {
    parent.url = ./..;
    devshell.url = "github:numtide/devshell";
    # `flake-parts` demands an instance of nixpkgs.
    # Is there any way to reuse nixpkgs from parent?
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # As an example, the development flake runs tests on home manager modules
    # But the parent flake does not need to have home-manager as an input
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs =
    inputs@{ self, ... }:
    let
      # This bit of code allows reusing the parent's inputs
      parentInputs = inputs.parent.inputs;
    in
    parentInputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devshell.flakeModule ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          inputs',
          pkgs,
          ...
        }:
        {
          # A sample development shell
          devshells.default = {
            env = [
              {
                name = "HTTP_PORT";
                value = 8080;
              }
            ];
            commands = [
              {
                name = "test-interactive";
                # Note the /subflake syntax that allows referencing this subflake
                # The downside of this approach is if the subflake were to be moved, this command would break
                # I tried various combos of "`self`" but could not get them to work.
                command = "nix run ./subflake#checks.x86_64-linux.homeManagerModuleTest.driverInteractive -- --interactive";
                help = "Run interactive test";
              }
            ];
          };

          # Allows running `nix run .#` in the subflake which will run parent's package
          packages.default = inputs'.parent.packages.default;

          # Checks. Inlined so it's all self-contained.
          checks.homeManagerModuleTest = pkgs.testers.runNixOSTest {
            name = "homeManagerModuleTest";
            nodes.machine = {
              services.getty.autologinUser = "alice";
              users.users.alice = {
                isNormalUser = true;
                password = "hunter2";
                extraGroups = [ "input" ];
              };
              imports = [ self.inputs.home-manager.nixosModules.home-manager ];
              home-manager.users.alice = {
                imports = [ inputs.parent.homeManagerModules.default ];
                home.stateVersion = "25.11";
                myProgram.enable = true;
              };
            };

            testScript = /* python */ ''
              machine.wait_for_unit("default.target")
              machine.succeed("su -- alice -c 'which hello'")
              machine.fail("su -- root -c 'which hello'")
            '';
          };
        };
      flake = { };
    };
}
