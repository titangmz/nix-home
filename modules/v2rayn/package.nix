{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
  fontconfig,
}:
let
  version = "7.25.4";
  sources = {
    x86_64-linux = {
      url = "https://github.com/2dust/v2rayN/releases/download/${version}/v2rayN-linux-64.zip";
      hash = "sha256-vx1VLnxnEeSWfVcLi+cJX5UZNY4+pNfDoYqBvaOGr0g=";
      dir = "v2rayN-linux-64";
    };
    aarch64-darwin = {
      url = "https://github.com/2dust/v2rayN/releases/download/${version}/v2rayN-macos-arm64.zip";
      hash = "sha256-echoiNbeaCiBLDXYzh4NLH7+zzoy42GCy6+1oo1xrYs=";
      dir = "v2rayN-macos-arm64";
    };
    x86_64-darwin = {
      url = "https://github.com/2dust/v2rayN/releases/download/${version}/v2rayN-macos-64.zip";
      hash = "sha256-gwkA8OdIdAQAMbx7pdM0+VU1KEFHuvj4aWVySMYgLSQ=";
      dir = "v2rayN-macos-64";
    };
  };
  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "v2rayN has no build for ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "v2rayn";
  inherit version;

  src = fetchurl {
    inherit (source) url hash;
  };

  sourceRoot = source.dir;

  nativeBuildInputs = [
    unzip
  ]
  ++ lib.optionals stdenv.isLinux [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals stdenv.isLinux [
    fontconfig
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontFixup = stdenv.isDarwin;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/v2rayn $out/bin
    cp -a . $out/lib/v2rayn/
    chmod -R u+w $out/lib/v2rayn
    find $out/lib/v2rayn -type f \( \
      -name v2rayN -o -name AmazTool -o -name xray -o -name sing-box \
      \) -exec chmod +x {} +
    # Official marker: config and cores are copied to Local Application Data.
    touch $out/lib/v2rayn/NotStoreConfigHere.txt

    cat > $out/bin/v2rayN << EOF
    #!${stdenv.shell}
    export V2RAYN_LOCAL_APPLICATION_DATA_V2=1
    exec "$out/lib/v2rayn/v2rayN" "\$@"
    EOF
    chmod +x $out/bin/v2rayN

    ${lib.optionalString stdenv.isLinux ''
      install -Dm644 $out/lib/v2rayn/v2rayN.png \
        $out/share/icons/hicolor/256x256/apps/v2rayn.png
      mkdir -p $out/share/applications
      cat > $out/share/applications/v2rayn.desktop << EOF
      [Desktop Entry]
      Name=v2rayN
      Comment=Xray and sing-box GUI
      Exec=v2rayN
      Icon=v2rayn
      Terminal=false
      Type=Application
      Categories=Network;
      EOF
    ''}

    ${lib.optionalString stdenv.isDarwin ''
      app=$out/Applications/v2rayN.app/Contents
      mkdir -p "$app/MacOS" "$app/Resources"
      cat > "$app/Info.plist" << EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleExecutable</key>
        <string>v2rayN</string>
        <key>CFBundleIdentifier</key>
        <string>com.github.2dust.v2rayn</string>
        <key>CFBundleName</key>
        <string>v2rayN</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>CFBundleShortVersionString</key>
        <string>${version}</string>
        <key>CFBundleVersion</key>
        <string>${version}</string>
      </dict>
      </plist>
      EOF
      cat > "$app/MacOS/v2rayN" << EOF
      #!${stdenv.shell}
      export V2RAYN_LOCAL_APPLICATION_DATA_V2=1
      exec "$out/lib/v2rayn/v2rayN" "\$@"
      EOF
      chmod +x "$app/MacOS/v2rayN"
    ''}

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    test -x $out/bin/v2rayN
    test -x $out/lib/v2rayn/v2rayN
    test -x $out/lib/v2rayn/bin/xray/xray
    test -f $out/lib/v2rayn/NotStoreConfigHere.txt
    ${lib.optionalString stdenv.isDarwin ''
      test -x $out/Applications/v2rayN.app/Contents/MacOS/v2rayN
    ''}
  '';

  meta = {
    description = "GUI client for Xray, sing-box, and other cores";
    homepage = "https://github.com/2dust/v2rayN";
    changelog = "https://github.com/2dust/v2rayN/releases/tag/${version}";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "v2rayN";
    platforms = builtins.attrNames sources;
  };
}
