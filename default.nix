{ stdenv, fetchurl, mpd_clientlib, curl, glib, pkgconfig }:

stdenv.mkDerivation rec {
  version = "0.1";
  name = "nixos-scripts-${version}";

  src = ./.;

  buildInputs = [ ];

  installPhase = ''
    mkdir -p $out/bin
    cp ./nix-* $out/bin/
  '';

  meta = with stdenv.lib; {
    description = "Utility scripts for working with nixos tools";
    homepage = https://github.com/matthiasbeyer/nixos-scripts;
    license = licenses.gpl2;
    maintainers = [ maintainers.matthiasbeyer ];
  };
}
