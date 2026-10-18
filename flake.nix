{
  description = "secure-k8s-platform-lab dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

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
        terraform # unfree (BSL). For OpenTofu use: opentofu
        ansible # full package: includes ansible.posix and community.general
        kubectl
        kubernetes-helm
        cosign
        trivy # local convenience only; CI uses a digest-pinned image
        jq
        yq-go
        git
        gnumake
        openssh
        xorriso # in case the provider needs an ISO tool for cloud-init disks
        libvirt # provides virsh
      ];
    };
  };
}
