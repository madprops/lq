{
  description = "lq - list files";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};

          # 1. Define your dependency
          nap = pkgs.buildNimPackage {
            pname = "nap";
            version = "3.0.0";
            src = pkgs.fetchFromGitHub {
              owner = "madprops";
              repo = "nap";
              rev = "v3.0.0"; # Make sure this matches a real tag or commit in the nap repo

              # Nix requires a cryptographic hash for all downloads to ensure purity.
              # We use fakeHash temporarily so Nix attempts the download and gives us the real one.
              hash = pkgs.lib.fakeHash;
            };
          };

        in {
          # 2. Build the main package and provide the dependency
          default = pkgs.buildNimPackage {
            pname = "lq";
            version = "5.1.0";
            src = ./.;
            buildInputs = [ nap ];
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in {
          default = pkgs.mkShell {
            packages = [
              pkgs.nim
              pkgs.nimble
            ];
          };
        });
    };
}