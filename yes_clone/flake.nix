{
  description = "yes_clone";

  inputs = {
    # nixpkgs unstable for latest versions
    pkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, zig_overlay, ... } @ inputs: 
    let
      # system version (you may need to change this)
      system = "x86_64-linux";
      pkgs = import nixpkgs { };
    in {
      # Nix shell
      devShells.${system}.default = pkgs.mkShell {
        # install packages
        packages = with pkgs; [
          fasm
          gnumake
          binutils
        ]; 
      };
    };
}
