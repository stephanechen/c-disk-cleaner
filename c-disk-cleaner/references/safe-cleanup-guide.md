# C盘安全清理知识库

> 本文档是操作层面的参考指南。软件路径识别请查阅 `software-registry.md`。

---

## 迁移安全原则

1. **永远使用"复制 + 目录联接"而非"移动"** —— 复制验证通过后再处理源文件
2. **保留 .bak 备份直到确认正常** —— 至少保留 7 天，确认应用和数据无异常后再删除
3. **在应用关闭状态下操作** —— 用任务管理器或 `Get-Process` 确认进程已退出
4. **验证文件数量一致** —— 复制后对比源和目标的文件数和总大小
5. **mklink /J 创建目录联接** —— 不要用符号链接（mklink /D），目录联接对应用透明

## 迁移回退方法

```powershell
# 1. 删除出问题的联接（仅删除联接本身，不删除目标数据）
cmd /c "rmdir '<联接路径>'"

# 2. 恢复备份
cmd /c "move '<备份路径>' '<原路径>'"
```

## robocopy 安全参数

```powershell
robocopy <源> <目标> /E /COPY:DAT /R:3 /W:5 /MT:8
```

| 参数 | 作用 |
|------|------|
| `/E` | 包含空子目录 |
| `/COPY:DAT` | 复制数据、属性、时间戳（不复制 NTFS 权限以免失败） |
| `/R:3` | 失败重试 3 次 |
| `/W:5` | 重试间隔 5 秒 |
| `/MT:8` | 8 线程并行（加速复制） |

## 系统清理命令速查

| 操作 | 命令/方法 | 预计释放 |
|------|-----------|----------|
| 磁盘清理(含系统文件) | `cleanmgr` → 清理系统文件 | 3-10 GB |
| 关闭系统休眠 | `powercfg /h off` | 4-16 GB（≈内存大小） |
| 调整虚拟内存 | 系统属性 → 高级 → 性能设置 → 高级 → 虚拟内存 | 自定义 |
| 删除 Windows 更新缓存 | 磁盘清理 → Windows 更新清理 | 2-8 GB |
| 清空回收站 | 右键回收站 → 清空 | 不定 |

## 手动安全的清理项

### 用户级
| 位置 | 说明 |
|------|------|
| `%TEMP%` (=`AppData\Local\Temp`) | 所有应用临时文件。安全删除 |
| `%LOCALAPPDATA%\npm-cache` | npm 缓存 |
| `%LOCALAPPDATA%\pip` | pip 缓存 |
| `%APPDATA%\Code\Cache` | VS Code 缓存 |
| `%APPDATA%\Code\CachedData` | VS Code 扩展缓存 |
| `%APPDATA%\Code\CrashDumps` | VS Code 崩溃日志 |
| `.gradle\caches` | Gradle 构建缓存 |

### 浏览器
| 位置 | 说明 |
|------|------|
| `%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache` | Edge 缓存 |
| `%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache` | Chrome 缓存 |
| `%APPDATA%\Mozilla\Firefox\Profiles\*\cache2` | Firefox 缓存 |

### 系统级
| 位置 | 说明 |
|------|------|
| `C:\Windows\Temp` | Windows 临时文件 |
| `C:\Windows\Logs` | 系统日志（CBS 日志可能很大） |
| `C:\Windows\Prefetch` | 预读取，不影响启动速度 |
| `C:\Windows\memory.dmp` | 蓝屏内存转储 |
| `C:\Windows\Minidump` | 小型蓝屏转储 |
| `C:\Windows\SoftwareDistribution\Download` | Windows 更新下载缓存 |

## 不建议手动操作

| 项目 | 正确方法 |
|------|----------|
| `C:\Windows\WinSxS` | `cleanmgr` 或 `DISM /cleanup-image` |
| `C:\Windows\System32` | 绝不删除 |
| `C:\Windows\SysWOW64` | 绝不删除 |
| `C:\Windows\assembly` | 绝不删除 |
| `C:\Windows\Installer` | 磁盘清理 |
| `C:\pagefile.sys` | 系统属性调整 |
| `C:\hiberfil.sys` | `powercfg /h off` |

## 不同用户类型处理建议

| 用户类型 | 常见大项 | 建议 |
|----------|----------|------|
| **普通办公用户** | 微信文件、WPS数据、浏览器缓存 | 迁移微信+清理缓存 = 释放20-40GB |
| **开发者** | npm/pip/Gradle/Maven、Docker、VS Code、IDE | 清理开发缓存 = 释放10-30GB |
| **设计师/视频编辑** | 剪映、Adobe、Blender 渲染缓存 | 清理渲染缓存 = 释放10-50GB |
| **游戏玩家** | Steam/Epic 游戏库 | 迁移游戏库到其他盘 |
| **学生** | 微信、浏览器、课程资料 | 迁移微信 + 清理缓存 |
