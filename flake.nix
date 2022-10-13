{
  description = "plutip-flake";
  nixConfig.bash-prompt = "\\[\\e[0m\\][\\[\\e[0;2m\\]plutip-flake \\[\\e[0;1m\\]plutip-flake \\[\\e[0;93m\\]\\w\\[\\e[0m\\]]\\[\\e[0m\\]$ \\[\\e[0m\\]";

  inputs = {
    nixpkgs.follows = "plutip/nixpkgs";
    haskell-nix.follows = "plutip/haskell-nix";

    plutip.url = "github:mlabs-haskell/plutip";
  };


  outputs = inputs@{ self, nixpkgs, haskell-nix, plutip, ... }:
    let
      defaultSystems = [ "x86_64-linux" "x86_64-darwin" ];
      perSystem = nixpkgs.lib.genAttrs defaultSystems;

      nixpkgsFor = system: import nixpkgs {
        inherit system;
        overlays = [ haskell-nix.overlay (import "${plutip.inputs.iohk-nix}/overlays/crypto") ];
        inherit (haskell-nix) config;
      };
      nixpkgsFor' = system: import nixpkgs { inherit system; };

      deferPluginErrors = true;

      offchain = rec {
        ghcVersion = "ghc8107";

        projectFor = system:
          let
            pkgs = nixpkgsFor system;
            pkgs' = nixpkgsFor' system;
            plutipin = inputs.plutip.inputs;
            project = pkgs.haskell-nix.cabalProject' {
              name = "plutip-flake";
              src = ./.;
              compiler-nix-name = ghcVersion;
              inherit (plutip) cabalProjectLocal;
              extraSources = plutip.extraSources ++ [
                {
                  src = "${plutip}";
                  subdirs = [ "." ];
                }
              ];
              modules = plutip.haskellModules;
              shell = {
                withHoogle = true;

                exactDeps = true;

                # We use the ones from Nixpkgs, since they are cached reliably.
                # Eventually we will probably want to build these with haskell.nix.
                nativeBuildInputs = [
                  pkgs'.cabal-install
                  pkgs'.fd
                  pkgs'.hlint

                  project.hsPkgs.cardano-cli.components.exes.cardano-cli
                  project.hsPkgs.cardano-node.components.exes.cardano-node
                ];

                tools.haskell-language-server = "latest";

                additional = ps: [ ps.plutip ];
              };
            };
          in
          project;
      };
    in
    {
      inherit nixpkgsFor;

      offchain = {
        project = perSystem offchain.projectFor;
        flake = perSystem (system: (offchain.projectFor system).flake { });
      };

      packages = perSystem (system:
        self.offchain.flake.${system}.packages
      );

      devShells = perSystem (system: {
        offchain = self.offchain.flake.${system}.devShell;
      });
    };
}

