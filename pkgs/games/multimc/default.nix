{ lib, mkDerivation, fetchFromGitHub, cmake, jdk8, jdk, zlib, file, makeWrapper, xorg, libpulseaudio, qtbase, libGL, autoPatchelfHook, runCommand, gdb, perl }:

let
  libpath = with xorg; lib.makeLibraryPath [ libX11 libXext libXcursor libXrandr libXxf86vm libpulseaudio libGL ];
  proprietaryBuild = mkDerivation {
    pname = "multimc-properietary";
    version = "unstable-2021-09-08";

    buildInputs = [ autoPatchelfHook ];

    src = builtins.fetchTarball {
      # TODO This will break: we need to wait for a numbered release to be cut so we have a stable download URL.
      url = "https://files.multimc.org/downloads/mmc-develop-lin64.tar.gz";
      sha256 = "0gfwxgl6dcmcvhif4a2c3g90ghxlg97qpaz00dbn2z3b838afzsv";
    };

    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
    mkdir $out
    mv * $out
    '';

    # where we're going, we don't need WrapQtApps
    dontWrapQtApps = true;

    meta.license = lib.licenses.unfree;
  };

  token = runCommand "multimc-token" {} ''
  ${gdb}/bin/gdb -batch -x ${./extract-key.gdb} ${proprietaryBuild}/bin/MultiMC | ${perl}/bin/perl -ne '/^\$2 = .*"(.*)"$/ && print "$1"' > $out
  '';

in mkDerivation rec {
  pname = "multimc";
  version = "unstable-2021-09-08";
  src = fetchFromGitHub {
    owner = "MultiMC";
    repo = "MultiMC5";
    rev = "6c9dc4c86ad934d08554b0358ac2875b9fc5f9dd";
    sha256 = "sha256-OrmIYOBarSpm6Zz/xoSRLC40bL3820oTq2XP5eJGCBk=";
    fetchSubmodules = true;
  };
  nativeBuildInputs = [ cmake file makeWrapper ];
  buildInputs = [ qtbase jdk8 zlib ];

  patches = [ ./0001-pick-latest-java-first.patch ];

  postPatch = ''
    # do a crimes
    substituteInPlace notsecrets/Secrets.cpp \
      --replace 'QString MSAClientID = "";' "QString MSAClientID = \"$(cat ${token})\";" \

    # hardcode jdk paths
    substituteInPlace launcher/java/JavaUtils.cpp \
      --replace 'scanJavaDir("/usr/lib/jvm")' 'javas.append("${jdk}/lib/openjdk/bin/java")' \
      --replace 'scanJavaDir("/usr/lib32/jvm")' 'javas.append("${jdk8}/lib/openjdk/bin/java")'
  '';

  cmakeFlags = [ "-DMultiMC_LAYOUT=lin-system" ];

  postInstall = ''
    install -Dm644 ../launcher/resources/multimc/scalable/multimc.svg $out/share/pixmaps/multimc.svg
    install -Dm755 ../launcher/package/linux/multimc.desktop $out/share/applications/multimc.desktop

    # xorg.xrandr needed for LWJGL [2.9.2, 3) https://github.com/LWJGL/lwjgl/issues/128
    wrapProgram $out/bin/multimc \
      --set GAME_LIBRARY_PATH /run/opengl-driver/lib:${libpath} \
      --prefix PATH : ${lib.makeBinPath [ xorg.xrandr ]}
  '';

  meta = with lib; {
    homepage = "https://multimc.org/";
    description = "A free, open source launcher for Minecraft";
    longDescription = ''
      Allows you to have multiple, separate instances of Minecraft (each with their own mods, texture packs, saves, etc) and helps you manage them and their associated options with a simple interface.
    '';
    platforms = platforms.linux;
    license = licenses.asl20;
    # upstream don't want us to re-distribute this application:
    # https://github.com/NixOS/nixpkgs/issues/131983
    hydraPlatforms = [];
    maintainers = with maintainers; [ cleverca22 starcraft66 ];
  };
}
