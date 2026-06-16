# Xboard-Node 完全隐藏安装脚本 (Alpine Linux)

<p align="center">
  <img src="https://img.shields.io/badge/Alpine-Linux-blue?style=flat-square&logo=alpinelinux" alt="Alpine Linux">
  <img src="https://img.shields.io/github/v/release/lei33440/xboard-node-hidden-alpine?style=flat-square" alt="Version">
  <img src="https://img.shields.io/github/stars/lei33440/xboard-node-hidden-alpine?style=flat-square" alt="Stars">
</p>

一个专为 **Alpine Linux** 系统设计的 Xboard-Node **完全隐藏**安装脚本，支持同一台服务器对接多个面板，且所有痕迹完全隐藏。

> 🔒 `ps -ef | grep xboard` 显示为空，真正完全隐藏！

## 功能特性

- 🔒 **进程名隐藏** - 显示为 `crond-worker`/`ssh-agent` 等常见系统进程名
- 🔒 **二进制隐藏** - 重命名为 `kernel-update`
- 🔒 **配置隐藏** - 配置存储在 `/etc/.system-cache/` 隐藏目录（持久化）
- 🔒 **服务描述隐藏** - OpenRC 服务显示为 "System Service"
- ✅ **多面板支持** - 一台服务器对接多个不同面板
- ✅ **独立实例** - 每个实例独立运行，互不影响
- ✅ **一键部署** - 只需一条命令即可完成安装
- ✅ **多架构支持** - 支持 amd64 和 arm64
- ✅ **OpenRC 管理** - 使用 OpenRC 服务管理（Alpine 原生）
- ✅ **开机自启** - 支持服务开机自动启动

## 隐藏效果对比

### 普通安装

```bash
$ ps aux | grep xboard
root  1234  ... /usr/local/bin/xboard-node -c /etc/xboard-node-mypanel/config.yml
```

### 完全隐藏安装

```bash
$ ps aux | grep xboard
(无结果 - 完全隐藏!)
```

```bash
$ ps aux | grep -E "crond-worker|ssh-agent"
root  1234  ... crond-worker -c /etc/.system-cache/mypanel/config.yml
```

看起来像普通的系统进程！

## 支持的系统

| 系统 | 架构 | 状态 |
|------|------|------|
| Alpine 3.10+ | x86_64 (amd64) | ✅ 支持 |
| Alpine 3.10+ | aarch64 (arm64) | ✅ 支持 |

## 快速开始

### 安装实例

```bash
# 安装脚本
wget -N https://raw.githubusercontent.com/lei33440/xboard-node-hidden-alpine/main/install-instance.sh -O install.sh && chmod +x install.sh

# 添加第一个面板
sh install.sh \
  --name mypanel \
  --panel http://面板1地址 \
  --token 面板1TOKEN \
  --machine-id 1

# 添加第二个面板
sh install.sh \
  --name backup \
  --panel http://面板2地址 \
  --token 面板2TOKEN \
  --machine-id 1
```

### 参数说明

| 参数 | 必需 | 说明 |
|------|------|------|
| `--name` | 是 | 实例名称（英文，唯一标识） |
| `--panel` | 是 | 面板地址 URL |
| `--token` | 是 | 通信令牌 |
| `--machine-id` | 是 | 机器 ID |
| `--version` | 否 | Xboard-Node 版本（默认：latest） |
| `--help` | 否 | 显示帮助信息 |

## 隐藏原理

1. **二进制重命名**: `xboard-node` → `kernel-update`
2. **进程名伪装**: 使用 `exec -a` 将进程名改为 `crond-worker`/`ssh-agent` 等
3. **配置隐藏**: 配置存储在 `/etc/.system-cache/{实例名}/`（持久化，重启不丢失）
4. **日志隐藏**: OpenRC 服务输出重定向到 null

### 隐藏内容

| 原项目 | 隐藏后 |
|--------|--------|
| 进程名 `xboard-node` | `crond-worker` / `ssh-agent` |
| 二进制 `/usr/local/bin/xboard-node` | `/usr/local/bin/kernel-update` |
| 配置 `/etc/xboard-node-{name}` | `/etc/.system-cache/{name}` |
| OpenRC 描述 | `System Service` |

## 实例管理

### 查看所有实例

```bash
# 查看 OpenRC 服务状态
rc-status

# 查看隐藏进程
ps aux | grep -E "crond-worker|ssh-agent|system-logger"

# 查看端口
netstat -tlnp | grep -E '321[0-9]{2}'
```

### 启动/停止/重启单个实例

```bash
# 启动
/etc/init.d/xboard-node-mypanel start

# 停止
/etc/init.d/xboard-node-mypanel stop

# 重启
/etc/init.d/xboard-node-mypanel restart

# 查看状态
/etc/init.d/xboard-node-mypanel status
```

### 卸载实例

```bash
# 卸载指定实例
wget -N https://raw.githubusercontent.com/lei33440/xboard-node-hidden-alpine/main/uninstall-instance.sh -O uninstall.sh && chmod +x uninstall.sh
sh uninstall.sh --name mypanel

# 卸载所有实例
wget -N https://raw.githubusercontent.com/lei33440/xboard-node-hidden-alpine/main/uninstall-all.sh -O uninstall-all.sh && chmod +x uninstall-all.sh
sh uninstall-all.sh
```

## 文件位置

| 文件 | 路径 |
|------|------|
| 二进制 | `/usr/local/bin/kernel-update` |
| 实例配置 | `/etc/.system-cache/{实例名}/config.yml` |
| 包装脚本 | `/usr/local/bin/{crond-worker|ssh-agent|...}` |
| OpenRC 服务 | `/etc/init.d/xboard-node-{实例名}` |

## 与 Debian 版本的区别

| 功能 | Alpine 版本 | Debian 版本 |
|------|-----------|------------|
| 服务管理 | OpenRC | systemd |
| 进程隐藏 | ✅ | ✅ |
| 二进制隐藏 | ✅ | ✅ |
| 配置隐藏 | ✅ | ✅ |
| 持久化 | ✅ | ✅ |
| 多面板 | ✅ | ✅ |
| 开机自启 | ✅ | ✅ |

## 常见问题

### Q: 如何验证进程已完全隐藏？

A: 执行以下命令：
```bash
# 应该显示无结果
ps aux | grep xboard

# 应该显示伪装后的进程
ps aux | grep -E "crond-worker|ssh-agent"
```

### Q: 实例名称有什么要求？

A: 只能是英文字母、数字和连字符，不能有特殊字符。例如：`mypanel`、`panel-1`、`backup`。

### Q: 可以同时运行多少个实例？

A: 理论上没有限制，但受服务器性能和端口数量限制。建议不超过 10 个实例。

### Q: 如何备份配置？

A:
```bash
# 备份所有实例配置
tar -czf hidden-backup.tar.gz /etc/.system-cache/

# 恢复备份
tar -xzf hidden-backup.tar.gz -C /
```

### Q: 日志在哪里查看？

A: 使用 OpenRC 日志：
```bash
tail -f /var/log/xboard-node-mypanel.log
```

## 更新日志

### v1.0.2 (2026-06-16)
- 🐛 修复 OpenRC 服务启动失败问题（supervise-daemon 报 "first argument must be" 错误）
- 🔧 改用 start-stop-daemon 直接管理服务，兼容 Alpine 3.10+
- ✅ 优化 PID 文件管理，start/stop 更可靠

### v1.0.1 (2026-06-16)
- 🐛 修复 OpenRC supervise-daemon 服务名匹配问题
- 🔗 创建与 service 同名的符号链接
- 🔗 卸载脚本同步清理符号链接

### v1.0.0 (2026-06-08)
- 🎉 首发版本
- 🔒 进程名隐藏（crond-worker/ssh-agent）
- 🔒 二进制重命名为 kernel-update
- 🔒 配置存储在 /etc/.system-cache/ 持久化目录
- ✅ Alpine OpenRC 服务管理
- ✅ 支持多面板/多实例
- ✅ 支持开机自启
- ✅ 支持 amd64 和 arm64 架构

## 相关项目

- [xboard-node-multi-panel](https://github.com/lei33440/xboard-node-multi-panel) - Alpine 多面板安装（普通版）
- [xboard-node-multi-panel-debian](https://github.com/lei33440/xboard-node-multi-panel-debian) - Debian 多面板安装（普通版）
- [xboard-node-hidden-process](https://github.com/lei33440/xboard-node-hidden-process) - Debian 完全隐藏安装（基础版本）
- [Xboard](https://github.com/cedar2025/Xboard) - 功能强大的代理面板
- [Xboard-Node](https://github.com/cedar2025/Xboard-Node) - Xboard 节点后端

## 许可证

本项目基于 MPL-2.0 许可证开源。

## 联系方式

- GitHub: https://github.com/lei33440
- 项目反馈: https://github.com/lei33440/xboard-node-hidden-alpine/issues