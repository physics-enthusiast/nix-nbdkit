{ pkgs ? import <nixpkgs> {} }: rec {
  libnbd = pkgs.callPackage ./libnbd.nix {};
  nbdkit = pkgs.callPackage ./nbdkit.nix { inherit libnbd };
}
