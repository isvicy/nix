# 在 NixOS 上安装 .deb 包

NixOS 不支持直接安装 `.deb` 包，需要将其转换为 Nix derivation。本文档记录了完整的打包流程。

## 核心步骤

### 1. 下载并分析 .deb 包

```bash
# 下载 .deb 文件
curl -L -o /tmp/package.deb "https://example.com/package.deb"

# 解压查看内容结构
cd /tmp && mkdir extract && ar x package.deb && tar xf data.tar.* -C extract

# 查看文件结构
ls -la extract/
```

### 2. 获取正确的哈希值

**重要**: Nix 的 SRI 格式 `sha256-xxx=` 需要 base64 编码，不是 base32。

```bash
# 方法一：使用 nix-prefetch-url（推荐）
nix-prefetch-url --type sha256 "https://example.com/package.deb"
# 输出 base32 哈希，例如：12apj1j4sqaimcmh7xdnhll5mdqm9zjkbgzka2gbdz4zdgf325wy

# 方法二：转换为 SRI 格式
nix hash convert --to sri --hash-algo sha256 12apj1j4sqaimcmh7xdnhll5mdqm9zjkbgzka2gbdz4zdgf325wy
# 输出：sha256-nhcx3Guf/LaeUPO/NeVPFbdaKIW29QMrq1FhTWSQV4k=
```

### 3. 创建 Nix 包定义

在 `pkgs/` 目录下创建包文件，例如 `pkgs/myapp.nix`：

```nix
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  # 根据应用需要添加依赖
  alsa-lib,
  gtk3,
  libGL,
  # ... 其他依赖
}:
stdenv.mkDerivation rec {
  pname = "myapp";
  version = "1.0.0";

  src = fetchurl {
    url = "https://example.com/myapp_${version}_amd64.deb";
    hash = "sha256-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=";  # SRI 格式
  };

  nativeBuildInputs = [
    dpkg              # 解压 .deb
    autoPatchelfHook  # 自动修补 ELF 二进制文件
    makeWrapper       # 创建包装脚本
  ];

  buildInputs = [
    # 运行时依赖库
    alsa-lib
    gtk3
    libGL
    # ...
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt
    cp -r opt/MyApp $out/opt/

    mkdir -p $out/bin
    makeWrapper $out/opt/MyApp/myapp $out/bin/myapp \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"

    # 安装图标和 .desktop 文件
    mkdir -p $out/share/applications
    cp usr/share/applications/*.desktop $out/share/applications/

    mkdir -p $out/share/icons
    cp -r usr/share/icons/* $out/share/icons/

    runHook postInstall
  '';

  meta = with lib; {
    description = "My Application";
    homepage = "https://example.com";
    license = licenses.unfree;
    platforms = ["x86_64-linux"];
    mainProgram = "myapp";
  };
}
```

### 4. 添加到 Flake Overlay

在 `flake.nix` 中添加 overlay：

```nix
overlays = [
  # ... 其他 overlays
  (_final: prev: {
    myapp = prev.callPackage ./pkgs/myapp.nix {};
  })
];
```

### 5. 添加到用户包列表

在 home-manager 配置中添加：

```nix
home.packages = with pkgs; [
  myapp
];
```

### 6. 构建并测试

```bash
# 重要：新文件需要先 git add，否则 flake 找不到
git add pkgs/myapp.nix

# 单独测试包构建
nix-build --expr 'with import <nixpkgs> {}; callPackage ./pkgs/myapp.nix {}'

# 重建系统
sudo nixos-rebuild switch --flake .#hostname
```

## 常见问题

### 哈希格式错误

**症状**: 构建静默失败，无错误信息

**原因**: `sha256-xxx` 后面应该是 base64 编码，不是 base32

**解决**: 使用 `nix hash convert` 转换格式

### 缺少动态库

**症状**: 运行时报错 `cannot open shared object file`

**解决**: 在 `buildInputs` 中添加缺少的库，常见的有：
- `libGL` - OpenGL 支持
- `libxkbcommon` - 键盘输入
- `alsa-lib` - 音频
- `gtk3` - GTK 界面
- `nss` / `nspr` - 网络安全

## Electron 应用完整指南

Electron 应用需要特殊处理才能在 NixOS 上正常运行，尤其是在 Wayland 环境下。

### 完整依赖列表

```nix
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
  libGL
  libxkbcommon
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
  systemd  # 用于 libudev
];
```

### Wayland 支持

Electron 应用默认使用 XWayland，需要添加启动参数启用原生 Wayland：

```nix
makeWrapper $out/opt/MyApp/myapp $out/bin/myapp \
  --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
  --add-flags "--enable-features=UseOzonePlatform,WaylandWindowDecorations" \
  --add-flags "--ozone-platform=wayland"
```

**可选参数**（根据需要添加）：

```nix
--add-flags "--enable-wayland-ime"        # 输入法支持
--add-flags "--disable-gpu-sandbox"       # 如果遇到 GPU 问题
```

### 透明窗口应用（如桌面宠物）

对于需要透明背景的应用（如 Confirmo 桌面宠物），需要配置 compositor 窗口规则。

**Niri 配置示例**：

```nix
window-rules = [
  {
    matches = [
      {app-id = "myapp";}
      {app-id = "MyApp";}  # 注意大小写可能不同
    ];
    open-floating = true;
    border.enable = false;
    focus-ring.enable = false;
    shadow.enable = false;
    clip-to-geometry = false;
    draw-border-with-background = false;
    geometry-corner-radius = {
      top-left = 0.0;
      top-right = 0.0;
      bottom-left = 0.0;
      bottom-right = 0.0;
    };
  }
];
```

**查找应用的 app-id**：

```bash
# 运行应用后执行
niri msg windows | grep -A5 "App ID"
```

### 已知限制

1. **应用内更新不可用**：NixOS 的 `/nix/store` 是只读的，应用无法自更新。需要手动更新 `version` 和 `hash` 后重新构建。

2. **移动浮动窗口**：在 niri 中使用 `Mod + 左键拖动` 移动浮动窗口，直接拖动需要应用实现 `xdg-toplevel` 协议。

## 从源码运行 Electron 应用

如果你有 Electron 应用的源码，可以直接用 nix-shell 运行开发版本。

### 创建 shell.nix

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nodejs_20
    pnpm  # 或 yarn / npm
    electron

    # Electron 运行时依赖
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
    libGL
    libxkbcommon
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

  shellHook = ''
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
      pkgs.alsa-lib
      pkgs.gtk3
      pkgs.libGL
      pkgs.nss
      pkgs.xorg.libX11
    ]}:$LD_LIBRARY_PATH"
  '';
}
```

### 运行步骤

```bash
# 进入项目目录
cd /path/to/electron-app

# 启动 nix-shell
nix-shell

# 安装依赖
pnpm install

# 开发模式运行（使用系统 Electron）
pnpm run dev

# 或直接用 electron 运行
electron . --enable-features=UseOzonePlatform --ozone-platform=wayland
```

### 使用 flake 开发环境

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    devShells.x86_64-linux.default = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in pkgs.mkShell {
      packages = with pkgs; [
        nodejs_20
        pnpm
        electron
      ];

      LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (with pkgs; [
        alsa-lib gtk3 libGL nss mesa libdrm
        xorg.libX11 xorg.libXcomposite xorg.libxcb
      ]);
    };
  };
}
```

运行：`nix develop`

## 参考

- [Nixpkgs Manual - Trivial Builders](https://nixos.org/manual/nixpkgs/stable/#chap-trivial-builders)
- [autoPatchelfHook](https://nixos.org/manual/nixpkgs/stable/#setup-hook-autopatchelfhook)
- [Electron Wayland Support](https://www.electronjs.org/docs/latest/tutorial/wayland)
- [Niri Window Rules](https://github.com/YaLTeR/niri/wiki/Configuration:-Window-Rules)
