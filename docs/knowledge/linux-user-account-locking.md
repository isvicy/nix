# Linux 用户账户锁定机制

本文档记录 Linux 用户账户锁定的机制，特别是 `/etc/shadow` 文件中密码字段的含义。

## 背景

在配置 Gitea SSH passthrough 时，发现新创建的 `git` 用户无法通过 SSH 公钥认证登录，即使公钥已正确配置。日志显示：

```
User git not allowed because account is locked
```

## `/etc/shadow` 密码字段

`/etc/shadow` 文件格式：
```
username:password:lastchg:min:max:warn:inactive:expire:reserved
```

**密码字段的特殊值**：

| 值 | 含义 | 账户状态 |
|---|------|----------|
| `!` | 账户被锁定（从未设置密码或被 `passwd -l` 锁定） | 锁定 (L) |
| `!!` | 从未设置过密码（某些发行版） | 锁定 (L) |
| `*` | 系统账户，禁止密码登录 | 锁定 (L) |
| `!$6$...` | 密码被锁定，但保留了原始哈希 | 锁定 (L) |
| `$6$...` | 正常的密码哈希（SHA-512） | 有密码 (P) |
| `NP` | 无有效密码，但账户未锁定 | 有密码 (P) |
| 空 | 无密码，可直接登录（危险！） | 无密码 (NP) |

## 账户状态检查

```bash
# 查看账户状态
passwd -S username

# 输出格式：username STATUS lastchange min max warn inactive expire
# STATUS 可能的值：
#   L  - 锁定 (Locked)
#   P  - 有密码 (Password set)
#   NP - 无密码 (No Password)
```

## `useradd` 的默认行为

**关键点**：使用 `useradd` 创建用户时，如果不设置密码，密码字段默认为 `!`，账户处于**锁定状态**。

```bash
# 创建用户（不设置密码）
useradd -m git

# 查看 shadow 条目
grep git /etc/shadow
# 输出: git:!:20430:0:99999:7:::
#       ↑ 锁定标记
```

## SSH 与锁定账户

### PAM 的影响

当 sshd 配置 `UsePAM yes`（大多数发行版的默认值）时：

1. PAM 的 `pam_unix` 模块会检查账户是否锁定
2. **即使使用公钥认证**，锁定账户也会被拒绝
3. 这是安全特性，防止被禁用的账户通过任何方式登录

```
# /var/log/auth.log
sshd[12345]: User git not allowed because account is locked
```

### 解决方案

**方法 1：设置无效密码（推荐用于服务账户）**

```bash
# 设置一个无法匹配的密码值
usermod -p 'NP' git

# 或者使用一个无效的哈希
usermod -p '*NP*' git
```

**方法 2：解锁并设置随机密码**

```bash
# 生成随机密码并设置
echo "git:$(openssl rand -base64 32)" | chpasswd
```

**方法 3：修改 PAM 配置（不推荐）**

修改 `/etc/pam.d/sshd`，但这会影响系统安全性。

## 锁定与解锁命令

```bash
# 锁定账户
passwd -l username
# 或
usermod -L username

# 解锁账户（需要先有密码）
passwd -u username
# 或
usermod -U username

# 注意：如果账户从未设置过密码，解锁会失败
usermod -U git
# 输出: usermod: unlocking the user's password would result in a passwordless account.
```

## 服务账户最佳实践

对于只需要 SSH 公钥认证的服务账户（如 git）：

```bash
# 1. 创建用户
useradd -m -s /bin/sh git

# 2. 设置无效但非锁定的密码
usermod -p 'NP' git

# 3. 配置 SSH 公钥
mkdir -p /home/git/.ssh
chmod 700 /home/git/.ssh
# 添加 authorized_keys...

# 4. 验证状态
passwd -S git
# 应显示: git P ... （P 表示有密码，非锁定）
```

## 实际案例：Gitea SSH Passthrough

### 问题

Gitea Docker 容器配置了 SSH passthrough：
1. 主机上创建了 `git` 用户
2. `/home/git/.ssh/authorized_keys` 映射到容器
3. Gitea 正确添加了用户公钥
4. 但 SSH 连接失败：`Permission denied (publickey)`

### 原因

`git` 用户创建时未设置密码，账户处于锁定状态：

```bash
grep git /etc/shadow
# git:!:20430:0:99999:7:::

passwd -S git
# git L 2025-12-08 0 99999 7 -1
#    ↑ L = Locked
```

### 解决

```bash
usermod -p 'NP' git

passwd -S git
# git P 2025-12-08 0 99999 7 -1
#    ↑ P = Password set (non-locked)
```

## 相关文件

| 文件 | 用途 |
|------|------|
| `/etc/shadow` | 存储密码哈希和账户过期信息 |
| `/etc/passwd` | 存储用户基本信息（不含密码） |
| `/etc/pam.d/sshd` | SSH 的 PAM 配置 |
| `/etc/ssh/sshd_config` | SSH 服务器配置 |

## 参考资料

- [Understanding /etc/shadow file format on Linux - nixCraft](https://www.cyberciti.biz/faq/understanding-etcshadow-file/)
- [Understanding the /etc/shadow File - Linuxize](https://linuxize.com/post/etc-shadow-file/)
- [shadow(5) - Linux man page](https://linux.die.net/man/5/shadow)
- [How to check if user account is locked - howtouselinux](https://www.howtouselinux.com/post/linux-command-check-if-user-account-is-locked-or-not-in-linux)
