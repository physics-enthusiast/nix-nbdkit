useMemorymapping () {
  export NIX_CFLAGS_COMPILE="${NIX_CFLAGS_COMPILE-}${NIX_CFLAGS_COMPILE:+ }-include fmemopen_asm_compat.h";
  export NIX_LDFLAGS="${NIX_LDFLAGS-}${NIX_LDFLAGS:+ }-lmemorymapping";
}

postHooks+=(useMemorymapping)
