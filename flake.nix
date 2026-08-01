{
  description = "Dank Material Shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      goModVersion =
        let
          content = builtins.readFile ./core/go.mod;
          lines = builtins.filter builtins.isString (builtins.split "\n" content);
          goLines = builtins.filter (l: builtins.match "go [0-9]+\\..*" l != null) lines;
          matched =
            if goLines != [ ] then builtins.match "go ([0-9]+)\\.([0-9]+).*" (builtins.head goLines) else null;
        in
        if matched != null then
          {
            major = builtins.elemAt matched 0;
            minor = builtins.elemAt matched 1;
          }
        else
          {
            major = "1";
            minor = "25";
          };
      goForPkgs = pkgs: pkgs.${"go_${goModVersion.major}_${goModVersion.minor}"};
      forEachSystem =
        fn:
        nixpkgs.lib.genAttrs [ "aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux" ] (
          system: fn system nixpkgs.legacyPackages.${system}
        );
      forEachLinuxSystem =
        fn:
        nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ] (
          system: fn system nixpkgs.legacyPackages.${system}
        );

      mkModuleWithDmsPkgs =
        modulePath:
        args@{ pkgs, ... }:
        {
          imports = [
            (import modulePath (args // { dmsPkgs = buildDmsPkgs pkgs; }))
          ];
        };

      mkQmlImportPath =
        pkgs: qmlPkgs:
        pkgs.lib.concatStringsSep ":" (map (o: "${o}/${pkgs.qt6.qtbase.qtQmlPrefix}") qmlPkgs);

      mkQtPluginPath =
        pkgs: qtPkgs:
        pkgs.lib.concatStringsSep ":" (map (o: "${o}/${pkgs.qt6.qtbase.qtPluginPrefix}") qtPkgs);

      qmlPkgs =
        pkgs: with pkgs.kdePackages; [
          kirigami.unwrapped
          sonnet
          qtmultimedia
          qtimageformats
          kimageformats
        ];

      mkQuickshellRunner =
        pkgs:
        let
          qtPackages = qmlPkgs pkgs;
        in
        pkgs.runCommand "skwig-dms" { } ''
          mkdir -p $out/bin

          cat > $out/bin/skwig-dms <<'EOF'
          #!${pkgs.runtimeShell}
          export DMS_DISABLE_HOT_RELOAD=1
          export DMS_DISABLE_MATUGEN=1
          export NIXPKGS_QT6_QML_IMPORT_PATH="${mkQmlImportPath pkgs qtPackages}''${NIXPKGS_QT6_QML_IMPORT_PATH:+:$NIXPKGS_QT6_QML_IMPORT_PATH}"
          export QT_PLUGIN_PATH="${mkQtPluginPath pkgs qtPackages}''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
          exec ${pkgs.quickshell}/bin/qs -p ${./quickshell} "$@"
          EOF

          cat > $out/bin/skwig-dms-picker <<'EOF'
          #!${pkgs.runtimeShell}
          if [ "$#" -gt 0 ]; then
            printf '%s\n' 'usage: skwig-dms-picker' >&2
            exit 2
          fi

          input="$(${pkgs.coreutils}/bin/cat)"
          request_id="picker-$$-$(${pkgs.coreutils}/bin/date +%s%N)"

          qs_pid="$(${pkgs.procps}/bin/pgrep -o -f 'quickshell.*-p ${./quickshell}' || true)"
          if [ -z "$qs_pid" ]; then
            printf '%s\n' 'skwig-dms-picker: skwig-dms is not running' >&2
            exit 2
          fi

          coproc QS_PICKER_LISTENER { ${pkgs.quickshell}/bin/qs ipc --pid "$qs_pid" listen skwig-dms pickerFinished; }
          cleanup() {
            ${pkgs.coreutils}/bin/kill "$QS_PICKER_LISTENER_PID" 2>/dev/null || true
          }
          trap cleanup EXIT

          if ! ${pkgs.quickshell}/bin/qs ipc --pid "$qs_pid" call skwig-dms picker "$input" "$request_id" >/dev/null; then
            printf '%s\n' 'skwig-dms-picker: failed to open picker' >&2
            exit 2
          fi

          selected_prefix="$request_id"$'\tselected\t'
          cancelled_prefix="$request_id"$'\tcancelled\t'
          while IFS= read -r line <&"''${QS_PICKER_LISTENER[0]}"; do
            case "$line" in
              "$selected_prefix"*)
                printf '%s\n' "''${line#"$selected_prefix"}"
                exit 0
                ;;
              "$cancelled_prefix"*)
                exit 1
                ;;
            esac
          done

          exit 1
          EOF

          cat > $out/bin/skwig-dms-app-picker <<'EOF'
          #!${pkgs.runtimeShell}
          if [ "$#" -gt 0 ]; then
            printf '%s\n' 'usage: skwig-dms-app-picker' >&2
            exit 2
          fi

          request_id="app-picker-$$-$(${pkgs.coreutils}/bin/date +%s%N)"

          qs_pid="$(${pkgs.procps}/bin/pgrep -o -f 'quickshell.*-p ${./quickshell}' || true)"
          if [ -z "$qs_pid" ]; then
            printf '%s\n' 'skwig-dms-app-picker: skwig-dms is not running' >&2
            exit 2
          fi

          coproc QS_APP_PICKER_LISTENER { ${pkgs.quickshell}/bin/qs ipc --pid "$qs_pid" listen skwig-dms appPickerFinished; }
          cleanup() {
            ${pkgs.coreutils}/bin/kill "$QS_APP_PICKER_LISTENER_PID" 2>/dev/null || true
          }
          trap cleanup EXIT

          if ! ${pkgs.quickshell}/bin/qs ipc --pid "$qs_pid" call skwig-dms appPicker "$request_id" >/dev/null; then
            printf '%s\n' 'skwig-dms-app-picker: failed to open app picker' >&2
            exit 2
          fi

          selected_prefix="$request_id"$'\tselected\t'
          cancelled_prefix="$request_id"$'\tcancelled\t'
          while IFS= read -r line <&"''${QS_APP_PICKER_LISTENER[0]}"; do
            case "$line" in
              "$selected_prefix"*)
                executable="''${line#"$selected_prefix"}"
                if [ -z "$executable" ]; then
                  exit 1
                fi
                case "$executable" in
                  /*)
                    printf '%s\n' "$executable"
                    ;;
                  *)
                    resolved="$(command -v -- "$executable" || true)"
                    if [ -z "$resolved" ]; then
                      printf 'skwig-dms-app-picker: executable not found: %s\n' "$executable" >&2
                      exit 1
                    fi
                    printf '%s\n' "$resolved"
                    ;;
                esac
                exit 0
                ;;
              "$cancelled_prefix"*)
                exit 1
                ;;
            esac
          done

          exit 1
          EOF

          cat > $out/bin/skwig-dms-launcher <<'EOF'
          #!${pkgs.runtimeShell}
          bindir="$(${pkgs.coreutils}/bin/dirname "$0")"
          app="$($bindir/skwig-dms-app-picker)" || exit $?
          prefix="''${SKWIG_DMS_LAUNCH_PREFIX:-uwsm app --}"
          if [ -n "$prefix" ]; then
            exec ${pkgs.runtimeShell} -lc 'exec "$@"' _ $prefix "$app"
          fi
          exec "$app"
          EOF

          chmod +x $out/bin/skwig-dms $out/bin/skwig-dms-picker $out/bin/skwig-dms-app-picker $out/bin/skwig-dms-launcher
        '';

      # Allows downstream modules to provide their own 'pkgs' (with overlays)
      # instead of being forced to use the flake's locked nixpkgs.
      mkDmsShell =
        pkgs:
        let
          mkDate =
            longDate:
            pkgs.lib.concatStringsSep "-" [
              (builtins.substring 0 4 longDate)
              (builtins.substring 4 2 longDate)
              (builtins.substring 6 2 longDate)
            ];
          version =
            let
              rawVersion = pkgs.lib.removePrefix "v" (pkgs.lib.trim (builtins.readFile ./quickshell/VERSION));
              cleanVersion = builtins.replaceStrings [ " " ] [ "" ] rawVersion;
              dateSuffix = "+date=" + mkDate (self.lastModifiedDate or "19700101");
              revSuffix = "_" + (self.shortRev or "dirty");
            in
            "${cleanVersion}${dateSuffix}${revSuffix}";
        in
        pkgs.lib.makeOverridable (
          {
            extraQtPackages ? [ ],
          }:
          (pkgs.buildGoModule.override { go = goForPkgs pkgs; }) (
            let
              rootSrc = ./.;
              qtPackages = (qmlPkgs pkgs) ++ extraQtPackages;
            in
            {
              inherit version;
              pname = "dms-shell";
              src = ./core;
              vendorHash = "sha256-nvxFHQhOfBGl3h51fgYDb39K0NCj+H8mAEyKr1qOwJQ=";

              subPackages = [ "cmd/dms" ];

              ldflags = [
                "-s"
                "-w"
                "-X 'main.Version=${version}'"
              ];

              nativeBuildInputs = with pkgs; [
                installShellFiles
                makeWrapper
              ];

              postInstall = ''
                mkdir -p $out/share/quickshell/dms
                cp -r ${rootSrc}/quickshell/. $out/share/quickshell/dms/

                chmod u+w $out/share/quickshell/dms/VERSION
                echo "${version}" > $out/share/quickshell/dms/VERSION

                # Install desktop file and icon
                install -D ${rootSrc}/assets/dms-open.desktop \
                  $out/share/applications/dms-open.desktop
                install -D ${rootSrc}/assets/com.danklinux.dms.desktop \
                  $out/share/applications/com.danklinux.dms.desktop
                install -D ${rootSrc}/assets/com.danklinux.dms.notepad.desktop \
                  $out/share/applications/com.danklinux.dms.notepad.desktop
                install -D ${rootSrc}/core/assets/danklogo.svg \
                  $out/share/hicolor/scalable/apps/danklogo.svg

                wrapProgram $out/bin/dms \
                  --add-flags "-c $out/share/quickshell/dms" \
                  --prefix "NIXPKGS_QT6_QML_IMPORT_PATH" ":" "${mkQmlImportPath pkgs qtPackages}" \
                  --prefix "QT_PLUGIN_PATH" ":" "${mkQtPluginPath pkgs qtPackages}"

                install -Dm644 ${rootSrc}/assets/systemd/dms.service \
                  $out/lib/systemd/user/dms.service

                substituteInPlace $out/lib/systemd/user/dms.service \
                  --replace-fail /usr/bin/dms $out/bin/dms \
                  --replace-fail /usr/bin/pkill ${pkgs.procps}/bin/pkill

                substituteInPlace $out/share/quickshell/dms/Modules/Greetd/assets/dms-greeter \
                  --replace-fail /bin/bash ${pkgs.bashInteractive}/bin/bash

                substituteInPlace $out/share/quickshell/dms/assets/pam/fprint \
                  --replace-fail pam_fprintd.so ${pkgs.fprintd}/lib/security/pam_fprintd.so \
                  --replace-fail pam_deny.so ${pkgs.pam}/lib/security/pam_deny.so \
                  --replace-fail pam_permit.so ${pkgs.pam}/lib/security/pam_permit.so

                substituteInPlace $out/share/quickshell/dms/assets/pam/u2f \
                  --replace-fail pam_u2f.so ${pkgs.pam_u2f}/lib/security/pam_u2f.so \
                  --replace-fail pam_deny.so ${pkgs.pam}/lib/security/pam_deny.so \
                  --replace-fail pam_permit.so ${pkgs.pam}/lib/security/pam_permit.so

                substituteInPlace $out/share/quickshell/dms/assets/pam/other \
                  --replace-fail pam_deny.so ${pkgs.pam}/lib/security/pam_deny.so

                installShellCompletion --cmd dms \
                  --bash <($out/bin/dms completion bash) \
                  --fish <($out/bin/dms completion fish) \
                  --zsh <($out/bin/dms completion zsh)
              '';

              meta = {
                description = "Desktop shell for wayland compositors built with Quickshell & GO";
                homepage = "https://danklinux.com";
                changelog = "https://github.com/AvengeMedia/DankMaterialShell/releases/tag/v${version}";
                license = pkgs.lib.licenses.mit;
                mainProgram = "dms";
                platforms = pkgs.lib.platforms.linux;
              };
            }
          )
        ) { };

      buildDmsPkgs = pkgs: {
        dms-shell = mkDmsShell pkgs;
      };
    in
    {
      packages = forEachSystem (
        system: pkgs: {
          dms-shell = mkDmsShell pkgs;
          skwig-dms = mkQuickshellRunner pkgs;
          default = self.packages.${system}.skwig-dms;
          quickshell = builtins.warn "dank-material-shell: the package Quickshell is not included in the DMS flake anymore. We recommend you to use the one from nixos-unstable branch of Nixpkgs or the upstream flake." pkgs.quickshell;
        }
      );

      apps = forEachSystem (
        system: pkgs: {
          default = {
            type = "app";
            program = "${self.packages.${system}.skwig-dms}/bin/skwig-dms";
          };
          skwig-dms = self.apps.${system}.default;
        }
      );

      lib = { inherit mkDmsShell buildDmsPkgs; };

      homeModules.dank-material-shell = mkModuleWithDmsPkgs ./distro/nix/home.nix;

      homeModules.default = self.homeModules.dank-material-shell;

      homeModules.niri = import ./distro/nix/niri.nix;

      homeModules.dankMaterialShell.default = builtins.warn "dank-material-shell: flake output `homeModules.dankMaterialShell.default` has been renamed to `homeModules.dank-material-shell`" self.homeModules.dank-material-shell;

      homeModules.dankMaterialShell.niri = builtins.warn "dank-material-shell: flake output `homeModules.dankMaterialShell.niri` has been renamed to `homeModules.niri`" self.homeModules.niri;

      nixosModules.dank-material-shell = mkModuleWithDmsPkgs ./distro/nix/nixos.nix;

      nixosModules.default = self.nixosModules.dank-material-shell;

      nixosModules.greeter = mkModuleWithDmsPkgs ./distro/nix/greeter.nix;

      nixosModules.dankMaterialShell = builtins.warn "dank-material-shell: flake output `nixosModules.dankMaterialShell` has been renamed to `nixosModules.dank-material-shell`" self.nixosModules.dank-material-shell;

      devShells = forEachSystem (
        system: pkgs:
        let
          devQmlPkgs = with pkgs;
          [
            quickshell
            kdePackages.qtdeclarative
          ]
          ++ (qmlPkgs pkgs);
        in
        {
          default = pkgs.mkShell {
            buildInputs =
              with pkgs;
              [
                (goForPkgs pkgs)
                go-mockery
                gopls
                delve
                go-tools
                gnumake

                prek
                uv # for prek
                shellcheck

                # Nix development tools
                nixd
                nil
              ]
              ++ devQmlPkgs;

            shellHook = ''
              touch quickshell/.qmlls.ini 2>/dev/null
              if [ ! -f .git/hooks/pre-commit ]; then prek install; fi
            '';

            QML2_IMPORT_PATH = mkQmlImportPath pkgs devQmlPkgs;
            QT_PLUGIN_PATH = mkQtPluginPath pkgs devQmlPkgs;
          };
        }
      );

      nixosTests = forEachLinuxSystem (
        system: pkgs:
        import ./distro/nix/tests {
          inherit
            self
            pkgs
            ;
          lib = pkgs.lib;
        }
      );
    };
}
