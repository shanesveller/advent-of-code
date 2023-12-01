{
  description = "Advent of Code Solutions - 2023";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-darwin" "x86_64-linux"];
      perSystem = {
        config,
        lib,
        system,
        ...
      }: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [inputs.rust-overlay.overlays.default];
        };
        rustTools = (pkgs.rust-bin.fromRustupToolchainFile
          ./rust-toolchain.toml)
        .override {extensions = ["rust-analyzer" "rust-src"];};
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [pkgs.pkg-config];
          packages = with pkgs;
            [
              bacon
              config.packages.cargo-aoc
              cargo-nextest
              cargo-outdated
              cargo-watch
              rustTools
            ]
            ++ lib.optional pkgs.stdenv.isDarwin pkgs.libiconv;

          CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER =
            lib.optional pkgs.stdenv.isLinux "${pkgs.clang}/bin/clang";
          RUSTFLAGS =
            lib.optional pkgs.stdenv.isLinux
            "-C link-arg=-fuse-ld=${pkgs.mold}/bin/mold";
          RUST_SRC_PATH = "${rustTools}/lib/rustlib/src/rust/library";
        };

        formatter = pkgs.alejandra;

        packages = {
          cargo-aoc = let
            pname = "cargo-aoc";
            version = "0.3.7";
          in
            pkgs.rustPlatform.buildRustPackage {
              inherit pname version;

              src = pkgs.fetchFromGitHub {
                owner = "gobanos";
                repo = "cargo-aoc";
                rev = version;
                sha256 = "sha256-k9Lm91+Bk6EC8+KfEXhSs4ki385prZ6Vbs6W+18aZSI=";
              };

              cargoSha256 = "sha256-DKP9YMbVojK7w5pkX/gok4PG6WUjhqUdvTwSir05d0s=";

              nativeBuildInputs = [pkgs.pkg-config];
              buildInputs =
                [pkgs.openssl]
                ++ pkgs.lib.optional pkgs.stdenv.isDarwin
                pkgs.darwin.apple_sdk.frameworks.Security;
            };
          gcroot = config.devShells.default.inputDerivation;
        };
      };
    };
}
