# 🧹 C 盘安全清理技能包

> 安全、可回退、跨机器适配的 Windows C 盘空间分析与清理工具包。
> **不删除任何文件**直到你明确确认。

[![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-blue)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-blue)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/license-MIT-green)](./LICENSE)

---

## 这是什么

一个 **Claude Code / Codex 技能包**，能够：

1. **扫描** C 盘所有大目录 → 自动识别 50+ 常见软件
2. **报告** 按安全等级分组（🟢 安全 / 🟡 需确认 / 🔴 系统）
3. **迁移** 大文件到 D/E/F 盘（复制 → 验证 → 目录联接，应用完全无感知）
4. **清理** 缓存和临时文件（预览后确认才删除）

**核心诉求：** 你的朋友/同事/家人的电脑 C 盘也满了，把这个包丢过去，自动识别他们电脑上的软件，不用你自己一个个找。

---

## 快速开始

### 安装

```bash
# 把整个文件夹复制到 skills 目录
cp -r c-disk-cleaner ~/.codex/skills/
```

或放在 Claude Code 的 skills 路径下（取决于你的配置）。

### 使用

打开 Claude Code，直接说：

```
扫描一下我的 C 盘
```

技能自动触发，生成报告后你可以说：

```
把微信迁移到 D 盘
清理所有浏览器缓存
关闭休眠释放空间
```

---

## ✨ 特性

| 特性 | 说明 |
|------|------|
| 🔍 **通用扫描引擎** | 不写死任何软件名，遍历所有用户目录，按大小排序 |
| 📦 **50+ 软件知识库** | 覆盖 IM / 办公 / 浏览器 / 开发 / 设计 / 游戏 / 云盘 / AI |
| 🛡️ **三级安全分级** | 🟢 安全（缓存）→ 🟡 需确认（用户数据）→ 🔴 系统（不碰） |
| 🔗 **目录联接迁移** | robocopy 复制 → 验证 → mklink /J 联接，应用无感知 |
| ⏪ **可回退** | 保留 .bak 备份，一键恢复 |
| 👥 **多用户适配** | 自动遍历所有 `C:\Users\*`，不管电脑上有几个账户 |
| 🧩 **可扩展** | 遇到未知软件 > 加入注册表 > 下次自动识别 |
| 👁️ **预览模式** | 所有清理脚本支持 `-WhatIf`，先看再删 |

---

## 🏗️ 架构：三层设计

```
┌──────────────────────────────────────────────────┐
│                  SKILL.md                         │
│            工作流程 + 安全规则                      │
│         (触发词、阶段控制、禁令)                    │
├──────────────────────────────────────────────────┤
│               scripts/                           │
│   scan-disk.ps1       通用扫描引擎                │
│   migrate-data.ps1    安全迁移引擎                │
│   safe-clean.ps1      安全清理引擎                │
│         ↕ 不写死任何软件路径 ↕                     │
├──────────────────────────────────────────────────┤
│             references/                           │
│   software-registry.md    ← 核心知识库 (50+软件)   │
│   safe-cleanup-guide.md   ← 安全知识库            │
│   custom-config-template.md ← 用户自定义模板      │
│         ↕ 跟软件生态一起成长 ↕                     │
└──────────────────────────────────────────────────┘
```

**关键设计决策：** 脚本是纯粹的扫描/迁移/清理引擎，不硬编码任何软件名。所有软件识别来自 `references/software-registry.md` 知识库。换一台电脑、换一批软件——只扩充注册表，脚本代码不用改。

---

## 🔒 安全保障

| 场景 | 保障措施 |
|------|----------|
| 迁移前 | 检查目标盘空间 → 确认应用已关闭 → 用户确认 |
| 迁移中 | robocopy 带重试 → 验证文件数与总大小 |
| 迁移后 | 原文件保留 .bak → 验证联接生效 → 应用测试后再删备份 |
| 清理前 | 预览要删的内容 → 标安全等级 → 用户确认 |
| 清理中 | 仅删除 🟢安全 标记目录 → 锁定的文件跳过不硬删 |
| 全局 | 不删 Windows 系统文件 / 不在应用运行时操作 / 不跳过备份 |

---

## 📦 已支持软件（50+）

| 分类 | 软件 |
|------|------|
| 💬 即时通讯 | 微信(个人版/工作版)、QQ、TIM、企业微信、钉钉、飞书、Telegram、Discord、Slack |
| 📄 办公 | WPS Office、WPS 云盘、MS Office、Notion、Obsidian、有道云笔记、印象笔记、Foxit |
| 🌐 浏览器 | Chrome、Edge、Firefox、QQ浏览器、360浏览器、搜狗浏览器、Brave、Opera |
| 🛠️ 开发工具 | npm、pip、Gradle、Maven、Docker、VS Code、JetBrains、Android SDK、Visual Studio、Cursor、Trae、CodeBuddy、微信开发者工具、Cargo、Go |
| 🎬 视频/设计 | 剪映、Adobe 全家桶、DaVinci Resolve、Blender、Figma、CorelDRAW、AutoCAD、OBS、B站 |
| 🎮 游戏 | Steam、Epic Games、Ubisoft、EA Games |
| ☁️ 云存储 | 百度网盘、阿里云盘、OneDrive、iCloud |
| 🎵 音乐 | 网易云音乐、QQ音乐、酷狗、酷我、Spotify |
| 🤖 AI 助手 | IMA、豆包 |
| 🖥️ OEM | 联想、戴尔、惠普等预装软件 |
| ⚙️ 系统 | Temp、WinSxS、休眠文件、虚拟内存、更新缓存 |

完整列表见 [software-registry.md](./references/software-registry.md)

---

## 📂 文件结构

```
c-disk-cleaner/
├── README.md                           ← 本文件
├── SKILL.md                            ← 技能定义（触发词、工作流、安全规则）
├── agents/
│   └── openai.yaml                     ← OpenAI/Codex 元数据
├── scripts/
│   ├── scan-disk.ps1                   ← C盘通用扫描引擎
│   ├── migrate-data.ps1                ← 安全迁移引擎
│   └── safe-clean.ps1                  ← 安全清理引擎
└── references/
    ├── software-registry.md            ← 50+软件路径注册表（核心知识库）
    ├── safe-cleanup-guide.md           ← 安全清理知识库
    └── custom-config-template.md       ← 用户自定义软件配置模板
```

---

## 🔧 直接运行脚本

不依赖 Claude Code 也可以直接运行 PowerShell 脚本：

### 扫描

```powershell
# 基本扫描（报告 >50MB 的目录）
.\scripts\scan-disk.ps1

# 深度扫描（对大未识别目录下探一层）
.\scripts\scan-disk.ps1 -DeepScan

# 自定义阈值
.\scripts\scan-disk.ps1 -MinSizeMB 100
```

### 安全清理（预览）

```powershell
# 预览所有安全清理项（不删除）
.\scripts\safe-clean.ps1 -WhatIf

# 只清理浏览器缓存（预览）
.\scripts\safe-clean.ps1 -Target browsers -WhatIf

# 实际清理临时文件
.\scripts\safe-clean.ps1 -Target temp

# 清理所有安全项
.\scripts\safe-clean.ps1 -Target all
```

### 安全迁移（预览）

```powershell
# 预览迁移操作（不执行）
.\scripts\migrate-data.ps1 -SourcePath "C:\Users\<用户名>\xwechat_files" -DestDrive D -AppProcess "WeChatAppEx" -WhatIf

# 执行迁移
.\scripts\migrate-data.ps1 -SourcePath "C:\Users\<用户名>\xwechat_files" -DestDrive D -AppProcess "WeChatAppEx"
```

---

## 🧩 添加你的专属软件

如果你的软件不在知识库中，有两种方式：

### 方式一：临时告知 AI

扫描后，AI 会列出"未识别目录"。直接告诉 AI：
> "C:\Users\xxx\AppData\Roaming\MyApp 是我的行业软件，可以清理缓存"

### 方式二：永久加入配置

编辑 `references/custom-config-template.md`，按格式添加：

```yaml
custom_software:
  - name: "我公司的 OA 系统"
    paths:
      - "AppData\\Roaming\\CompanyOA"
    safety: caution
    action: migrate
    note: "OA系统聊天记录，建议迁移到D盘"
    category: "公司软件"
```

### 方式三：贡献回知识库

如果是常见软件，欢迎提 PR 到 `references/software-registry.md` 对应分类下：

```markdown
| 新软件名 | `相对路径\到\数据` | 🟡 | 迁移 | 简要说明 |
```

---

## ❓ FAQ

### Q: 迁移后微信/软件打不开了怎么办？

A: 有 `.bak` 备份。回退命令：
```powershell
cmd /c "rmdir '<联接路径>'"
cmd /c "move '<联接路径>.bak' '<原路径>'"
```

### Q: 会删我的聊天记录吗？

A: 不会。迁移是"复制到 D 盘 → 建联接"的方式，数据完整保留。清理只删 🟢安全 标记的缓存目录，不动用户数据。

### Q: 为什么不用"移动"而用"复制+联接"？

A: 迁移过程分两步独立操作——先完整复制并验证，通过后再建联接。如果复制中途断电，源数据完好无损。直接移动的话，中断可能导致数据不完整。

### Q: 对其他用户目录也有权限扫描吗？

A: 扫描引擎用 `-ErrorAction SilentlyContinue`，没权限的目录会静默跳过，不会报错也不会越权。

### Q: 为什么不用符号链接？

A: 符号链接（`mklink /D`）在某些场景下对应用不可见。目录联接（`mklink /J`）对应用完全透明，所有文件读写自动落在目标盘。

### Q: 能不能支持 macOS / Linux？

A: 当前版本仅支持 Windows。核心思路（通用扫描 + 知识库匹配 + 符号链接迁移）可移植，欢迎贡献。

---

## 📜 许可

MIT License

---

## 🤝 贡献

如果你发现了新的常用软件值得加入注册表，或脚本有改进建议，欢迎：

1. Fork 这个仓库
2. 编辑 `references/software-registry.md` 或相关脚本
3. 提 PR

每个条目格式：

```markdown
| 软件名 | `相对路径` | 🟢/🟡/🔴 | clean/migrate/manual | 备注说明 |
```
