{ lib, stdenv, bash, autoreconfHook, pkg-config, which
, fetchFromGitLab
, runCommand
, completionSupport ? true, bash-completion
, selinuxSupport ? stdenv.isLinux, libselinux
, tlsSupport ? true, gnutls
, goPluginSupport ? true, go
, luaPluginSupport ? true, lua
, ocamlPluginSupport ? true, ocamlPackages
, perlPluginSupport ? true, perl, libxcrypt
, pythonPluginSupport ? true, python3
# https://gitlab.com/nbdkit/nbdkit/-/commit/f935260cc50265e1f89e95ae4ca275b43d38f128
, rustPluginSupport ? true, rustc, rustPlatform, cargo, libiconv
, tclPluginSupport ? true, tcl
, additionalOptionalFeatures ? stdenv.isLinux, curl, libguestfs, libisoburn, libvirt, e2fsprogs, libnbd, libssh, libtorrent-rasterbar, boost, lzma, zlib-ng, qemu
, enableManpages ? true
, memorymappingHook, memstreamHook
}: 
let
  version = "1.39.4";
  src = fetchFromGitLab {
    owner = "nbdkit";
    repo = "nbdkit";
    rev = "v${version}";
    hash = "sha256-jJWknok8Mnd0+MDXzEoN/hNpgxDKeXMaGzZclQdDpuQ=";
  };
  cargoDeps = rustPlatform.fetchCargoTarball { 
    src = runCommand "${src.name}-rust-deps" {} ''
      mkdir -p $out
      cp -r ${src}/plugins/rust/. $out/
      cp $out/Cargo.lock.msrv $out/Cargo.lock
    '';
    hash = "sha256-3hnA0Ot6Q9lTnH+O5fmh2v2q7YMhmU5u75BlLwmF2Kk="; 
  };
in
stdenv.mkDerivation ({
  pname = "nbdkit";
  inherit version src;

  enableParallelBuilding = true;

  nativeBuildInputs = [ 
    autoreconfHook pkg-config 
  ]
    ++ lib.optionals goPluginSupport [ go ]
    ++ lib.optionals luaPluginSupport [ lua ]
    ++ lib.optionals ocamlPluginSupport [ ocamlPackages.ocaml ocamlPackages.findlib ocamlPackages.ocamlbuild ]
    ++ lib.optionals perlPluginSupport [ libxcrypt perl ]
    ++ lib.optionals pythonPluginSupport [ (python3.withPackages (p: lib.optionals additionalOptionalFeatures [ p.boto3 p.google-cloud-storage (p.toPythonModule libnbd.python) ])) ]
    ++ lib.optionals rustPluginSupport ([ rustPlatform.cargoSetupHook cargo rustc ] ++ lib.optionals stdenv.isDarwin [ libiconv ])
    ++ lib.optionals tclPluginSupport [ tcl ];

  buildInputs = [
    which
  ]
    ++ lib.optionals enableManpages [ (perl.withPackages (p: [ p.PodSimple ])) ]
    ++ lib.optionals completionSupport [ bash-completion ]
    ++ lib.optionals selinuxSupport [ libselinux ]
    ++ lib.optionals tlsSupport [ gnutls ]
    ++ lib.optionals additionalOptionalFeatures [ curl libguestfs libisoburn libvirt e2fsprogs libnbd libssh libtorrent-rasterbar boost lzma zlib-ng ]
    ++ lib.optionals (stdenv.system == "x86_64-darwin") [ memstreamHook memorymappingHook ];

  checkInputs = []
    ++ lib.optionals additionalOptionalFeatures [ qemu ];

  postUnpack = lib.optionalString goPluginSupport ''
    export GOCACHE=$TMPDIR/go-cache
    export GOPATH="$TMPDIR/go"
    export GOPROXY=off
    export CGO_ENABLED=1
  '' + lib.optionalString rustPluginSupport ''
    cp source/plugins/rust/Cargo.lock.msrv source/plugins/rust/Cargo.lock
  '';

  postPatch = lib.optionalString ocamlPluginSupport ''
    sed -i plugins/ocaml/Makefile.am -e "
      s|\$(OCAMLLIB)|\"$out/lib/ocaml/${ocamlPackages.ocaml.version}/site-lib/\"|g
      83ilibnbdkitocaml_la_LIBADD = ${ocamlPackages.ocaml}/lib/ocaml/libasmrun_pic.a
    "
    sed -i plugins/rust/Makefile.am -e '
      s|cargo build|cargo rustc --crate-type=rlib|
      83d
    '
  '';

  # Shell scripts with shebangs are ran during build
  # so we patchShebang everything --build. Anything
  # that ends up in the outputs will be patched again
  # to --host anyway. 
  # Patching the sources themselves misses a couple of
  # .sh.in files that aren't chmodded +x
  postConfigure = ''
    patchShebangs --build ./
    # Backward compatability tests done by upstream. We skip them both because we don't need them, and
    # because they contain precompiled binaries.
    # See https://gitlab.com/nbdkit/nbdkit/-/tree/master/tests/old-plugins
    rm -rf tests/old-plugins/
    for test_file in $(find ./tests -type f -print); do
      # First replacement patches shebangs in function body. Second deals with tests that implicitly require
      # a libguestfs appliance but are not disabled by --disable-libguestfs-tests, and just causes them to
      # directly exit successfully. See the comments on --disable-libguestfs-tests for more details
      substituteInPlace "$test_file" \
        --replace-quiet '/usr/bin/env bash' '${bash}/bin/bash' \
        --replace-quiet 'requires guestfish --version' 'exit 0'
    done
  '';

  # Use a dummy cert like the gnutls derivation does (the very same one, in fact) to avoid depending on
  # cacert (which would cause a rebuild of this package whenever the certs are updated), since they
  # are only needed for tests
  preCheck = "export NIX_SSL_CERT_FILE=${./dummy.crt}";

  configureFlags = [
    # Diagnostic info requested by upstream
    "--with-extra='Nixpkgs'"
    # Same problem as #37540, would rather not bundle a downloaded binary so just disable the tests instead
    "--disable-libguestfs-tests"
  ]
    # Apparently there's a MacOS syscall with the same name causing false positives when configure.ac
    # tries to detect the presence of fdatasync. Hence, inclusion of the replacement function is not
    # triggered. Force it off
    ++ lib.optionals stdenv.isDarwin [ "ac_cv_func_fdatasync=no" ]
    # open_memstream is injected via CFLAGS and LD in pkgs/development/libraries/memstream/setup-hook.sh
    # This is invisible to configure which detects it as missing and attempts to find a substitution
    # during AC_REPLACE_FUNCS. One is in fact defined, but was intended for windows, so it throws.
    # We override the check manually since we know it will be available during actual compilation.
    # This is specific to x86_64-darwin. See nixpkgs/pkgs/os-specific/darwin/cctools/port.nix for more info
    ++ lib.optionals (stdenv.system == "x86_64-darwin") [ "ac_cv_func_open_memstream=yes" ]
    # Most language plugins are automatically turned on or off based on the
    # presence of relevant dependencies and headers. However, to build the
    # docs, perl has to be a nativeBuildInput. Hence, explicitly disable
    # perl plugins if perlPluginSupport is false but enableManpages is true 
    ++ lib.optionals (!perlPluginSupport && enableManpages) [ "--disable-perl" ];

  installFlags = []
    ++ lib.optionals completionSupport [ "bashcompdir=$(out)/share/bash-completion/completions" ];

  doCheck = true;

  outputs = [
    "out" "dev"
  ] ++ lib.optionals enableManpages [
    "man"
  ];
} // lib.optionalAttrs rustPluginSupport {
  inherit cargoDeps;
  cargoRoot = "plugins/rust";
})
