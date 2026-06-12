# C盘安全清理知识库

## 安全可清理（不影响使用）

### 开发缓存
| 路径 | 清理命令 |
|------|----------|
| `%LOCALAPPDATA%\npm-cache` | `npm cache clean --force` |
| `%LOCALAPPDATA%\pip` | `pip cache purge` |
| `%APPDATA%\npm` | npm 全局缓存，可删 |
| `.chromium-browser-snapshots` | Playwright/Puppeteer 快照 |

### 系统临时文件
| 路径 | 说明 |
|------|------|
| `%TEMP%` | 用户临时文件 |
| `C:\Windows\Temp` | 系统临时文件 |
| `C:\Windows\Prefetch` | 预读取（可安全清理） |
| `C:\Windows\SoftwareDistribution\Download` | Windows 更新下载缓存 |

### 软件缓存
| 路径 | 说明 |
|------|------|
| `%LOCALAPPDATA%\JianyingPro\User Data\Cache` | 剪映渲染缓存 |
| Edge/Chrome `User Data\Default\Cache` | 浏览器缓存 |
| `%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache` | Edge 缓存 |

## 可迁移（建议迁移到其他盘）

| 路径 | 说明 | 迁移方式 |
|------|------|----------|
| `xwechat_files` | 微信工作版数据 | 复制+目录联接 |
| `Documents\WeChat Files` | 微信个人版数据 | 复制+目录联接 |
| `WPSDrive` | WPS 云盘同步 | 复制+目录联接 |
| `AppData\Roaming\kingsoft\wps` | WPS 云备份 | 清理或迁移 |

## 不建议手动清理（用系统工具）

| 路径 | 说明 | 工具 |
|------|------|------|
| `C:\Windows\WinSxS` | 组件库 | `cleanmgr` 磁盘清理 |
| `C:\hiberfil.sys` | 休眠文件 | `powercfg /h off` |
| `C:\pagefile.sys` | 虚拟内存 | 系统属性调整 |
| `C:\Windows\Installer` | 安装包 | 磁盘清理 |

## 迁移安全原则

1. 永远使用"复制+联接"而非"移动"
2. 保留 .bak 备份直到确认正常
3. 在应用关闭状态下操作
4. 验证文件数量一致
5. mklink /J 创建目录联接（非符号链接）

## robocopy 安全参数

```
robocopy 源 目标 /E /COPY:DAT /R:3 /W:5 /MT:8
```
- /E: 包含空子目录
- /COPY:DAT: 复制数据、属性、时间戳（不复制权限避免失败）
- /R:3: 失败重试3次
- /W:5: 重试间隔5秒
- /MT:8: 8线程并行
