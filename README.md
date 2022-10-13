This repository can be used as a template for setting a Nix flake that includes [Plutip](https://github.com/mlabs-haskell/plutip).

Commands to build and run:
```
nix develop .#offchain
cabal run plutip-flake
```

The project is importing and making use of `Plutip`s library, therefore, you will need to make sure that the following executables are present in your `PATH`:

* `cardano-cli` executable available in the environment
* `cardano-node` executable available in the environment

And the following ghc flag must to be set for the test execution: `-Wall -threaded -rtsopts`

NOTE: This branch launches local network in `Vasil`. It was tested with node `1.35.3` (this node version used in nix environment as well). Please use appropriate node version when setting up own binaries in `PATH`.