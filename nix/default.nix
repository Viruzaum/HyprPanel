{
  inputs,
  pkgs,
  system,
  stdenv,
  lib,
  writeShellScriptBin,
  # bun,
  dart-sass,
  fd,
  accountsservice,
  btop,
  pipewire,
  bluez,
  bluez-tools,
  grimblast,
  gpu-screen-recorder,
  networkmanager,
  brightnessctl,
  matugen,
  swww,
  python3,
  libgtop,
  gobject-introspection,
  glib,
}: let
  ags = inputs.ags.packages.${system}.default.override {
    extraPackages = [accountsservice];
  };

  bun = pkgs.bun.overrideAttrs rec {
    passthru.sources."x86_64-linux" = pkgs.fetchurl {
      url = "https://github.com/oven-sh/bun/releases/download/bun-v1.1.37/bun-linux-x64-baseline.zip";
      hash = "sha256-AHmpv7jqLBW1C5G0sfzG+ppctluxR8xscZxlCnVyINw=";
    };
    src = passthru.sources."x86_64-linux";
  };

  pname = "hyprpanel";
  config = stdenv.mkDerivation {
    inherit pname;
    version = "latest";
    src = ../.;

    buildPhase = ''
      ${bun}/bin/bun build ./main.ts \
        --outfile main.js \
        --external "resource://*" \
        --external "gi://*"
    '';

    installPhase = ''
      mkdir $out
      cp -r assets $out
      cp -r scss $out
      cp -r widget $out
      cp -r services $out
      cp -r themes $out
      cp -r scripts $out
      cp -f main.js $out/config.js
    '';
  };
in {
  desktop = {
    inherit config;
    script = writeShellScriptBin pname ''
      export PATH=$PATH:${lib.makeBinPath [dart-sass fd btop pipewire bluez bluez-tools networkmanager matugen swww grimblast gpu-screen-recorder brightnessctl pkgs.gnome.gnome-bluetooth python3]}
      export GI_TYPELIB_PATH=${libgtop}/lib/girepository-1.0:${glib}/lib/girepository-1.0:$GI_TYPELIB_PATH
      ${ags}/bin/ags -b hyprpanel -c ${config}/config.js $@
    '';
  };
}
