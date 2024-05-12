{ lib, stdenv, bash, autoreconfHook, pkg-config
, fetchFromGitLab
, runCommand
, completionSupport ? true, bash-completion
, selinuxSupport ? stdenv.isLinux, libselinux
, tlsSupport ? true, gnutls
# https://gitlab.com/nbdkit/nbdkit/-/commit/a3a2f9a46054ab45ce170f92344eea1e801d9892
, goPluginSupport ? stdenv.isLinux, go
, luaPluginSupport ? true, lua
, ocamlPluginSupport ? true, ocaml
, perlPluginSupport ? true, perl, libxcrypt
, pythonPluginSupport ? true, python3
# https://gitlab.com/nbdkit/nbdkit/-/commit/f935260cc50265e1f89e95ae4ca275b43d38f128
, rustPluginSupport ? stdenv.isLinux, rustc, rustPlatform, cargo, libiconv
, tclPluginSupport ? true, tcl
, additionalOptionalFeatures ? stdenv.isLinux, curl, libguestfs, libisoburn, libvirt, e2fsprogs, libnbd, libssh, libtorrent-rasterbar, boost, lzma, zlib-ng
, enableManpages ? true
, memstreamHook
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
    ++ lib.optionals ocamlPluginSupport [ ocaml ]
    ++ lib.optionals perlPluginSupport [ libxcrypt perl ]
    ++ lib.optionals pythonPluginSupport [ (python3.withPackages (p: lib.optionals additionalOptionalFeatures [ p.boto3 p.google-cloud-storage (p.toPythonModule libnbd.python) ])) ]
    ++ lib.optionals rustPluginSupport ([ rustPlatform.cargoSetupHook cargo rustc ] ++ lib.optionals stdenv.isDarwin [ libiconv ])
    ++ lib.optionals tclPluginSupport [ tcl ];

  buildInputs = []
    ++ lib.optionals enableManpages [ (perl.withPackages (p: [ p.PodSimple ])) ]
    ++ lib.optionals completionSupport [ bash-completion ]
    ++ lib.optionals selinuxSupport [ libselinux ]
    ++ lib.optionals tlsSupport [ gnutls ]
    ++ lib.optionals additionalOptionalFeatures [ curl libguestfs libisoburn libvirt e2fsprogs libnbd libssh libtorrent-rasterbar boost lzma zlib-ng ]
    ++ lib.optionals (stdenv.system == "x86_64-darwin") [ memstreamHook ];

  postUnpack = lib.optionalString goPluginSupport ''
    export GOCACHE=$TMPDIR/go-cache
    export GOPATH="$TMPDIR/go"
    export GOPROXY=off
  '' + lib.optionalString rustPluginSupport ''
    cp source/plugins/rust/Cargo.lock.msrv source/plugins/rust/Cargo.lock
  ''; 

  postPatch = lib.optionalString ocamlPluginSupport ''
    sed -i plugins/ocaml/Makefile.am -e "s|\$(OCAMLLIB)|\"$out/lib/ocaml/${ocaml.version}/site-lib/\"|g"
  '';

  # Shell scripts with shebangs are ran during build
  # so we patchShebang everything --build. Anything
  # that ends up in the outputs will be patched again
  # to --host anyway. 
  # Patching the sources themselves misses a couple of
  # .sh.in files that aren't chmodded +x
  postConfigure = ''
    patchShebangs --build ./
  '';

  configureFlags = [
    # Diagnostic info requested by upstream
    "--with-extra='Nixpkgs'"
  ]
    # Apparently there's a MacOS syscall with the same name causing false positives when configure.ac
    # tries to detect the presence of fdatasync. Hence, inclusion of the replacement function is not
    # triggered. Force it off.
    ++ lib.optionals stdenv.isDarwin [ "ac_cv_func_fdatasync=no" ]
    # Most language plugins are automatically turned on or off based on the
    # presence of relevant dependencies and headers. However, to build the
    # docs, perl has to be a nativeBuildInput. Hence, explicitly disable
    # perl plugins if perlPluginSupport is false but enableManpages is true 
    ++ lib.optionals (!perlPluginSupport && enableManpages) [ "--disable-perl" ];

  installFlags = []
    ++ lib.optionals completionSupport [ "bashcompdir=$(out)/share/bash-completion/completions" ];

  doCheck = false;

  outputs = [
    "out" "dev"
  ] ++ lib.optionals enableManpages [
    "man"
  ];
} // lib.optionalAttrs rustPluginSupport {
  inherit cargoDeps;
  cargoRoot = "plugins/rust";
})
