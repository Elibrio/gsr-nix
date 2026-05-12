{
  description = "GPU Screen Recorder and the UI components";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        versions = {
          gpu-screen-recorder = {
            version = "5.13.6";
            hash = "sha256-8jOR2YWqYeskwRTuMeiRGa4LuvmV57S5qAYTNcNAvME=";
          };

          gpu-screen-recorder-notification = {
            version = "1.3.0";
            hash = "sha256-qCQmsNr8y+UUF/jmnyUANRcCv+GqlCWiGzGgE3y45EA=";
          };

          gpu-screen-recorder-ui = {
            version = "1.12.0";
            hash = "sha256-UUvHYWJtmsDIrSoDZpLfkHO/LUz61W94hF8ohOcu4Yg=";
          };
        };

        mkSnapshotDerivation =
          {
            pname,
            version,
            hash,
            snapshotName,
            description,
            extraNativeBuildInputs ? [ ],
            buildInputs ? [ ],
            mesonFlags ? [ ],
            postInstall ? "",
          }:
          pkgs.stdenv.mkDerivation rec {
            inherit pname version;

            src = pkgs.fetchurl {
              url = "https://dec05eba.com/snapshot/${snapshotName}.git.${version}.tar.gz";
              hash = hash;
            };

            sourceRoot = ".";

            nativeBuildInputs =
              (with pkgs; [ meson ninja pkg-config ]) ++ extraNativeBuildInputs;

            inherit buildInputs mesonFlags postInstall;

            meta = {
              inherit description;
              homepage = "https://github.com/dec05eba/gpu-screen-recorder";
              license = pkgs.lib.licenses.gpl3Only;
              maintainers = [ "dec05eba" ];
            };
          };

        gpu-screen-recorder = mkSnapshotDerivation {
          pname = "gpu-screen-recorder";
          snapshotName = "gpu-screen-recorder";
          version = versions.gpu-screen-recorder.version;
          hash = versions.gpu-screen-recorder.hash;
          description = "GPU-accelerated screen recorder supporting H.264/H.265";

          buildInputs = with pkgs; [
            ffmpeg
            libglvnd
            libxcomposite
            libxrandr
            libxfixes
            libxdamage
            libx11
            libpulseaudio
            libva
            libdrm
            libcap
            wayland-scanner
            pipewire
            dbus
            libjpeg_turbo
            vulkan-headers
            wayland
            egl-wayland
          ];

          mesonFlags = [ "-Dsystemd=true" ];
        };

        gpu-screen-recorder-notification = mkSnapshotDerivation {
          pname = "gpu-screen-recorder-notification";
          snapshotName = "gpu-screen-recorder-notification";
          version = versions.gpu-screen-recorder-notification.version;
          hash = versions.gpu-screen-recorder-notification.hash;
          description = "Notification daemon for GPU Screen Recorder";

          buildInputs = with pkgs; [
            libglvnd
            libx11
            libxrandr
            libxrender
            libxext
            wayland
            wayland-scanner
            egl-wayland
          ];
        };

        gpu-screen-recorder-ui = mkSnapshotDerivation {
          pname = "gpu-screen-recorder-ui";
          snapshotName = "gpu-screen-recorder-ui";
          version = versions.gpu-screen-recorder-ui.version;
          hash = versions.gpu-screen-recorder-ui.hash;
          description = "GTK3 graphical interface for GPU Screen Recorder";

          extraNativeBuildInputs = with pkgs; [
            gtk3
            desktop-file-utils
            makeWrapper
          ];

          buildInputs = with pkgs; [
            gpu-screen-recorder
            gpu-screen-recorder-notification
            libglvnd
            libx11
            libxrandr
            libxrender
            libxcomposite
            libxfixes
            libxext
            libxi
            libxcursor
            libpulseaudio
            libdrm
            libcap
            wayland
            wayland-scanner
            egl-wayland
          ];

          postInstall = ''
            wrapProgram $out/bin/gsr-ui \
              --prefix PATH : ${pkgs.lib.makeBinPath [
                gpu-screen-recorder
                gpu-screen-recorder-notification
              ]} \
              --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [
                pkgs.libglvnd
              ]}
          '';
        };
      in
      {
        packages = {
          inherit
            gpu-screen-recorder
            gpu-screen-recorder-notification
            gpu-screen-recorder-ui;
          default = gpu-screen-recorder-ui;
        };
      }
    );
}
