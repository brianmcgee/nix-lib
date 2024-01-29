{
  lib,
  config,
  flake-parts-lib,
  ...
}: let
  inherit (config) systems allSystems;
in {
  options.perSystem = flake-parts-lib.mkPerSystemOption {
    options.nixosConfigurations = with lib;
      mkOption {
        type = types.lazyAttrsOf types.raw;
        default = {};
        description = ''
          Allows defining NixOS configurations as perSystem attributes.
          All configs are transposed to flake.nixosConfigurations.''${system}_''${name}.
          Use lib.mkIf to filter out unsupported systems if required.
        '';
        example = literalExpression ''
          { inputs, ... }: {
            perSystem = { pkgs, ... }: {
                my-machine = inputs.nixpkgs.lib.nixosSystem {
                    inherit pkgs;
                    modules = [
                      ./my-machine/nixos-configuration.nix
                      config.nixosModules.my-module
                    ];
                };
            };
          }
        '';
      };
  };

  config.flake.nixosConfigurations = with lib;
    foldl
    (x: y: x // y)
    {}
    (
      map
      (system: mapAttrs' (n: v: nameValuePair "${system}_${n}" v) (attrByPath [system "nixosConfigurations"] {} allSystems))
      systems
    );
}
