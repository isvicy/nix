{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libxkbcommon,
  libGL,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
  xorg,
}:
stdenv.mkDerivation rec {
  pname = "confirmo";
  version = "1.0.64";

  src = fetchurl {
    url = "https://github.com/yetone/confirmo-releases/releases/download/v${version}/confirmo_${version}_amd64.deb";
    hash = "sha256-HBK++Ev+Z6A/ryNjV2M9fxrc67fymVp5yjQ9MtR12mo=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libxkbcommon
    libGL
    mesa
    nspr
    nss
    pango
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libxcb
    xorg.libxshmfence
  ];

  runtimeDependencies = [
    systemd
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt
    cp -r opt/Confirmo $out/opt/

    mkdir -p $out/bin
    makeWrapper $out/opt/Confirmo/confirmo $out/bin/confirmo \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
      --add-flags "--enable-features=UseOzonePlatform,WaylandWindowDecorations" \
      --add-flags "--ozone-platform=wayland"

    mkdir -p $out/share/applications
    cat > $out/share/applications/confirmo.desktop << EOF
    [Desktop Entry]
    Name=Confirmo
    Exec=$out/bin/confirmo %U
    Terminal=false
    Type=Application
    Icon=confirmo
    StartupWMClass=Confirmo
    Comment=Vibe Coding Desktop Pet - Your AI Coding Companion
    Categories=Development;
    EOF

    mkdir -p $out/share/icons/hicolor
    cp -r usr/share/icons/hicolor/* $out/share/icons/hicolor/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Vibe Coding Desktop Pet - Your AI Coding Companion";
    homepage = "https://github.com/yetone/confirmo-releases";
    license = licenses.unfree;
    maintainers = [];
    platforms = ["x86_64-linux"];
    mainProgram = "confirmo";
  };
}
