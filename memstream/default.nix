{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "memstream";
  version = "0.1";

  src = fetchurl {
    url = "https://piumarta.com/software/memstream/memstream-${version}.tar.gz";
    sha256 = "0kvdb897g7nyviaz72arbqijk2g2wa61cmi3l5yh48rzr49r3a3a";
  };

  dontConfigure = true;

  postBuild = ''
    $AR rcs libmemstream.a memstream.o
  '';

  doCheck = true;
  checkPhase = ''
    runHook preCheck

    ./test | grep "This is a test of memstream"

    runHook postCheck
  '';

  preInstall = ''
    # The hook uses this rather than the regular header because -include on clang is indiscriminate
    # and affects .s (lowercase) assembly code files as well.
    (echo '#ifndef __ASSEMBLY__'; cat memstream.h; echo '#endif') > memstream_asm_compat.h
  '';

  installPhase = ''
    runHook preInstall

    install -D libmemstream.a "$out"/lib/libmemstream.a
    install -D memstream.h "$out"/include/memstream.h
    install -D memstream_asm_compat.h "$out"/include/memstream_asm_compat.h

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://www.piumarta.com/software/memstream/";
    description = "memstream.c is an implementation of the POSIX function open_memstream() for BSD and BSD-like operating systems";
    license = licenses.mit;
    maintainers = with maintainers; [ veprbl ];
    platforms = platforms.unix;
  };
}
