{ pkgs ? import <nixpkgs> {} }: rec {
  memorymapping = pkgs.callPackage ./memorymapping { };
  memorymappingHook = pkgs.makeSetupHook {
    name = "memorymapping-hook";
    propagatedBuildInputs = [ memorymapping ];
  } ./memorymapping/setup-hook.sh;
  memstream = pkgs.callPackage ./memstream { };
  memstreamHook = pkgs.makeSetupHook {
    name = "memstream-hook";
    propagatedBuildInputs = [ memstream ];
  } ./memstream/setup-hook.sh;
  libnbd = pkgs.callPackage ./libnbd.nix {};
  nbdkit = pkgs.callPackage ./nbdkit.nix { inherit memorymappingHook memstreamHook libnbd; };
}
