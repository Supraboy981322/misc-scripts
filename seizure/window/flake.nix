{
  description = "seizure_gui";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

      in {
        devShells.default = pkgs.mkShell (
          let
            libs = with pkgs; [
              go
              mesa
              libXi
              libXcursor
              libXrandr
              libglvnd
              libXinerama
              wayland
              pkg-config
              libxkbcommon
            ];
          in { 
          buildInputs = libs;
          packages = libs;
        });
      })
    );
}
