{
  description = "yes_clone";

  inputs = {
    pkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... } @ inputs: 
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };

      deps = with pkgs; [
        fasm
        gnumake
        binutils
      ];
    in {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        pname = "yes_clone";
        version = "0.1.0";
        src = ./.;
        nativeBuildInputs = deps; 
        installPhase = ''
          mkdir -p $out/bin
          cp yes_clone $out/bin/
        '';
      };
      devShells.${system}.default = pkgs.mkShell {
        packages = deps; 
      };
    };
}
