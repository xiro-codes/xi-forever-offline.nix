{
  pkgs,
  lib ? pkgs.lib,
  version ? "0.3.9",
  kitSrc ? null,
  sha256 ? "sha256-t30cHInm8yMshU1l+132B781f9tI21V6032k8N6B76E=",
  kitDir ? "$HOME/.xi/",
  ...
}:
let
  pkgsi686 = pkgs.pkgsi686Linux;

  kitSource =
    if kitSrc != null then
      kitSrc
    else
      pkgs.fetchzip {
        url = "https://github.com/Hurami89/xi-forever-offline/releases/download/v${version}/xi-forever-offline-v${version}-linux-x64.tar.gz";
        inherit sha256;
      };

  rev = if kitSrc != null && kitSrc ? rev then kitSrc.rev else "unknown";

  kitFiles = pkgs.runCommand "xi-forever-offline-kit-${version}" { } ''
    mkdir -p "$out/share/xi-forever-offline"
    cp -a "${kitSource}/." "$out/share/xi-forever-offline/"
    chmod -R u+w "$out/share/xi-forever-offline"

    if [ ! -d "$out/share/xi-forever-offline/lib/mariadb-compat" ]; then
      mkdir -p "$out/share/xi-forever-offline/lib/mariadb-compat"
      ln -sf "${pkgs.libaio}/lib/libaio.so.1" "$out/share/xi-forever-offline/lib/mariadb-compat/libaio.so.1"
      ln -sf "${pkgs.libxcrypt-legacy}/lib/libcrypt.so.1" "$out/share/xi-forever-offline/lib/mariadb-compat/libcrypt.so.1"
      ln -sf "${pkgs.ncurses5}/lib/libncurses.so.5" "$out/share/xi-forever-offline/lib/mariadb-compat/libncurses.so.5"
      ln -sf "${pkgs.ncurses5}/lib/libtinfo.so.5" "$out/share/xi-forever-offline/lib/mariadb-compat/libtinfo.so.5"
      ln -sf "${pkgs.ncurses}/lib/libncurses.so.6" "$out/share/xi-forever-offline/lib/mariadb-compat/libncurses.so.6"
      ln -sf "${pkgs.ncurses}/lib/libncursesw.so.6" "$out/share/xi-forever-offline/lib/mariadb-compat/libncursesw.so.6"
      ln -sf "${pkgs.ncurses}/lib/libtinfo.so.6" "$out/share/xi-forever-offline/lib/mariadb-compat/libtinfo.so.6"
    fi

    if [ ! -f "$out/share/xi-forever-offline/VERSION.txt" ]; then
      printf "XI: Forever Offline v%s\ncommit %s\n" "${version}" "${rev}" > "$out/share/xi-forever-offline/VERSION.txt"
    fi

    if [ -f "$out/share/xi-forever-offline/XI-Forever-Offline" ]; then
      chmod +x "$out/share/xi-forever-offline/XI-Forever-Offline"
    fi
  '';

  xorgLocale = pkgs.runCommand "xorg-locale" { } ''
    mkdir -p $out/share/X11
    ln -s ${pkgs.libx11}/share/X11/locale $out/share/X11/locale
  '';

  # Backported python-xlib derivation for stable nixpkgs (nixos-26.05)
  mkPythonXlib =
    ps:
    ps.buildPythonPackage rec {
      pname = "python-xlib";
      version = "0.33";
      pyproject = true;

      src = pkgs.fetchFromGitHub {
        owner = "python-xlib";
        repo = "python-xlib";
        tag = version;
        hash = "sha256-u06OWlMIOUzHOVS4hvm72jGgTSXWUqMvEQd8bTpFog0=";
      };

      build-system = [
        (ps.setuptools-scm.override {
          setuptools = ps.setuptools_80 or ps.setuptools;
        })
      ];

      buildInputs = [ pkgs.libx11 ];

      dependencies = [ ps.six ];

      doCheck = false;

      meta = {
        changelog = "https://github.com/python-xlib/python-xlib/releases/tag/${version}";
        description = "Fully functional X client library for Python programs";
        homepage = "https://github.com/python-xlib/python-xlib";
        license = lib.licenses.lgpl21Plus;
      };
    };

  pythonEnv = pkgs.python3.withPackages (
    ps:
    let
      python-xlib = ps.python-xlib or (mkPythonXlib ps);
    in
    with ps;
    [
      tkinter
      pillow
      certifi
      mariadb
      bcrypt
      urllib3
      truststore
      python-xlib
      six
      cbor2
      pyzstd
      xxhash
    ]
  );

  fhs = pkgs.buildFHSEnv {
    name = "xi-forever-offline-fhs";
    multiArch = true;
    includeClosures = true;
    privateTmp = false;

    targetPkgs =
      pkgs: with pkgs; [
        bash
        coreutils
        file
        findutils
        gawk
        gnugrep
        gnused
        gnutar
        gzip
        xz
        unzip
        zip
        which
        procps
        lsb-release
        pciutils
        usbutils
        xdg-utils
        zenity
        nettools
        iproute2
        curl
        rsync
        glibc_multi.bin
        fontconfig
        noto-fonts
        xorgLocale
        pythonEnv
      ];

    multiPkgs =
      pkgs: with pkgs; [
        glibc
        stdenv.cc.cc.lib
        libxcrypt
        libxcrypt-legacy
        systemd
        libaio
        ncurses5
        ncurses
        zlib
        openssl
        libkrb5
        libcap
        networkmanager

        libGL
        libdrm
        libgbm
        udev
        libudev0-shim
        libva
        libvdpau
        vulkan-loader

        alsa-lib
        libpulseaudio
        libusb1
        SDL2
        libpcap
        pcsclite

        glib
        gtk3
        pango
        cairo
        atk
        gdk-pixbuf
        freetype
        fontconfig

        libx11
        libxcursor
        libxrandr
        libxi
        libxtst
        libxcb
        libxkbcommon
        libxxf86vm
        libxext
        libxfixes
        libxrender
        libxcomposite
        libxdamage
        libxinerama
        libxscrnsaver
        wayland
      ];

    extraBuildCommands = ''
      cp -f $out/usr/{bin,sbin}/ldconfig
    '';

    extraBwrapArgs = [
      "--ro-bind-try /etc/zoneinfo /usr/share/zoneinfo"
    ];

    profile = ''
      export LIBGL_DRIVERS_PATH=${pkgs.mesa}/lib/dri:${pkgsi686.mesa}/lib/dri
      export LIBVA_DRIVERS_PATH=${pkgs.mesa}/lib/dri:${pkgsi686.mesa}/lib/dri
      export __EGL_VENDOR_LIBRARY_DIRS=${pkgs.mesa}/share/glvnd/egl_vendor.d:${pkgsi686.mesa}/share/glvnd/egl_vendor.d
      export VDPAU_DRIVER_PATH=/run/opengl-driver/lib/vdpau:/run/opengl-driver-32/lib/vdpau
      export PATH="/usr/sbin:$PATH"
    '';

    runScript = pkgs.writeShellScript "xi-forever-offline-run" ''
      set -e

      KIT_SRC="${kitFiles}/share/xi-forever-offline"
      DEFAULT_KIT_DIR="${kitDir}"

      # If running inside a kit directory already (and XIFO_HOME isn't explicitly set), use PWD;
      # otherwise use XIFO_HOME or ~/.xicore/XI Forever Offline and seed/update kit files if needed.
      if [ -n "''${XIFO_HOME:-}" ]; then
        KIT_DIR="$XIFO_HOME"
      elif [ -f "./launcher_gui.pyw" ] && [ -f "./launcher_core.py" ]; then
        KIT_DIR="$PWD"
      else
        KIT_DIR="$DEFAULT_KIT_DIR"
      fi

      if [ ! -f "$KIT_DIR/launcher_gui.pyw" ]; then
        mkdir -p "$KIT_DIR"
        cp -a "$KIT_SRC/." "$KIT_DIR/"
        chmod -R u+w "$KIT_DIR"
        if [ -f "$KIT_DIR/XI-Forever-Offline" ]; then
          chmod +x "$KIT_DIR/XI-Forever-Offline"
        fi
      fi

      if [ $# -gt 0 ]; then
        case "$1" in
          -*)
            cd "$KIT_DIR"
            if [ -x ./XI-Forever-Offline ]; then
              exec ./XI-Forever-Offline "$@"
            else
              exec python3 ./launcher_gui.pyw "$@"
            fi
            ;;
          *)
            exec "$@"
            ;;
        esac
      fi

      cd "$KIT_DIR"
      if [ -x ./XI-Forever-Offline ]; then
        exec ./XI-Forever-Offline
      else
        exec python3 ./launcher_gui.pyw
      fi
    '';
  };

  desktopItem = pkgs.makeDesktopItem {
    name = "xi-forever-offline";
    desktopName = "XI: Forever Offline";
    comment = "Offline FINAL FANTASY XI with squad mates and a living world";
    exec = "xi-forever-offline";
    icon = "xi-forever-offline";
    terminal = false;
    categories = [
      "Game"
      "RolePlaying"
    ];
    startupWMClass = "XI Forever Offline";
  };
in
pkgs.symlinkJoin {
  name = "xi-forever-offline-${version}";
  pname = "xi-forever-offline";
  inherit version;

  paths = [
    desktopItem
  ];

  postBuild = ''
    mkdir -p "$out/bin" "$out/share/icons/hicolor/256x256/apps" "$out/share/pixmaps"
    ln -s "${fhs}/bin/xi-forever-offline-fhs" "$out/bin/xi-forever-offline"
    ln -s "${fhs}/bin/xi-forever-offline-fhs" "$out/bin/XI-Forever-Offline"
    if [ -f "${kitFiles}/share/xi-forever-offline/assets/ui/icon.png" ]; then
      ln -s "${kitFiles}/share/xi-forever-offline/assets/ui/icon.png" "$out/share/icons/hicolor/256x256/apps/xi-forever-offline.png"
      ln -s "${kitFiles}/share/xi-forever-offline/assets/ui/icon.png" "$out/share/pixmaps/xi-forever-offline.png"
    fi
  '';

  passthru = {
    inherit fhs kitFiles;
    env = fhs.env;
  };

  meta = with lib; {
    description = "Offline FINAL FANTASY XI launcher, server, and FHS runtime for NixOS";
    homepage = "https://github.com/Hurami89/xi-forever-offline";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "xi-forever-offline";
  };
}
