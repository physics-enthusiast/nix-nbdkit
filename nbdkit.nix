{ lib, stdenv, autoreconfHook, pkg-config
, fetchFromGitLab
, gnutls
}:

stdenv.mkDerivation rec {
  pname = "nbdkit";
  version = "1.36";
  src = fetchFromGitLab {
    owner = "nbdkit";
    repo = "nbdkit";
    rev = "stable-${version}";
    hash = "sha256-7NTxC3HmN+3tzBDtxIOuHpfF184S8RjYbbKouW5Z//k=";
  };

  enableParallelBuilding = true;

  nativeBuildInputs = [ autoreconfHook pkg-config ];
  buildInputs = [ gnutls ];

  postConfigurePhase = ''
    patchShebangs --build /build
  '';

  outputs = [ "out" "dev" ];
}
