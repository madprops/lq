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

      mkPcre = pkgs: pkgs.stdenv.mkDerivation {
        pname = "pcre";
        version = "8.45";
        src = pkgs.fetchurl {
          url = "mirror://sourceforge/pcre/pcre/8.45/pcre-8.45.tar.bz2";
          sha256 = "4dae6fdcd2bb0bb6c37b5f97c33c2be954da743985369cddac3546e3218bffb8";
        };
        configureFlags = [
          "--enable-unicode-properties"
          "--enable-utf"
        ];
      };
    in {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          pcre = mkPcre pkgs;

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
              pcre
            ];
            nimFlags = [
              "-d:usePcre"
              "-d:usePcreHeader"
              "--passL:-lpcre"
            ];
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          pcre = mkPcre pkgs;
        in {
          default = pkgs.mkShell {
            packages = [
              pkgs.nim
              pkgs.nimble
              pcre
            ];
          };
        });
    };
}