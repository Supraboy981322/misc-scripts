{
  description = "err_window";
  inputs = {
    pkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs, ... } @ inputs: 
    let 
      # system version (you may need to change this)
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = [ pkgs.gtk4 ];
      packages = with pkgs; [
        gcc
        pkg-config
      ];
    };
  };
}
