{
  lib,
  stdenv,
  fetchurl,
  installShellFiles,
}:
stdenv.mkDerivation rec {
  pname = "skim";
  version = "2.0.2";

  src = fetchurl {
    url = "https://github.com/skim-rs/skim/releases/download/v${version}/skim-x86_64-unknown-linux-gnu.tar.xz";
    hash = "sha256-XcXFaj/9k+oHtstFS/F1Gph8477/URmbsMwwdkAH67c=";
  };

  sourceRoot = "skim-x86_64-unknown-linux-gnu";

  nativeBuildInputs = [installShellFiles];

  installPhase = ''
    runHook preInstall

    install -Dm755 sk -t $out/bin
    install -Dm444 shell/* -t $out/share/skim

    installManPage man/man1/*
    installShellCompletion \
      --cmd sk \
      --bash shell/completion.bash \
      --fish shell/completion.fish \
      --zsh shell/completion.zsh

    runHook postInstall
  '';

  meta = with lib; {
    description = "Command-line fuzzy finder written in Rust (prebuilt with frizbee support)";
    homepage = "https://github.com/skim-rs/skim";
    license = licenses.mit;
    platforms = ["x86_64-linux"];
    mainProgram = "sk";
  };
}
