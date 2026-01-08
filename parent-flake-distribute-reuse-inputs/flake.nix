{
  description = "Parent flake";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, ... }:
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
          "x86_64-darwin"
        ];

        perSystem =
          { pkgs, ... }:
          {
            packages.default = pkgs.hello;
          };

        flake = {
          # A sample Home Manager module
          homeManagerModules.default =
            {
              lib,
              config,
              pkgs,
              ...
            }:
            let
              cfg = config.myProgram;
            in
            {
              # This pattern:
              # https://flake.parts/define-module-in-separate-file.html
              options.myProgram = {
                enable = lib.mkEnableOption "my awesome program";
                package = lib.mkOption {
                  default = withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }: config.packages.default);
                  defaultText = lib.literalMD "`packages.default` from the parent flake";
                };
              };

              config = lib.mkIf cfg.enable {
                home.packages = [ cfg.package ];
              };
            };
        };
      }
    );
}
