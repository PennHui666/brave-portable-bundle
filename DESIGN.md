# Brave Portable 真正便携方案 · 设计定稿

- 版本：v1.0（定稿，待实施）
- 日期：2026-10-26
- 实施位置：`E:\brave-portable\brave-portable-bundle\`（新建项目文件夹）
- 硬约束（已定调）：
  1. 整套方案以**新建项目文件夹**方式落地，不与参考源码同处一层构建。
  2. `brave-portable` 源码**仅作参考资料**，不作实施载体、**不修改其任何文件**（含 `main.go`、启动器二进制）。

---

## 0. 一句话概述

在官方 Brave Portable 发布包之上，追加一组**外部脚本**与**一处配置预置**，使「所有启动路径都经过启动器、用户数据只落 `data`、宿主机 C 盘不留残留」。用户无需理解注册表机制，只需记住四条规则。

## 1. 背景与根因（含本机实证）

- 现象：经 Brave 内置“设为默认浏览器”后，外部链接触发时数据分叉——`data` 一套、C 盘 `AppData` 另一套；迁移后因内部状态/加密绑定不一致而异常。
- 根因：Brave 内置注册写入的 ProgID 命令**直接指向 `app\brave.exe`**、且为**绝对路径**、**不带 `--user-data-dir`**，从而绕过启动器的重定向逻辑。
- 本机实测证据（只读查询 HKCU）：
  ```
  HKCU\Software\Classes\BraveHTML.IJX5VDOZXX7NJMILTMBTV344LA\shell\open\command
      = "D:\brave-portable-win64-1.95.104-101\app\brave.exe" --single-argument %1
  ```
- 结论：**外部链接的启动路径被切换**是唯一根因；方案目标即“把外部链接重新引回启动器”。

## 2. 适用范围与边界

**适用**
- 单机 / 多机 / U 盘携带，追求“复制即迁移 + 宿主干净”的个人用户。
- Windows 10 / 11 桌面版；普通用户权限即可（全部键位在 `HKCU`，免管理员）。
- 使用官方（未修改的）Brave Portable 发布包。

**不适用 / 明确排除**
- 企业集中管控、组策略锁定默认应用的场景。
- 需要程序化设置 `UserChoice` 的场景——Windows 的 Hash 校验机制不允许，**必须人工确认一次**。
- 同时“注册”多份便携包（同名键互斥，见 §9）。
- 与系统版 Brave 混装且不愿 cleanup 触及 `AppData\BraveSoftware` 的场景（见 §10 风险）。

**已确认的天然约束（不需额外处理）**
- `--disable-machine-id`、`--disable-encryption-win` 由启动器硬编码，任何经启动器的启动自动携带 → 跨机 cookie 解密无需处理。
- 官方默认 `cleanup: false`；本方案预置为 `true`。

## 3. 设计目标与非目标

目标：数据唯一归宿 `data`；所有启动经启动器；宿主无残留；迁移靠复制文件夹 + 一次 setup；用户认知负担最低。

非目标：不自动设置 `UserChoice`；不修改 Brave 二进制或启动器源码；不接管/不修复系统版 Brave 的数据。

## 4. 总体架构

```
用户解压
   │
   ├─ setup.bat ──────► 写 HKCU 注册表（ProgID + RegisteredApplications + StartMenuInternet）
   │                    比对/更新路径、创建桌面快捷方式、打开 readme.html
   │
   ├─ readme.html ────► 引导用户在系统设置里手动把默认浏览器设为 “Brave Portable”
   │                    （打开 ms-settings:defaultapps）
   │
两次启动路径：
   ├─ 桌面快捷方式 → launch.bat ──► 自检 UserChoice + 路径自愈 ──► brave-portable.exe
   └─ 外部链接 → System(UserChoice) ──► BravePortableHTML 命令 ──► brave-portable.exe
                                                                     │
                                                                     ▼
                                            brave-portable.exe（官方启动器，未修改）
                                                                     │
                                    注入 --user-data-dir=<包>\data 等参数，启动 app\brave.exe
                                                                     │
                                            Brave 退出 → cleanup:true 清理 C 盘残留
```

## 5. 模块职责划分

| 构件 | 文件 | 职责 | 触发时机 |
|---|---|---|---|
| 首次注册 | `setup.bat` | 写全部注册表键；路径比对与修正；创建桌面快捷方式；打开说明页 | 用户解压后双击一次 |
| 启动自检 | `launch.bat` | 读 `UserChoice` 自检；路径不一致则自愈；异常时提示并引导 | 桌面快捷方式每次启动 |
| 说明页 | `readme.html` | 原理、设默认步骤、禁令、数据位置、迁移、取消、安全提示 | setup 打开 / 随时 |
| 取消注册 | `unregister.bat` | 删除本方案写入的全部键；不碰 `UserChoice`；可重复运行 | 用户需要清理时 |
| CI 组装 | `.github/workflows/*.yml` | 下载上游包 → 解压 → 预置 yml → 校验 → 注入自定义文件 → 重打包发布 | 上游发版 / 手动 |
| 预置配置 | `brave-portable.yml` | `app.cleanup: true` | 随包分发 |

## 6. 关键技术选型与特性（含取舍）

1. **注册位置：`HKCU`（用户级）而非 `HKLM`**
   - 特性：免管理员、每用户独立、UAC 友好。
   - 取舍：牺牲“机器级/对所有用户生效”，换取零提权与最低打扰——契合个人便携场景。

2. **协议 ProgID + `RegisteredApplications` + `StartMenuInternet` 三件套**
   - 特性：`ProgID` 决定外部链接实际执行的命令；`RegisteredApplications→Capabilities\URLAssociations` 让条目进入“默认应用/按协议选默认”的候选；`StartMenuInternet` 使其在系统眼里“像浏览器”。
   - 取舍：遵循微软规范注册（虽 `StartMenuInternet` 非 http/https 生效的硬必需，但成本低、贴合 Chrome/Brave 做法）。

3. **`UserChoice` 只读不写**
   - 特性：Windows 10 1607+ 对其做 Hash 校验，程序写入会被判篡改并回滚。
   - 取舍：接受“必须用户手动确认一次”的操作成本，换取系统层面的可靠性。

4. **wrapper 命令用 `"<wrapper>" "%1"`（**不用** `--open-url`）**
   - 因不修改启动器源码，官方 wrapper 不认识 `--open-url`；裸 URL 会被透传给 `brave.exe` 并由 Chromium 正常打开。
   - 取舍：放弃自定义注入防护，改以“URL 来自系统协议调用 + 双引号包裹”缓解；残余风险列为可接受（见 §10）。

5. **自愈（原 D 项）落在 `launch.bat`**
   - 特性：只在“桌面快捷方式启动”这条路径触发；`setup.bat` 亦含同一比对逻辑覆盖“重跑脚本”。
   - 取舍：不改源码就无法覆盖“裸双击 / 任务栏固定启动器”；说明页引导用户以桌面快捷方式为主入口，以换取“零改源码”。

6. **`unregister.bat` 采用静态文件随包分发（**修正原构想“由 setup 生成”**）**
   - 特性：删除的是固定键名，与路径无关，故无需动态生成。
   - 取舍：降低 setup 复杂度与出错面；文件由 CI 注入即可。

## 7. 注册表键完整清单（定稿）

以下全部写入 `HKCU`。`<W>` 表示启动器绝对路径（由脚本用 `%~dp0` 展开，不写死）。

```
; —— 协议 ProgID（外部链接实际执行处）——
HKCU\Software\Classes\BravePortableHTML
    (Default)                 = "Brave Portable Document"
    DefaultIcon\(Default)     = "<W>",0
    shell\open\command\(Default) = "<W>" "%1"

; —— 浏览器客户端注册 ——
HKCU\Software\Clients\StartMenuInternet\BravePortable
    (Default)                 = "Brave Portable"
    DefaultIcon\(Default)     = "<W>",0
    shell\open\command\(Default) = "<W>"
    Capabilities
        ApplicationName       = "Brave Portable"          ; 显示名
        ApplicationDescription= "Brave 便携版：数据保存在本文件夹内。"
        Startmenu
            StartMenuInternet  = "BravePortable"           ; 必须等于上面的子键名
        URLAssociations
            http               = "BravePortableHTML"
            https              = "BravePortableHTML"
        FileAssociations
            .html  = "BravePortableHTML"
            .htm   = "BravePortableHTML"
            .shtml = "BravePortableHTML"
            .xht   = "BravePortableHTML"
            .xhtml = "BravePortableHTML"

; —— 登记到“默认应用”候选 ——
HKCU\Software\RegisteredApplications
    "Brave Portable"           = "Software\Clients\StartMenuInternet\BravePortable\Capabilities"
```

要点（对应上轮评审的硬伤修复）：
- **必含 `ApplicationDescription`**：缺失将导致条目**不出现在默认程序 UI 列表**。
- **`DefaultIcon` 两层都要写**：浏览器客户端层为微软规范强制项。
- **`Startmenu\StartMenuInternet` 必须与子键名一致**。
- `ApplicationName` 与 `RegisteredApplications` 值名保持同名（均 “Brave Portable”）。
- `FileAssociations` 仅声明能力（让 Brave Portable 出现在网页文件候选），**不强制改默认**，与 Chrome/Brave 一致。

**实现注记（bat + reg.exe 引号转义，已实测验证目标值正确）**
- ProgID 命令在 bat 中写作：
  `reg add "HKCU\Software\Classes\BravePortableHTML\shell\open\command" /ve /d "\"%~dp0brave-portable.exe\" \"%%1\"" /f`
  - `\"`：reg.exe 的字面双引号转义；`%%1`：bat 转义为字面 `%1` 占位符；`"%~dp0..."`：空格路径整体加引号。
- 中文路径/值：bat 以 **UTF-8** 保存 + 首行 `chcp 65001 >nul`，reg.exe 即按 UTF-8 处理，注册表内部为 Unicode。
- 实测（PowerShell .NET API，因本环境禁 cmd.exe）：值 `"E:\...\_test space\brave-portable.exe" "%1"` 与中文 `ApplicationDescription` 均正确写入并读回。建议用户双击测试 bat 做最终确认。

## 8. 各启动路径与数据流

- **外部链接触发**：Windows 依 `UserChoice`（http/https）= `BravePortableHTML` → 执行 `"<W>" "%1"` → 启动器注入 `--user-data-dir=<包>\data` → `app\brave.exe` → 数据落 `data`。
- **桌面快捷方式**：`launch.bat` 自检 + 自愈 → 启动器（同上）。
- **直接双击 `brave-portable.exe`**：仍经启动器 → 数据落 `data`（正确），但**不触发自检/自愈**（接受的局限）。
- **退出后**：启动器执行 `cleanup: true`，清理 C 盘非用户资料残留。

## 9. 边界情况与风险处置

| 场景 | 影响 | 处置 |
|---|---|---|
| `Capabilities` 缺 `ApplicationDescription` | 不出现在候选列表，链路断 | 定稿已强制写入 |
| 删 ProgID 后 `UserChoice` 悬空 | 外部链接失败 | `unregister.bat` 先检测并**警告“请先改回其他默认浏览器”** |
| 移动文件夹后未重注册 | 命令指向旧路径失效 | `setup.bat` 覆盖 + `launch.bat` 自愈 + 说明页规则 |
| **迁移到新机器** | `UserChoice` 是本机键，不随文件夹走 | 说明页明确：**需重新设一次默认** |
| 多份便携包 | 同名 `BravePortable*` 键互相覆盖 | 说明页声明“同一时刻只注册一份” |
| 用“选择其他应用→指向 exe”设默认 | 系统另建 ProgID，链路断 | 说明页强调：**从列表选 “Brave Portable”**，勿按 exe 路径选 |
| 中文/空格路径 | cmd 代码页、`reg add` 引号转义 | 全程加引号；脚本首行 `chcp 65001`；已实测通过（见 §7 注记） |
| 杀毒/EDR 拦截 | “bat 改 http/https 关联”是劫持特征，可能告警/回滚 | 代码签名、说明用途；把行为做得可见 |
| 组策略锁定默认应用 | 手动/写入均失败 | 说明前置条件 |

## 10. 安全性设计

- **注册表**：全部 `HKCU`、可逆、附 `unregister.bat`；但行为特征接近“浏览器劫持”，**是 AV 误伤头号来源**，需配合签名与透明说明。
- **`UserChoice`**：只读；`unregister.bat` 绝不改写。
- **`data` 明文存储**：`--disable-encryption-win` 令 cookie、**保存的密码、自动填充、OAuth/会话 token** 均可被固定密钥解密。说明页须警示：**像保管密码一样保管本文件夹，建议置于 BitLocker/加密卷，勿放共享盘**。
- **`cleanup: true`**：清理目标为 `%APPDATA%\BraveSoftware`、`%LOCALAPPDATA%\BraveSoftware`（正是**系统版 Brave 的数据目录**）。若本机混装普通版 Brave，**存在误删其用户数据的风险** → 说明页须显著警示；如需彻底规避，只能调整清理目标（代价：改启动器源码，本方案不予采纳）。
- **可逆性**：`unregister.bat` 可重复运行，删键容忍“不存在”。

## 11. 可维护性与可移植性

- **“复制文件夹即迁移”= 部分达成**：迁移后需**重跑 `setup.bat`**（修路径）；换机器还需**重设一次默认**。两条都必须写进说明页，避免“复制后以为能用”的落差。
- **上游变动**：产物格式（7z）、yml 键位可能变化 → 工作流做**结构化校验**。
- **脚本健壮性**：所有路径加引号、统一 UTF-8/`chcp`、输出**执行日志**便于排障。
- **上游合并成本**：因不改源码，无 fork 合并负担；代价是自愈覆盖不全。

## 12. CI 工作流设计

流程：下载上游发布包 → 解压 → 预置 `brave-portable.yml` → **结构化校验** → 注入自定义文件（包根）→ 重打包 → 发 Release。

关键约束：
1. **校验用 YAML 解析后判断 `app.cleanup == true`**（**禁止**裸 `grep` 字符串匹配），校验失败即让工作流失败。
2. 预置 yml：**不存在则新建**；已存在则**仅合并/追加 `app.cleanup`，不覆盖其它键**。
3. 注入的 `setup.bat`/`launch.bat`/`unregister.bat`/`readme.html` 放在**包根目录**（与 `brave-portable.exe` 同级）。
4. 上游产物为 **`.7z`**（已确认），用 7-Zip 解压。
5. 建议：Release 附 checksum；tag 对齐上游版本号。

## 13. 与替代方案对比与取舍

| 方案 | 做法 | 优点 | 缺点 | 取舍 |
|---|---|---|---|---|
| **甲（本方案）** | 外部脚本注册 + 不改源码 | 零改源码、可逆、维护成本低、与上游零偏离 | 自愈仅覆盖桌面快捷方式、bat 闪窗、需用户手动步骤、AV 误伤面 | **采纳**：与“源码仅作参考”的硬约束一致 |
| 乙（fork 内建） | 改 `main.go`，注册/自检/自愈进启动器 | 自愈覆盖所有启动、无闪窗、逻辑集中 | 需维护 fork、合并成本 | 排除（违反不修改源码约束） |
| 丙（劫持 `brave.exe` 名） | 真实 exe 改名 + 桩占位 | 连内置“设为默认”也命中 | 动官方文件、递归/更新风险 | 排除（改官方文件） |
| 丁（DISM 关联 XML） | 映像级预置 | 企业批量 | 仅新用户/映像 | 排除（非个人场景） |

取舍依据：**“不修改源码”是本项目第一约束**，它直接决定采用方案甲，并接受其自愈覆盖不全、需 bat 引导的局限。

## 14. 用户操作规则（对外只讲这四条）

1. 解压后先运行 `setup.bat`（首次运行脚本）。
2. **不要**点 Brave 内部的“设为默认浏览器”。
3. 数据始终在 `data` 目录，复制整个文件夹即可带走。
4. 移动文件夹或换机器后，重跑一次 `setup.bat`（换机器还需**重新设一次默认浏览器**）。

## 15. 待核实 / 待决策项（已收口）

1. ~~上游产物格式~~ → **已确认 `.7z`**，工作流用 7-Zip 解压。
2. ~~中文/空格路径下 `reg add` 引号转义与 `chcp 65001`~~ → **已实测通过**（PowerShell .NET API 验证：空格路径 + `%1` 占位符 + 中文值均正确写入读回）。bat 侧写法见 §7 实现注记。
3. ~~`readme.html` 点击 `ms-settings:` 可达性~~ → **用户已确认**。
4. ~~脚本序号前缀~~ → **不加**。
5. ~~`FileAssociations`~~ → **写入**（声明 .htm/.html/.shtml/.xht/.xhtml → BravePortableHTML，仅入候选、不强制改默认）。
6. ~~`SHChangeNotify` 广播~~ → **不广播**（设置页每次打开重读注册表；广播需 PowerShell 调 API，收益低）。

## 16. 落地目录结构（新项目文件夹）

```
E:\brave-portable\brave-portable-bundle\
├─ DESIGN.md                     ; 本定稿
├─ README.md                     ; （可选）面向仓库读者
├─ .github\workflows\build.yml   ; 组装与发布
├─ config\
│   └─ brave-portable.yml        ; app.cleanup: true（预置）
└─ payload\                      ; 注入到发布包根目录的文件
    ├─ setup.bat
    ├─ launch.bat
    ├─ unregister.bat
    └─ readme.html
```

> 说明：`payload\*` 为随包分发的自定义文件；CI 在组装阶段把它们复制到解压后的 Brave Portable 包根目录。