{ pkgs ? import <nixpkgs> {} }: rec {
  libnbd = pkgs.darwin.apple_sdk_11_0.callPackage ./libnbd.nix {};
  nbdkit = pkgs.darwin.apple_sdk_11_0.callPackage ./nbdkit.nix { inherit libnbd; };
}
