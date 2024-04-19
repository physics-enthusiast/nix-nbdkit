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

  # Shell scripts with shebangs are ran during build
  # so we patchShebang everything. Anything that ends 
  # up in the outputs will be patched again anyway. 
  postPatch = ''
    patchShebangs --build .
  '';

  outputs = [ "out" "dev" ];
}
