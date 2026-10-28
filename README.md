# Brave Portable Bundle

在官方 [Brave Portable](https://github.com/portapps/brave-portable) 发布包之上，追加外部脚本与配置预置，实现**真正便携**的 Brave 浏览器体验：所有启动路径经启动器、用户数据唯一落 `data` 目录、宿主机 C 盘不留残留。

## 功能特性

- **数据便携**：书签、历史、Cookie、密码、扩展等全部数据保存在文件夹内 `data` 目录，复制整个文件夹即可迁移。
- **宿主干净**：预置 `cleanup: true`，Brave 退出时自动清理 `%APPDATA%\BraveSoftware` 和 `%LOCALAPPDATA%\BraveSoftware` 残留。
- **外部链接接管**：通过注册 ProgID + RegisteredApplications + StartMenuInternet 三件套，使外部链接（他处点击网址）经启动器打开，数据正确落入 `data`。
- **路径自愈**：桌面快捷方式每次启动自动检测并修正注册表中的启动器路径，移动文件夹后无需手动改注册表。
- **无闪窗启动**：桌面快捷方式经 `launch.vbs`（VBScript）启动，无命令行窗口闪烁。
- **一键注册/取消**：`setup.bat` 写入全部注册表键，`unregister.bat` 一键清理，均免管理员权限。

## 系统要求

- Windows 10 / 11 桌面版
- 普通用户权限即可（全部注册表键位于 `HKCU`）
- 不适用于企业组策略锁定默认应用的场景

## 快速开始

1. 从 [Releases](https://github.com/PennHui666/brave-portable-bundle/releases) 下载最新的 `.7z` 包并解压。
2. 双击 `setup.bat` 完成首次注册（会自动打开使用说明页）。
3. 在说明页点击"打开默认应用设置"，从列表中选择 **"Brave Portable"** 设为默认浏览器。

### 四条规则

1. 解压后先运行 `setup.bat`。
2. **不要**点击 Brave 内部的"设为默认浏览器"。
3. 数据始终在 `data` 目录，复制整个文件夹即可带走。
4. 移动文件夹或换机器后，重跑一次 `setup.bat`（换机器还需重新设一次默认浏览器）。

### 启动方式

| 方式 | 说明 |
|------|------|
| 桌面快捷方式（推荐） | 无闪窗，每次启动自动路径自愈 |
| 外部链接 | 经系统协议调用启动器，数据落入 `data` |
| 直接双击 `brave-portable.exe` | 可用，但不触发路径自愈 |
| 任务栏固定 `brave-portable.exe` | 可用，经启动器 |

> **切勿**固定 `app\brave.exe` 到任务栏——它会绕过启动器，数据落 C 盘并在退出时被清理，导致数据丢失。

## 目录结构

```
brave-portable-bundle/
├─ DESIGN.md                     # 设计定稿（完整技术文档）
├─ .gitignore
├─ .github/workflows/build.yml   # CI 组装与发布
├─ config/
│   └─ brave-portable.yml        # 预置配置（app.cleanup: true）
└─ payload/                      # 注入到发布包根目录的文件
    ├─ setup.bat                 # 首次注册
    ├─ launch.vbs                # 启动自愈
    ├─ unregister.bat            # 取消注册
    └─ readme.html               # 使用说明（随包分发）
```

## CI/CD 自动构建

GitHub Actions 工作流 `.github/workflows/build.yml` 自动跟踪上游 `portapps/brave-portable` 的发布并组装 bundle 包。

**触发策略**：

| 触发方式 | 行为 |
|----------|------|
| 定时（每天 UTC 04:00） | 检查上游最新版本，若本仓库已有对应 release 则跳过，否则自动构建发布 |
| 手动（`workflow_dispatch`） | 强制构建，若同名 release 已存在则删除后重建 |
| Push tags `v*` | 预留触发器 |

**构建流程**：下载上游 `.7z` → 解压 → 预置 `brave-portable.yml`（`cleanup: true`）→ 结构化校验 → 注入 payload 脚本 → 重打包 → 发布 Release（附 SHA256 校验和）。

## 取消注册

运行 `unregister.bat` 可删除 `setup.bat` 写入的全部注册表键。取消前请先在系统设置中将默认浏览器改回其他程序，否则外部链接将无法打开。

## 技术文档

完整的设计 rationale、注册表键清单、安全性分析、替代方案对比等内容见 [DESIGN.md](DESIGN.md)。

## 致谢

- [portapps/brave-portable](https://github.com/portapps/brave-portable) — 上游 Brave Portable 项目，由 CrazyMax 维护。
- 本项目不修改上游任何源码或二进制，仅在其发布包之上追加外部脚本与配置预置。

## 许可证

本项目的外部脚本与配置文件以 MIT 许可证发布。Brave 浏览器及其便携包装的版权归各自原作者所有。