{
  description = "lq - list files";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {self, nixpkgs}:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
    in {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};

          # Just fetch the library source.
          # buildNimPackage will find the .nimble file and link it automatically.
          nap = pkgs.fetchFromGitHub {
            owner = "madprops";
            repo = "nap";
            rev = "v3.0.0";
            hash = "sha256-78hzV2izyFz/asyqaoPV+VDDOZU/mxN1WMP5uuXOORE=";
          };

        in {
          default = pkgs.buildNimPackage {
            pname = "lq";
            version = "5.1.0";
            src = ./.;
            buildInputs = [
              nap
              pkgs.pcre
            ];
            nimFlags = [
              "-d:usePcre"
            ];
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
              pkgs.pcre
            ];
          };
        });
    };
}