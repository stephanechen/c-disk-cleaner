# 软件路径注册表

> 本文档是技能包的核心知识库。扫描引擎通过此注册表识别各软件的数据目录并给出处理建议。
> 路径均为相对于 `C:\Users\<用户名>\` 的相对路径（除非标注为绝对路径）。
> 
> **贡献指南：** 找到新的常用软件？按照表格格式添加一行即可。欢迎 PR。

---

## 即时通讯

| 软件 | 路径模式 | 安全 | 操作 | 备注 |
|------|----------|------|------|------|
| 微信(个人版) | `Documents\WeChat Files` | 🟡 | 迁移 | 聊天记录、文件、图片、视频 |
| 微信(工作版) | `xwechat_files` | 🟡 | 迁移 | 企业微信数据，含大量文件 |
| QQ | `AppData\Roaming\Tencent\QQ` | 🟡 | 清理缓存 | 图片/文件缓存可清理 |
| QQ | `Documents\Tencent Files` | 🟡 | 迁移 | QQ 接收的文件 |
| TIM | `Documents\TIM` | 🟡 | 迁移 | 腾讯 TIM 数据 |
| 企业微信 | `AppData\Roaming\WXWork` | 🟡 | 清理缓存 | 企业微信缓存 |
| 钉钉 | `AppData\Roaming\DingTalk` | 🟡 | 清理缓存 | 钉钉缓存文件 |
| 飞书 | `AppData\Roaming\Lark` | 🟡 | 清理缓存 | 飞书缓存/日志 |
| Telegram | `AppData\Roaming\Telegram Desktop` | 🟡 | 清理缓存 | 缓存可删，注意保存登录 |
| Discord | `AppData\Roaming\discord` | 🟢 | 清理缓存 | 纯缓存，安全清理 |
| Slack | `AppData\Local\slack` | 🟢 | 清理缓存 | 纯缓存 |

---

## 办公软件

| 软件 | 路径模式 | 安全 | 操作 | 备注 |
|------|----------|------|------|------|
| WPS Office | `AppData\Roaming\kingsoft\office6` | 🟡 | 清理缓存 | 本地缓存与模板 |
| WPS 云备份 | `AppData\Roaming\kingsoft\wps` | 🟡 | 清理 | 云备份历史版本，可清 |
| WPS 云盘 | `WPSDrive` | 🟡 | 迁移 | WPS 云盘本地同步目录 |
| Microsoft Office | `AppData\Local\Microsoft\Office` | 🟢 | 清理缓存 | Office 缓存 |
| Microsoft Office | `AppData\Roaming\Microsoft\Office` | 🟢 | 清理缓存 | Office 最近文件等 |
| Notion | `AppData\Local\Programs\Notion` | 🟢 | 清理缓存 | Electron 应用缓存 |
| Obsidian | `AppData\Local\obsidian` | 🟢 | 清理缓存 | 插件缓存 |
| 有道云笔记 | `AppData\Local\youdao` | 🟡 | 清理缓存 | 有道笔记缓存 |
| 印象笔记 | `AppData\Local\Evernote` | 🟡 | 清理缓存 | 印象笔记本地缓存 |
| 语雀 | `AppData\Local\yuque` | 🟢 | 清理缓存 | 语雀桌面端缓存 |
| Adobe Acrobat | `AppData\Local\Adobe\Acrobat` | 🟢 | 清理缓存 | PDF 阅读器缓存 |
| Foxit PDF | `AppData\Roaming\Foxit Software` | 🟢 | 清理缓存 | 福昕 PDF 缓存 |

---

## 浏览器

| 软件 | 路径模式 | 安全 | 操作 | 备注 |
|------|----------|------|------|------|
| Google Chrome | `AppData\Local\Google\Chrome\User Data` | 🟢 | 清理缓存 | 删除 Default\Cache 即可 |
| Microsoft Edge | `AppData\Local\Microsoft\Edge\User Data` | 🟢 | 清理缓存 | 删除 Default\Cache 即可 |
| Firefox | `AppData\Roaming\Mozilla\Firefox` | 🟢 | 清理缓存 | 清理 Profiles\*\cache2 |
| QQ浏览器 | `AppData\Local\Tencent\QQBrowser` | 🟢 | 清理缓存 | 腾讯浏览器缓存 |
| 360浏览器 | `AppData\Local\360Chrome` | 🟢 | 清理缓存 | 360浏览器 |
| 360极速浏览器 | `AppData\Local\360Browser` | 🟢 | 清理缓存 | 360极速版 |
| 搜狗浏览器 | `AppData\Local\SogouExplorer` | 🟢 | 清理缓存 | 搜狗浏览器 |
| Brave | `AppData\Local\BraveSoftware` | 🟢 | 清理缓存 | 隐私浏览器 |
| Opera | `AppData\Roaming\Opera Software` | 🟢 | 清理缓存 | Opera 缓存 |

---

## 开发工具

| 软件 | 路径模式 | 安全 | 操作 | 备注 |
|------|----------|------|------|------|
| npm 缓存 | `AppData\Local\npm-cache` | 🟢 | 清理 | `npm cache clean --force` |
| npm 全局 | `AppData\Roaming\npm` | 🟢 | 清理 | 可清理后重新全局安装 |
| pip 缓存 | `AppData\Local\pip` | 🟢 | 清理 | `pip cache purge` |
| Gradle | `.gradle` | 🟢 | 清理缓存 | Gradle 构建缓存 |
| Maven | `.m2\repository` | 🟢 | 清理缓存 | Maven 本地仓库 |
| Docker Desktop | `AppData\Local\Docker` | 🟡 | 迁移 | Docker 镜像与容器数据 |
| VS Code 数据 | `AppData\Roaming\Code` | 🟡 | 清理缓存 | 扩展与缓存，可清理Cache子目录 |
| VS Code 程序 | `AppData\Local\Programs\Microsoft VS Code` | 🟡 | 清理缓存 | 更新缓存 |
| JetBrains IDE | `AppData\Local\JetBrains` | 🟡 | 清理缓存 | IDEA/PyCharm/WebStorm 缓存 |
| JetBrains IDE | `AppData\Roaming\JetBrains` | 🟡 | 清理缓存 | IDE 配置与插件 |
| Android Studio | `AppData\Local\Android` | 🟡 | 迁移 | Android SDK与模拟器 |
| Visual Studio | `AppData\Local\Microsoft\VisualStudio` | 🟡 | 清理缓存 | VS 组件缓存 |
| Cursor | `AppData\Roaming\Cursor` | 🟡 | 清理缓存 | Cursor 编辑器缓存 |
| Trae | `AppData\Roaming\Trae CN` | 🟡 | 清理缓存 | Trae 编辑器 |
| Trae Solo | `AppData\Roaming\TRAE SOLO CN` | 🟡 | 清理缓存 | Trae Solo 编辑器 |
| CodeBuddy | `AppData\Roaming\CodeBuddy CN` | 🟡 | 清理缓存 | CodeBuddy 编辑器 |
| Chromium 快照 | `.chromium-browser-snapshots` | 🟢 | 清理 | Playwright/Puppeteer 快照 |
| WorkBuddy | `.workbuddy\binaries` | 🟢 | 清理 | WorkBuddy 二进制，可重装 |
| 微信开发者工具 | `AppData\Local\微信开发者工具` | 🟢 | 清理缓存 | 微信小程序开发工具缓存 |
| Unity | `AppData\Local\Unity` | 🟡 | 清理缓存 | Unity 引擎缓存 |
| Unreal Engine | `AppData\Local\UnrealEngine` | 🟡 | 迁移 | UE 缓存，大 |
| Rust (cargo) | `.cargo` | 🟡 | 清理缓存 | Cargo 注册表与构建缓存 |
| Go (pkg) | `go\pkg` | 🟢 | 清理缓存 | Go 模块缓存 |

---

## 视频 / 设计

| 软件 | 路径模式 | 安全 | 操作 | 备注 |
|------|----------|------|------|------|
| 剪映 | `AppData\Local\JianyingPro` | 🟡 | 清理缓存 | 删除 Cache 子目录，保留配置 |
| Adobe 通用 | `AppData\Roaming\Adobe` | 🟡 | 清理缓存 | Adobe 全家桶公共缓存 |
| Premiere Pro | `AppData\Roaming\Adobe\Premiere Pro` | 🟡 | 清理缓存 | 渲染缓存 |
| After Effects | `AppData\Roaming\Adobe\After Effects` | 🟡 | 清理缓存 | 磁盘缓存 |
| Photoshop | `AppData\Roaming\Adobe\Photoshop` | 🟡 | 清理缓存 | 暂存盘 |
| DaVinci Resolve | `AppData\Roaming\Blackmagic Design` | 🟡 | 清理缓存 | 达芬奇调色 |
| Blender | `AppData\Roaming\Blender Foundation` | 🟡 | 清理缓存 | 3D 渲染缓存 |
| Figma | `AppData\Local\Figma` | 🟢 | 清理 | 设计工具缓存 |
| CorelDRAW | `AppData\Roaming\Corel` | 🟡 | 清理缓存 | Corel 临时文件 |
| AutoCAD | `AppData\Local\Autodesk` | 🟡 | 清理缓存 | AutoCAD 缓存 |
| SketchUp | `AppData\Roaming\SketchUp` | 🟡 | 清理缓存 | SketchUp 插件/缓存 |
| OBS Studio | `AppData\Roaming\obs-studio` | 🟢 | 清理缓存 | 录屏/直播软件缓存 |
| 哔哩哔哩 | `AppData\Local\bilibili` | 🟢 | 清理缓存 | B站客户端缓存 |

---

## 游戏平台

| 软件 | 路径模式 | 安全 | 操作 | 备注 |
|------|----------|------|------|------|
| Steam | `Program Files (x86)\Steam` | 🟡 | 迁移 | Steam 库文件夹可改到其他盘 |
| Epic Games | `Program Files\Epic Games` | 🟡 | 迁移 | Epic 游戏 |
| Ubisoft Connect | `Program Files (x86)\Ubisoft` | 🟡 | 迁移 | 育碧游戏 |
| EA App | `Program Files\EA Games` | 🟡 | 迁移 | EA 游戏 |
| 腾讯手游助手 | `AppData\Local\Tencent\MobileGamePC` | 🟡 | 清理缓存 | 手游模拟器缓存 |
| 网易MuMu | `AppData\Local\MuMu` | 🟡 | 清理缓存 | MuMu 模拟器 |

---

## 云存储

| 软件 | 路径模式 | 安全 | 操作 | 备注 |
|------|----------|------|------|------|
| 百度网盘 | `AppData\Roaming\baidu` | 🟡 | 清理缓存 | 百度网盘缓存 |
| 百度网盘 | `AppData\Local\Baidu` | 🟡 | 清理缓存 | 百度网盘本地数据 |
| 阿里云盘 | `AppData\Local\aDrive` | 🟡 | 清理缓存 | 阿里云盘 |
| 夸克网盘 | `AppData\Local\quark` | 🟡 | 清理缓存 | 夸克网盘 |
| OneDrive | `OneDrive` | 🟡 | 迁移 | 微软云盘同步目录 |
| Dropbox | `Dropbox` | 🟡 | 迁移 | 同步目录 |
| iCloud | `AppData\Roaming\Apple Computer` | 🟡 | 清理缓存 | iCloud 缓存 |

---

## 音乐 / 娱乐

| 软件 | 路径模式 | 安全 | 操作 | 备注 |
|------|----------|------|------|------|
| 网易云音乐 | `AppData\Local\NetEase` | 🟢 | 清理缓存 | 网易云音乐缓存 |
| QQ音乐 | `AppData\Local\Tencent\QQMusic` | 🟢 | 清理缓存 | QQ音乐缓存 |
| 酷狗音乐 | `AppData\Local\KuGou` | 🟢 | 清理缓存 | Kugou 缓存 |
| 酷我音乐 | `AppData\Local\KwMusic` | 🟢 | 清理缓存 | 酷我缓存 |
| Spotify | `AppData\Local\Spotify` | 🟢 | 清理缓存 | 离线歌曲缓存 |
| 抖音 | `AppData\Local\douyin` | 🟢 | 清理缓存 | 抖音桌面版 |
| 斗鱼 | `AppData\Roaming\Douyu` | 🟢 | 清理缓存 | 斗鱼直播 |

---

## 系统与工具（绝对路径）

| 项目 | 路径 | 安全 | 操作 | 备注 |
|------|------|------|------|------|
| 用户临时文件 | `C:\Users\<user>\AppData\Local\Temp` | 🟢 | 清理 | 所有应用临时文件 |
| 系统临时文件 | `C:\Windows\Temp` | 🟢 | 清理 | Windows 临时文件 |
| Windows 更新缓存 | `C:\Windows\SoftwareDistribution\Download` | 🟡 | 磁盘清理 | 用 cleanmgr 执行 |
| 系统组件库 | `C:\Windows\WinSxS` | 🔴 | 磁盘清理 | Windows 组件存储 |
| Windows 日志 | `C:\Windows\Logs` | 🟢 | 清理 | 系统日志文件 |
| 预读取 | `C:\Windows\Prefetch` | 🟢 | 清理 | 启动优化缓存 |
| Windows Installer | `C:\Windows\Installer` | 🔴 | 磁盘清理 | 安装包缓存 |
| 回收站 | `C:\$Recycle.Bin` | 🟢 | 清空 | 清空回收站 |
| 休眠文件 | `C:\hiberfil.sys` | 🔴 | 关闭休眠 | `powercfg /h off` 释放 4-16GB |
| 虚拟内存 | `C:\pagefile.sys` | 🔴 | 调整大小 | 系统属性 → 高级 → 虚拟内存 |
| 系统错误转储 | `C:\Windows\memory.dmp` | 🟢 | 清理 | 蓝屏日志（可删） |
| 系统错误转储 | `C:\Windows\Minidump` | 🟢 | 清理 | 小型转储文件 |

---

## 硬件厂商工具

| 软件 | 路径模式 | 安全 | 操作 | 备注 |
|------|----------|------|------|------|
| 联想软件 | `AppData\Local\Lenovo` | 🟡 | 清理 | 联想预装软件数据 |
| 联想软件 | `ProgramData\Lenovo` | 🟡 | 清理 | 联想驱动备份 |
| 戴尔软件 | `ProgramData\Dell` | 🟡 | 清理 | 戴尔预装软件 |
| 惠普软件 | `ProgramData\HP` | 🟡 | 清理 | HP 预装软件 |
| 华硕软件 | `ProgramData\ASUS` | 🟡 | 清理 | 华硕预装软件 |
| 华为电脑管家 | `AppData\Local\Huawei` | 🟡 | 清理缓存 | 华为电脑管家 |

---

## 输入法与远程工具

| 软件 | 路径模式 | 安全 | 操作 | 备注 |
|------|----------|------|------|------|
| 搜狗输入法 | `AppData\LocalLow\SogouPY` | 🟢 | 清理缓存 | 词库同步缓存 |
| 搜狗输入法 | `AppData\LocalLow\SogouWB` | 🟢 | 清理缓存 | 五笔版 |
| 百度输入法 | `AppData\Local\baidu` | 🟢 | 清理缓存 | 百度输入法缓存 |
| 讯飞输入法 | `AppData\Local\iFlyTek` | 🟢 | 清理缓存 | 讯飞输入法 |
| 向日葵 | `AppData\Roaming\Sunlogin` | 🟢 | 清理缓存 | 远程控制 |
| AnyDesk | `AppData\Roaming\AnyDesk` | 🟢 | 清理缓存 | 远程桌面 |
| TeamViewer | `AppData\Roaming\TeamViewer` | 🟢 | 清理缓存 | 远程控制 |

---

## AI 助手

| 软件 | 路径模式 | 安全 | 操作 | 备注 |
|------|----------|------|------|------|
| IMA 助手 | `AppData\Local\ima.copilot` | 🟢 | 清理缓存 | IMA Copilot |
| 豆包 | `AppData\Local\Doubao` | 🟢 | 清理缓存 | 豆包桌面端 |
| 通义千问 | `AppData\Local\tongyi` | 🟢 | 清理缓存 | 通义千问 |
| Kimi | `AppData\Local\kimi` | 🟢 | 清理缓存 | Moonshot Kimi |
| 秘塔AI | `AppData\Local\metaso` | 🟢 | 清理缓存 | 秘塔搜索 |
| ChatGPT | `AppData\Local\ChatGPT` | 🟢 | 清理缓存 | OpenAI ChatGPT 桌面端 |
| Copilot | `AppData\Local\Microsoft Copilot` | 🟢 | 清理缓存 | 微软 Copilot |

---

## 如何新增软件条目

在对应分类的表格中添加一行：

```markdown
| 新软件名 | `相对路径\到\数据目录` | 🟡 | 迁移 | 简要说明 |
```

路径相对于 `C:\Users\<用户名>\`。安全等级：`🟢` 纯缓存 / `🟡` 用户数据需确认 / `🔴` 系统文件。

新增后同步更新 `scripts/scan-disk.ps1` 中的 `$SoftwareRegistry` 数组。
