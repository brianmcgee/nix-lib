{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-root.url = "github:srid/flake-root";
  };

  outputs = inputs @ {
    nixpkgs,
    flake-parts,
    flake-root,
    treefmt-nix,
    ...
  }: let
    #
    lib = nixpkgs.lib.extend (import ./lib.nix);
  in
    (flake-parts.lib.evalFlakeModule
      {
        inherit inputs;
        specialArgs = {inherit lib;};
      }
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ];

        imports = [
          {
            imports = [
              treefmt-nix.flakeModule
              flake-root.flakeModule
            ];
            perSystem = {config, ...}: {
              treefmt.config = {
                inherit (config.flake-root) projectRootFile;
                flakeCheck = true;
                flakeFormatter = true;
                programs = {
                  alejandra.enable = true;
                  deadnix.enable = true;
                  statix.enable = true;
                };
              };
            };
          }
        ];

        flake.flakeModules = with lib;
          mapAttrs (_: import)
          (fs.rakeLeaves ./flake-parts);
      })
    .config
    .flake;
}
