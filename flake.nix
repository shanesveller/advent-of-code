{
  description = "Elixir Advent of Code Workspace";

  inputs = {
    beam-flakes.url = "github:shanesveller/nix-beam-flakes";
    beam-flakes.inputs.flake-parts.follows = "flake-parts";
    beam-flakes.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    stable.url = "nixpkgs/nixos-23.11";
  };

  nixConfig = {
    extra-substituters = ["https://shanesveller-nix-beam-flakes.cachix.org"];
    extra-trusted-public-keys = [
      "shanesveller-nix-beam-flakes.cachix.org-1:DMWI87/57GNone8wN7dXcqlgdIk36qHfvhXJ/esq5hk="
    ];
  };

  outputs = inputs @ {
    beam-flakes,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [beam-flakes.flakeModule];

      systems = ["aarch64-darwin" "x86_64-linux"];

      perSystem = {
        config,
        inputs',
        lib,
        pkgs,
        system,
        ...
      }: let
        inherit (inputs'.beam-flakes.packages) livebook;
        nixpkgsConfig = {
          allowUnfreePredicate = pkg:
            builtins.elem (lib.getName pkg) [
              "cudatoolkit"
              "cudatoolkit-12-cudnn"
              "libcublas"
              "nvidia-x11"
            ];
          enableCuda = system == "x86_64-linux";
        };
        inherit (stable.zfs.latestCompatibleLinuxPackages) nvidia_x11;
        cudaPackages = unstable.cudaPackages_12_1.overrideScope' (final: prev: {
          cudnn = prev.cudnn_8_9;
        });
        stable = import inputs.stable {
          inherit system;
          config = nixpkgsConfig;
        };
        unstable = import inputs.nixpkgs {
          inherit system;
          config = nixpkgsConfig;
        };
      in {
        _module.args.pkgs = unstable;

        formatter = pkgs.alejandra;

        beamWorkspace = {
          enable = true;
          devShell = {
            extraArgs = lib.mkIf pkgs.stdenv.isLinux {
              LD_LIBRARY_PATH = lib.makeLibraryPath ([nvidia_x11]
                ++ (with cudaPackages; [
                  cudatoolkit
                  cudnn
                  libcublas
                ]));
              XLA_FLAGS = "--xla_gpu_cuda_data_dir=${cudaPackages.cudatoolkit}";
              XLA_TARGET = "cuda120";
            };
            extraPackages =
              [livebook]
              ++ lib.optionals pkgs.stdenv.isLinux ([nvidia_x11]
                ++ (with pkgs; [
                  autoconf
                  cmake
                  gcc
                  gnumake
                ])
                ++ (with cudaPackages; [
                  cudatoolkit
                ]));
            languageServers.elixir = true;
            languageServers.erlang = false;
          };
          versions = {
            elixir = "1.15.7";
            erlang = "26.1.2";
          };
        };

        packages.gcroot = config.devShells.default.inputDerivation;
      };
    };
}
