# NoMount User Certs Sync (`nomount_user_certs`)

A lightweight KernelSU / APatch / Magisk module that mirrors Android User CA certificates into both `/system/etc/security/cacerts` and `/apex/com.android.conscrypt/cacerts` using **[NoMount](https://github.com/maxsteeel/nomount)** kernel VFS path redirection — **with zero `tmpfs` mounts and zero `nsenter` / Zygote injection**.

一个配合 **[NoMount](https://github.com/maxsteeel/nomount)** 使用的轻量级证书同步模块：通过 NoMount 内核级 VFS 路径重定向，将 Android 用户 CA 证书自动同步到 `/system/etc/security/cacerts` 与 `/apex/com.android.conscrypt/cacerts`，**不产生任何 `tmpfs` / `overlay` 挂载记录，也无需 `nsenter` 注入 Zygote**。

## Why / 为什么选择这种方式？

- **Android 14–16 Conscrypt APEX compatible**：同时覆盖 `/system/etc/security/cacerts` 与 `/apex/com.android.conscrypt/cacerts`（覆盖 Go/底层库读取 `/system` 及系统网络栈/应用读取 APEX 两条路径）。
- **Zero extra mounts**：复用 NoMount 元模块进行内核 VFS 路径重定向，不新增 `tmpfs` 或 `overlay` 挂载点。
- **Proper SELinux labels**：自动配置 `0:0`、`0755/0644` 及 `u:object_r:system_security_cacerts_file:s0`，确保非特权 App（如 `v2rayNG` / 浏览器）正常读取。
- **Live sync (`inotifyd`)**：后台监听 `/data/misc/user/0/cacerts-added`，在系统设置中安装或删除用户 CA 证书后自动热重载，无需每次重启。
- **KernelSU Action button**：支持在 KernelSU 管理器中点击「操作」按钮立即手动同步并查看当前生效规则。

## Requirements / 使用前提

- Root 方案：KernelSU / KernelSU Next / APatch / Magisk
- 已安装并启用 **[NoMount](https://github.com/maxsteeel/nomount)** 元模块（`/data/adb/modules/nomount/bin/nm`）
- Android 14 / 15 / 16（亦兼容更低版本）

## Installation & Usage / 安装与使用

1. 从 [Releases](https://github.com/CoderTCY/nomount-user-certs/releases) 下载 `nomount-user-certs-v*.zip`，在 KernelSU / APatch / Magisk 中刷入并重启。
2. 在手机「系统设置 → 安全 → 安装证书 → CA 证书」中安装你的 CA 证书（Android 会将其以 `<hash>.0` 写入 `/data/misc/user/0/cacerts-added/`）。
3. 模块通过 `inotifyd` 自动将其镜像到 NoMount 虚拟目录并调用 `nm module load` 生效；你也可以在管理器中点击模块的「操作 / Action」按钮触发手动同步。
4. （可选）如果需要额外预置已经是 OpenSSL `subject_hash_old` 命名格式（`<hash>.0`）的 PEM 证书，可直接放入模块目录下的 `extra_certs/`，随后点击 Action 或运行 `sync.sh --live`。

## How It Works / 工作原理

1. **`post-fs-data.sh` (`sync.sh --stage-only`)**：在 `NoMount` 元模块的 `metamount.sh` 执行前，将用户证书镜像到 `$MODDIR/system/etc/security/cacerts/` 与 `$MODDIR/apex/com.android.conscrypt/cacerts/`。
2. **`service.sh` (`sync.sh --live`)**：开机完成后兜底重载一次规则，并启动 `busybox inotifyd` 监听 `/data/misc/user/0/cacerts-added`。
3. **`uninstall.sh`**：卸载模块时停止 `inotifyd` 并调用 `nm module unload` 清理全部 VFS 重定向规则。

## License

[MIT](LICENSE)
