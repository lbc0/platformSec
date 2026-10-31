{
  description = "platformSec lab shell";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfreePredicate = pkg:
        builtins.elem (nixpkgs.lib.getName pkg) ["terraform"];
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        terraform # unfree (BSL); swap for opentofu to drop the predicate
        ansible
        kubectl
        kubernetes-helm
        cosign
        trivy
        jq
        yq-go
        git
        gnumake
        openssh
        xorriso
        libvirt # virsh
      ];
    };
  };
}
