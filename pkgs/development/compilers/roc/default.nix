{ lib, stdenv, rustPlatform, nix-gitignore, llvmPackages, cmake, git, pkg-config, python3, zig, rust-bindgen, libffi, libiconv, libxkbcommon, libxml2, ncurses, zlib, cargo, makeWrapper, alsa-lib, vulkan-headers, vulkan-loader, vulkan-tools, vulkan-validation-layers, xorg, glibc, AppKit, CoreFoundation, CoreServices, CoreVideo, Foundation, Metal, Security }:


let
  nixGlibcPath = if stdenv.isLinux then "${glibc.out}/lib" else "";
in
rustPlatform.buildRustPackage rec {
  pname = "roc";
  version = "0.0.1";

  src = nix-gitignore.gitignoreSource [] /home/anton/gitrepos/roc4/roc;

  cargoSha256 = "sha256-cFzOcU982kANsZjx4YoLQOZSOYN3loj+5zowhWoBWM8=";

  LLVM_SYS_130_PREFIX = "${llvmPackages.llvm.dev}";

  # required for zig
  XDG_CACHE_HOME = "xdg_cache"; # prevents zig AccessDenied error github.com/ziglang/zig/issues/6810

  # skip running rust tests, problems:
  # building of example platforms requires network: Could not resolve host
  # zig AccessDenied error github.com/ziglang/zig/issues/6810
  # Once instance has previously been poisoned ??
  doCheck = false;

  nativeBuildInputs = [
    cmake
    git
    pkg-config
    python3
    llvmPackages.clang
    llvmPackages.llvm.dev
    zig
    rust-bindgen
  ];

  buildInputs = [
    libffi
    libiconv
    libxkbcommon
    libxml2
    ncurses
    zlib
    cargo
    makeWrapper # used for postInstall wrapProgram
  ]
  ++ lib.optionals stdenv.isLinux [
      alsa-lib
      vulkan-headers
      vulkan-loader
      vulkan-tools
      vulkan-validation-layers
      xorg.libX11
      xorg.libXcursor
      xorg.libXi
      xorg.libXrandr
      xorg.libxcb
  ]
  ++ lib.optionals stdenv.isDarwin [
      AppKit
      CoreFoundation
      CoreServices
      CoreVideo
      Foundation
      Metal
      Security
  ];

  # cp: to copy str.zig,list.zig...
  # wrapProgram stdenv.cc: to make ld available for compiler/build/src/link.rs
  postInstall = ''
    cp -r target/x86_64-unknown-linux-gnu/release/lib/. $out/lib
    wrapProgram $out/bin/roc --set NIX_GLIBC_PATH ${nixGlibcPath} --prefix PATH : ${lib.makeBinPath [ stdenv.cc ]}
  '';

  meta = with lib; {
    description = "A pure functional programming language for making delightful software. Compiles to machine code or to WebAssembly.";
    homepage = "https://www.roc-lang.org/";
    license = licenses.upl;
    maintainers = teams.roc.members;
  };
}
