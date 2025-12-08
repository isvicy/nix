# DankMaterialShell makeWrapper 构建错误排查记录

**日期**: 2025-12-08
**影响版本**: DankMaterialShell commit `8838fd67` (2025-12-08)
**状态**: 已解决（固定到旧版本）

## 问题描述

### 现象

将 nixpkgs 从 `nixos-unstable` 切换到 `nixos-25.11` 后，执行 `nixos-rebuild switch` 时构建失败：

```
error: attribute 'makeWrapper' missing
at /nix/store/62j1bgicwhl0si0j9p54jjaxqms2gikg-source/flake.nix:73:29:
    72|                         nativeBuildInputs = with pkgs; [
    73|                             installShellFiles
       |                             ^
    74|                             .makeWrapper
```

### 触发条件

- 使用 `dankMaterialShell` flake input
- 设置 `inputs.nixpkgs.follows = "nixpkgs"` 让其跟随主 nixpkgs
- 执行 `nix flake update` 更新到 dankMaterialShell 最新版本

## 排查过程

### 1. 定位错误来源

错误信息显示问题出在 `/nix/store/...-source/flake.nix:73`，这是某个 flake input 的文件，不是本地配置。

通过 grep 搜索项目中的 `makeWrapper` 引用：
```bash
grep -r makeWrapper .
# 结果：项目中没有 makeWrapper 引用
```

确认问题来自外部依赖。

### 2. 确定是哪个 input

查看 nix store 中的 flake.nix：
```bash
cat /nix/store/62j1bgicwhl0si0j9p54jjaxqms2gikg-source/flake.nix | head -20
```

输出显示：
```nix
{
    description = "Dank Material Shell";
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        ...
    };
    ...
}
```

确认是 `dankMaterialShell` 这个 input。

### 3. 分析 Nix 语法错误

查看问题代码（flake.nix:72-75）：
```nix
nativeBuildInputs = with pkgs; [
    installShellFiles
    .makeWrapper      # <- 问题在这里
];
```

在 Nix 中，`.makeWrapper` 语法表示从前一个表达式继承属性，即 `installShellFiles.makeWrapper`。

验证这个理解：
```bash
nix eval --expr 'let pkgs = { installShellFiles = { makeWrapper = "wrapper-nested"; }; makeWrapper = "wrapper"; }; in with pkgs; [ installShellFiles .makeWrapper ]'
# 输出: [ "wrapper-nested" ]
```

但 `pkgs.installShellFiles` 是一个 derivation，不是 set，所以不存在 `.makeWrapper` 属性。这是上游的语法错误，应该写成 `makeWrapper` 而不是 `.makeWrapper`。

### 4. 为什么之前能用？

对比 flake.lock 中的版本：

| 状态 | dankMaterialShell commit | 日期 |
|------|-------------------------|------|
| 原来（能用） | `1f2a1c5dec5c36264e24d185f38fab2a7ddbb185` | 2025-11-26 |
| 更新后（报错） | `8838fd67b95ae0c608947a1991087cf3f8611dae` | 2025-12-08 |

检查旧版本的 flake.nix：
```bash
grep makeWrapper /nix/store/8qh3mjdzlh4bapc5am9hhc8pgg0248i5-source/flake.nix
# 结果：无输出
```

旧版本根本没有使用 `makeWrapper`，是新版本添加功能时引入了语法错误。

### 5. 为什么切换 nixpkgs 版本会触发？

当修改 flake.nix 后运行 `nix flake update`，会同时更新所有没有固定版本的 inputs，包括 `dankMaterialShell`。

这导致：
1. nixpkgs 从 unstable 切换到 25.11 ✓
2. dankMaterialShell 从 `1f2a1c5` 更新到 `8838fd6` ← 引入 bug

## 根本原因

DankMaterialShell 在 commit `8838fd67` (2025-12-08) 中添加了新功能，但代码有语法错误：

```nix
# 错误写法
nativeBuildInputs = with pkgs; [
    installShellFiles
    .makeWrapper      # 尝试访问 installShellFiles.makeWrapper，不存在
];

# 正确写法
nativeBuildInputs = with pkgs; [
    installShellFiles
    makeWrapper       # 直接引用 pkgs.makeWrapper
];
```

## 解决方案

### 方法 1: 固定到旧版本（推荐）

在 `flake.nix` 中固定 dankMaterialShell 到最后一个正常工作的版本：

```nix
dankMaterialShell = {
  # Pin to last working version - newer versions have a bug with .makeWrapper syntax
  url = "github:AvengeMedia/DankMaterialShell/1f2a1c5dec5c36264e24d185f38fab2a7ddbb185";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

然后更新 lock 文件：
```bash
nix flake update dankMaterialShell
sudo nixos-rebuild switch --flake .#rog
```

### 方法 2: 等待上游修复

向上游报告 bug 后等待修复：
- 仓库: https://github.com/AvengeMedia/DankMaterialShell
- 问题: flake.nix 第 74 行 `.makeWrapper` 应改为 `makeWrapper`

### 方法 3: 临时禁用 dankMaterialShell

如果不需要这个功能，可以暂时从配置中移除：

```nix
# home/desktop/niri.nix
imports = [
  inputs.niri.homeModules.niri
  # 注释掉以下两行
  # inputs.dankMaterialShell.homeModules.dankMaterialShell.default
  # inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
];

# 注释掉配置
# programs.dankMaterialShell = { ... };
```

## 相关文件

- `flake.nix` - Flake inputs 定义
- `home/desktop/niri.nix` - 使用 dankMaterialShell 的配置

## 经验总结

1. **`nix flake update` 会更新所有未固定的 inputs**：修改 flake.nix 后运行 update 可能会意外更新其他依赖
2. **使用 `nix flake update <input-name>` 可以只更新单个 input**：避免意外更新
3. **对于不稳定的第三方 flake，考虑固定版本**：使用 `url = "github:owner/repo/<commit-hash>"` 固定到已知正常的版本
4. **Nix 语法中 `.attr` 表示从前一个表达式继承**：`with pkgs; [ foo .bar ]` 等价于 `[ pkgs.foo pkgs.foo.bar ]`
5. **错误信息中的 nix store 路径可以帮助定位问题来源**：直接查看该路径下的文件确定是哪个 input
