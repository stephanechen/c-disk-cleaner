<#
.SYNOPSIS
    C盘存储通用扫描引擎
.DESCRIPTION
    遍历C盘关键位置，基于软件注册表知识库识别各目录归属，
    生成按安全等级分组的占用报告。
    不硬编码任何软件路径 —— 所有识别来自 $SoftwareRegistry。
    兼容 ConstrainedLanguage 模式，所有操作只读。
.PARAMETER MinSizeMB
    最小报告阈值(MB)，默认50
.PARAMETER DeepScan
    对大而未识别的目录进行二级深度扫描
.EXAMPLE
    .\scan-disk.ps1
    .\scan-disk.ps1 -DeepScan
    .\scan-disk.ps1 -MinSizeMB 100
#>

param(
    [int]$MinSizeMB = 50,
    [switch]$DeepScan
)

$ErrorActionPreference = 'SilentlyContinue'

# ============================================================
# 软件路径注册表（与 references/software-registry.md 同步扩充）
# ============================================================
$SoftwareRegistry = @(
    # === 即时通讯 ===
    @{Name='微信(个人版)'; Pattern='Documents\WeChat Files'; Safety='caution'; Action='migrate'; Category='即时通讯'; Note='微信聊天记录与文件'}
    @{Name='微信(工作版)'; Pattern='xwechat_files'; Safety='caution'; Action='migrate'; Category='即时通讯'; Note='微信工作版数据'}
    @{Name='QQ 数据'; Pattern='AppData\Roaming\Tencent\QQ'; Safety='caution'; Action='clean-cache'; Category='即时通讯'; Note='QQ图片/文件缓存'}
    @{Name='QQ 接收文件'; Pattern='Documents\Tencent Files'; Safety='caution'; Action='migrate'; Category='即时通讯'; Note='QQ接收的文件'}
    @{Name='TIM'; Pattern='Documents\TIM'; Safety='caution'; Action='migrate'; Category='即时通讯'; Note='腾讯TIM数据'}
    @{Name='企业微信'; Pattern='AppData\Roaming\WXWork'; Safety='caution'; Action='clean-cache'; Category='即时通讯'; Note='企业微信缓存'}
    @{Name='钉钉'; Pattern='AppData\Roaming\DingTalk'; Safety='caution'; Action='clean-cache'; Category='即时通讯'; Note='钉钉缓存'}
    @{Name='飞书'; Pattern='AppData\Roaming\Lark'; Safety='caution'; Action='clean-cache'; Category='即时通讯'; Note='飞书缓存'}
    @{Name='Telegram'; Pattern='AppData\Roaming\Telegram Desktop'; Safety='caution'; Action='clean-cache'; Category='即时通讯'; Note='Telegram缓存'}
    @{Name='Discord'; Pattern='AppData\Roaming\discord'; Safety='safe'; Action='clean'; Category='即时通讯'; Note='Discord缓存'}

    # === 办公软件 ===
    @{Name='WPS Office'; Pattern='AppData\Roaming\kingsoft\office6'; Safety='caution'; Action='clean-cache'; Category='办公软件'; Note='WPS本地缓存与模板'}
    @{Name='WPS 云备份'; Pattern='AppData\Roaming\kingsoft\wps'; Safety='caution'; Action='clean'; Category='办公软件'; Note='WPS云备份历史版本'}
    @{Name='WPS PDF'; Pattern='AppData\Roaming\kingsoft\PDF'; Safety='safe'; Action='clean'; Category='办公软件'; Note='WPS PDF数据'}
    @{Name='WPS 云盘'; Pattern='WPSDrive'; Safety='caution'; Action='migrate'; Category='办公软件'; Note='WPS云盘本地同步'}
    @{Name='MS Office 缓存'; Pattern='AppData\Local\Microsoft\Office'; Safety='safe'; Action='clean'; Category='办公软件'; Note='Office缓存'}
    @{Name='MS Office 最近文件'; Pattern='AppData\Roaming\Microsoft\Office'; Safety='safe'; Action='clean'; Category='办公软件'; Note='Office最近文件列表'}
    @{Name='Notion'; Pattern='AppData\Local\Programs\Notion'; Safety='safe'; Action='clean'; Category='办公软件'; Note='Notion桌面端缓存'}
    @{Name='Obsidian'; Pattern='AppData\Local\obsidian'; Safety='safe'; Action='clean'; Category='办公软件'; Note='Obsidian插件缓存'}
    @{Name='有道云笔记'; Pattern='AppData\Local\youdao'; Safety='caution'; Action='clean-cache'; Category='办公软件'; Note='有道笔记缓存'}
    @{Name='印象笔记'; Pattern='AppData\Local\Evernote'; Safety='caution'; Action='clean-cache'; Category='办公软件'; Note='印象笔记缓存'}
    @{Name='Foxit PDF'; Pattern='AppData\Roaming\Foxit Software'; Safety='safe'; Action='clean'; Category='办公软件'; Note='福昕PDF缓存'}

    # === 浏览器 ===
    @{Name='Chrome'; Pattern='AppData\Local\Google\Chrome'; Safety='safe'; Action='clean'; Category='浏览器'; Note='Chrome浏览器缓存'}
    @{Name='Edge'; Pattern='AppData\Local\Microsoft\Edge'; Safety='safe'; Action='clean'; Category='浏览器'; Note='Edge浏览器缓存'}
    @{Name='Firefox'; Pattern='AppData\Roaming\Mozilla\Firefox'; Safety='safe'; Action='clean'; Category='浏览器'; Note='Firefox缓存'}
    @{Name='QQ浏览器'; Pattern='AppData\Local\Tencent\QQBrowser'; Safety='safe'; Action='clean'; Category='浏览器'; Note='QQ浏览器缓存'}
    @{Name='360浏览器'; Pattern='AppData\Local\360Chrome'; Safety='safe'; Action='clean'; Category='浏览器'; Note='360浏览器'}
    @{Name='360极速浏览器'; Pattern='AppData\Local\360Browser'; Safety='safe'; Action='clean'; Category='浏览器'; Note='360极速浏览器'}
    @{Name='搜狗浏览器'; Pattern='AppData\Local\SogouExplorer'; Safety='safe'; Action='clean'; Category='浏览器'; Note='搜狗浏览器'}
    @{Name='Brave'; Pattern='AppData\Local\BraveSoftware'; Safety='safe'; Action='clean'; Category='浏览器'; Note='Brave浏览器'}
    @{Name='Opera'; Pattern='AppData\Roaming\Opera Software'; Safety='safe'; Action='clean'; Category='浏览器'; Note='Opera缓存'}

    # === 开发工具 ===
    @{Name='npm 缓存'; Pattern='AppData\Local\npm-cache'; Safety='safe'; Action='clean'; Category='开发工具'; Note='npm缓存'}
    @{Name='npm 全局'; Pattern='AppData\Roaming\npm'; Safety='safe'; Action='clean'; Category='开发工具'; Note='npm全局包'}
    @{Name='pip 缓存'; Pattern='AppData\Local\pip'; Safety='safe'; Action='clean'; Category='开发工具'; Note='pip缓存，pip cache purge'}
    @{Name='Gradle'; Pattern='.gradle'; Safety='safe'; Action='clean'; Category='开发工具'; Note='Gradle构建缓存'}
    @{Name='Maven'; Pattern='.m2'; Safety='safe'; Action='clean'; Category='开发工具'; Note='Maven本地仓库'}
    @{Name='Docker Desktop'; Pattern='AppData\Local\Docker'; Safety='caution'; Action='migrate'; Category='开发工具'; Note='Docker镜像与容器'}
    @{Name='VS Code 数据'; Pattern='AppData\Roaming\Code'; Safety='caution'; Action='clean-cache'; Category='开发工具'; Note='VS Code扩展与缓存'}
    @{Name='VS Code 程序'; Pattern='AppData\Local\Programs\Microsoft VS Code'; Safety='caution'; Action='clean-cache'; Category='开发工具'; Note='VS Code更新缓存'}
    @{Name='JetBrains IDE'; Pattern='AppData\Local\JetBrains'; Safety='caution'; Action='clean-cache'; Category='开发工具'; Note='IDEA/PyCharm/WS缓存'}
    @{Name='JetBrains 配置'; Pattern='AppData\Roaming\JetBrains'; Safety='caution'; Action='clean-cache'; Category='开发工具'; Note='IDE配置与插件'}
    @{Name='Android SDK'; Pattern='AppData\Local\Android'; Safety='caution'; Action='migrate'; Category='开发工具'; Note='Android SDK与模拟器'}
    @{Name='Visual Studio'; Pattern='AppData\Local\Microsoft\VisualStudio'; Safety='caution'; Action='clean-cache'; Category='开发工具'; Note='VS组件缓存'}
    @{Name='Cursor'; Pattern='AppData\Roaming\Cursor'; Safety='caution'; Action='clean-cache'; Category='开发工具'; Note='Cursor编辑器缓存'}
    @{Name='Trae'; Pattern='AppData\Roaming\Trae CN'; Safety='caution'; Action='clean-cache'; Category='开发工具'; Note='Trae编辑器'}
    @{Name='Trae Solo'; Pattern='AppData\Roaming\TRAE SOLO CN'; Safety='caution'; Action='clean-cache'; Category='开发工具'; Note='Trae Solo编辑器'}
    @{Name='CodeBuddy'; Pattern='AppData\Roaming\CodeBuddy CN'; Safety='caution'; Action='clean-cache'; Category='开发工具'; Note='CodeBuddy编辑器'}
    @{Name='Chromium 快照'; Pattern='.chromium-browser-snapshots'; Safety='safe'; Action='clean'; Category='开发工具'; Note='Playwright/Puppeteer'}
    @{Name='微信开发者工具'; Pattern='AppData\Local\微信开发者工具'; Safety='safe'; Action='clean'; Category='开发工具'; Note='小程序开发工具缓存'}
    @{Name='Cargo'; Pattern='.cargo'; Safety='caution'; Action='clean-cache'; Category='开发工具'; Note='Rust Cargo注册表'}
    @{Name='Go pkg'; Pattern='go\pkg'; Safety='safe'; Action='clean'; Category='开发工具'; Note='Go模块缓存'}

    # === 视频/设计 ===
    @{Name='剪映'; Pattern='AppData\Local\JianyingPro'; Safety='caution'; Action='clean-cache'; Category='视频设计'; Note='剪映渲染缓存'}
    @{Name='Adobe 通用'; Pattern='AppData\Roaming\Adobe'; Safety='caution'; Action='clean-cache'; Category='视频设计'; Note='Adobe全家桶缓存'}
    @{Name='Adobe Common'; Pattern='AppData\Local\Adobe'; Safety='caution'; Action='clean-cache'; Category='视频设计'; Note='Adobe通用缓存'}
    @{Name='DaVinci Resolve'; Pattern='AppData\Roaming\Blackmagic Design'; Safety='caution'; Action='clean-cache'; Category='视频设计'; Note='达芬奇缓存'}
    @{Name='Blender'; Pattern='AppData\Roaming\Blender Foundation'; Safety='caution'; Action='clean-cache'; Category='视频设计'; Note='Blender渲染缓存'}
    @{Name='Figma'; Pattern='AppData\Local\Figma'; Safety='safe'; Action='clean'; Category='视频设计'; Note='Figma缓存'}
    @{Name='CorelDRAW'; Pattern='AppData\Roaming\Corel'; Safety='caution'; Action='clean-cache'; Category='视频设计'; Note='CorelDRAW缓存'}
    @{Name='AutoCAD'; Pattern='AppData\Local\Autodesk'; Safety='caution'; Action='clean-cache'; Category='视频设计'; Note='AutoCAD缓存'}
    @{Name='OBS Studio'; Pattern='AppData\Roaming\obs-studio'; Safety='safe'; Action='clean'; Category='视频设计'; Note='OBS录屏缓存'}
    @{Name='哔哩哔哩'; Pattern='AppData\Local\bilibili'; Safety='safe'; Action='clean'; Category='视频设计'; Note='B站客户端缓存'}

    # === 游戏平台 ===
    @{Name='Steam'; Pattern='Program Files (x86)\Steam'; Safety='caution'; Action='migrate'; Category='游戏'; Note='Steam游戏平台'}
    @{Name='Epic Games'; Pattern='Program Files\Epic Games'; Safety='caution'; Action='migrate'; Category='游戏'; Note='Epic游戏'}
    @{Name='Ubisoft'; Pattern='Program Files (x86)\Ubisoft'; Safety='caution'; Action='migrate'; Category='游戏'; Note='育碧游戏'}
    @{Name='EA Games'; Pattern='Program Files\EA Games'; Safety='caution'; Action='migrate'; Category='游戏'; Note='EA游戏'}

    # === 云存储 ===
    @{Name='百度网盘'; Pattern='AppData\Roaming\baidu'; Safety='caution'; Action='clean-cache'; Category='云存储'; Note='百度网盘缓存'}
    @{Name='百度网盘数据'; Pattern='AppData\Local\Baidu'; Safety='caution'; Action='clean-cache'; Category='云存储'; Note='百度网盘本地数据'}
    @{Name='阿里云盘'; Pattern='AppData\Local\aDrive'; Safety='caution'; Action='clean-cache'; Category='云存储'; Note='阿里云盘缓存'}
    @{Name='OneDrive'; Pattern='OneDrive'; Safety='caution'; Action='migrate'; Category='云存储'; Note='OneDrive同步目录'}
    @{Name='iCloud'; Pattern='AppData\Roaming\Apple Computer'; Safety='caution'; Action='clean-cache'; Category='云存储'; Note='iCloud缓存'}

    # === 音乐/娱乐 ===
    @{Name='网易云音乐'; Pattern='AppData\Local\NetEase'; Safety='safe'; Action='clean'; Category='音乐娱乐'; Note='网易云缓存'}
    @{Name='QQ音乐'; Pattern='AppData\Local\Tencent\QQMusic'; Safety='safe'; Action='clean'; Category='音乐娱乐'; Note='QQ音乐缓存'}
    @{Name='酷狗音乐'; Pattern='AppData\Local\KuGou'; Safety='safe'; Action='clean'; Category='音乐娱乐'; Note='酷狗缓存'}
    @{Name='酷我音乐'; Pattern='AppData\Local\KwMusic'; Safety='safe'; Action='clean'; Category='音乐娱乐'; Note='酷我缓存'}
    @{Name='Spotify'; Pattern='AppData\Local\Spotify'; Safety='safe'; Action='clean'; Category='音乐娱乐'; Note='Spotify离线歌曲缓存'}

    # === 输入法/远程工具 ===
    @{Name='搜狗输入法'; Pattern='AppData\LocalLow\SogouPY'; Safety='safe'; Action='clean'; Category='输入法'; Note='搜狗拼音缓存'}
    @{Name='向日葵'; Pattern='AppData\Roaming\Sunlogin'; Safety='safe'; Action='clean'; Category='远程工具'; Note='向日葵缓存'}
    @{Name='AnyDesk'; Pattern='AppData\Roaming\AnyDesk'; Safety='safe'; Action='clean'; Category='远程工具'; Note='AnyDesk缓存'}
    @{Name='TeamViewer'; Pattern='AppData\Roaming\TeamViewer'; Safety='safe'; Action='clean'; Category='远程工具'; Note='TeamViewer缓存'}

    # === AI 助手 ===
    @{Name='IMA 助手'; Pattern='AppData\Local\ima.copilot'; Safety='safe'; Action='clean'; Category='AI助手'; Note='IMA Copilot'}
    @{Name='豆包'; Pattern='AppData\Local\Doubao'; Safety='safe'; Action='clean'; Category='AI助手'; Note='豆包桌面端'}

    # === 腾讯/kingsoft 兜底匹配（放最后，避免覆盖子分类） ===
    @{Name='腾讯通用数据'; Pattern='AppData\Roaming\Tencent'; Safety='caution'; Action='clean-cache'; Category='即时通讯'; Note='QQ/腾讯应用公共数据'}
    @{Name='腾讯本地数据'; Pattern='AppData\Local\Tencent'; Safety='caution'; Action='clean-cache'; Category='即时通讯'; Note='腾讯应用本地缓存'}
    @{Name='WPS 通用数据'; Pattern='AppData\Roaming\kingsoft'; Safety='caution'; Action='clean-cache'; Category='办公软件'; Note='WPS办公套件数据'}

    # === 系统(绝对路径匹配) ===
    @{Name='用户临时文件'; Pattern='[SYS:AppData\Local\Temp]'; Safety='safe'; Action='clean'; Category='系统'; Note='所有应用临时文件'}
    @{Name='系统临时文件'; Pattern='[SYS:C:\Windows\Temp]'; Safety='safe'; Action='clean'; Category='系统'; Note='Windows临时文件'}
    @{Name='Windows更新缓存'; Pattern='[SYS:C:\Windows\SoftwareDistribution]'; Safety='caution'; Action='disk-cleanup'; Category='系统'; Note='用cleanmgr清理'}
    @{Name='Windows组件库'; Pattern='[SYS:C:\Windows\WinSxS]'; Safety='system'; Action='disk-cleanup'; Category='系统'; Note='Windows组件存储'}
    @{Name='系统日志'; Pattern='[SYS:C:\Windows\Logs]'; Safety='safe'; Action='clean'; Category='系统'; Note='系统日志文件'}
    @{Name='预读取'; Pattern='[SYS:C:\Windows\Prefetch]'; Safety='safe'; Action='clean'; Category='系统'; Note='启动优化缓存'}
    @{Name='Installer缓存'; Pattern='[SYS:C:\Windows\Installer]'; Safety='system'; Action='disk-cleanup'; Category='系统'; Note='安装包缓存'}
    @{Name='休眠文件'; Pattern='[SYS:C:\hiberfil.sys]'; Safety='system'; Action='powercfg'; Category='系统'; Note='powercfg /h off 可释放4-16GB'}
    @{Name='虚拟内存'; Pattern='[SYS:C:\pagefile.sys]'; Safety='system'; Action='manual'; Category='系统'; Note='系统属性中调整大小'}
    @{Name='系统交换文件'; Pattern='[SYS:C:\swapfile.sys]'; Safety='system'; Action='manual'; Category='系统'; Note='UWP应用交换文件'}
    @{Name='内存转储'; Pattern='[SYS:C:\Windows\memory.dmp]'; Safety='safe'; Action='clean'; Category='系统'; Note='蓝屏错误转储(可删)'}
    @{Name='小型转储'; Pattern='[SYS:C:\Windows\Minidump]'; Safety='safe'; Action='clean'; Category='系统'; Note='小型蓝屏转储'}

    # === 硬件厂商 ===
    @{Name='联想软件'; Pattern='AppData\Local\Lenovo'; Safety='caution'; Action='clean-cache'; Category='OEM工具'; Note='联想预装软件数据'}
    @{Name='联想驱动'; Pattern='ProgramData\Lenovo'; Safety='caution'; Action='clean'; Category='OEM工具'; Note='联想驱动备份'}
    @{Name='戴尔软件'; Pattern='ProgramData\Dell'; Safety='caution'; Action='clean'; Category='OEM工具'; Note='戴尔预装软件'}
    @{Name='惠普软件'; Pattern='ProgramData\HP'; Safety='caution'; Action='clean'; Category='OEM工具'; Note='HP预装软件'}
)

# ============================================================
# 辅助函数
# ============================================================

function Get-DirSize {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return 0 }
    $size = (Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    return [int]($size / 1MB)
}

function Get-FileSizeMB {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return 0 }
    return [int]((Get-Item $Path -Force -ErrorAction SilentlyContinue).Length / 1MB)
}

function Match-Registry {
    param([string]$FullPath)
    foreach ($entry in $SoftwareRegistry) {
        $p = $entry.Pattern
        if ($p -match '^\[SYS:(.+)\]$') {
            if ($FullPath -eq $matches[1]) { return $entry }
        } else {
            $escaped = [regex]::Escape($p)
            if ($FullPath -match "C:\\Users\\.+?\\$escaped`$") { return $entry }
        }
    }
    return $null
}

function Format-Size {
    param([int]$SizeMB)
    if ($SizeMB -ge 1024) { return "$([math]::Round($SizeMB/1024,1)) GB" }
    return "$SizeMB MB"
}

$results = [System.Collections.ArrayList]::new()
$seen = @{}

function Add-Result {
    param(
        [string]$Category, [string]$Path, [int]$SizeMB,
        [string]$Software, [string]$Safety, [string]$Action, [string]$Note, [string]$User
    )
    if ($SizeMB -lt $MinSizeMB) { return }
    $key = $Path.ToLowerInvariant()
    if ($seen[$key]) { return }
    $seen[$key] = $true
    [void]$results.Add([PSCustomObject]@{
        Category = $Category; Path = $Path; SizeMB = $SizeMB
        SizeGB = [math]::Round($SizeMB/1024, 2); Software = $Software
        Safety = $Safety; Action = $Action; Note = $Note; UserName = $User
    })
}

# ============================================================
# 扫描
# ============================================================

$t0 = Get-Date
Write-Host ""
Write-Host "========================================"
Write-Host "  C盘存储通用扫描引擎"
Write-Host "========================================"
Write-Host " 时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host " 阈值: ${MinSizeMB} MB | 深度: $(if($DeepScan){'开'}else{'关'})"
Write-Host "========================================"
Write-Host ""

# C盘空闲
$fi = cmd /c 'dir C:\ /a 2>nul | findstr free'
$freeGB = 0
if ($fi -match '(\d[\d,]*) bytes free') {
    $freeGB = [math]::Round([long]($matches[1] -replace ',','') / 1GB, 1)
}
Write-Host "C盘可用: ${freeGB} GB`n"

# --- 根目录文件 ---
Write-Host "[扫描] C盘根目录..."
Get-ChildItem C:\ -Force -File -ErrorAction SilentlyContinue | ForEach-Object {
    $mb = [int]($_.Length / 1MB)
    if ($mb -lt 10) { return }
    $m = Match-Registry $_.FullName
    Add-Result -Category 'C盘根目录' -Path $_.FullName -SizeMB $mb `
        -Software $(if($m){$m.Name}else{'系统文件'}) `
        -Safety $(if($m){$m.Safety}else{'system'}) `
        -Action $(if($m){$m.Action}else{'manual'}) `
        -Note $(if($m){$m.Note}else{''}) -User ''
}

# --- 所有用户目录 ---
$allUsers = Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notin @('Public','Default','All Users','Default User') }

foreach ($ud in $allUsers) {
    $u = $ud.Name
    Write-Host "[扫描] C:\Users\$u ..."

    # 用户根目录（排除AppData）
    Get-ChildItem $ud.FullName -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'AppData' } | ForEach-Object {
        $mb = Get-DirSize $_.FullName
        $m = Match-Registry $_.FullName
        Add-Result -Category '用户目录' -Path $_.FullName -SizeMB $mb `
            -Software $(if($m){$m.Name}else{''}) `
            -Safety $(if($m){$m.Safety}else{'caution'}) `
            -Action $(if($m){$m.Action}else{''}) `
            -Note $(if($m){$m.Note}else{''}) -User $u
    }

    # AppData\Local
    $al = "$($ud.FullName)\AppData\Local"
    if (Test-Path $al) {
        Get-ChildItem $al -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $mb = Get-DirSize $_.FullName
            $m = Match-Registry $_.FullName
            Add-Result -Category 'AppData\Local' -Path $_.FullName -SizeMB $mb `
                -Software $(if($m){$m.Name}else{''}) `
                -Safety $(if($m){$m.Safety}else{'caution'}) `
                -Action $(if($m){$m.Action}else{''}) `
                -Note $(if($m){$m.Note}else{''}) -User $u
            if ($DeepScan -and $m -eq $null -and $mb -ge 1000) {
                Get-ChildItem $_.FullName -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                    $mb2 = Get-DirSize $_.FullName
                    $m2 = Match-Registry $_.FullName
                    Add-Result -Category 'AppData\Local(深)' -Path $_.FullName -SizeMB $mb2 `
                        -Software $(if($m2){$m2.Name}else{'未知'}) `
                        -Safety $(if($m2){$m2.Safety}else{'caution'}) `
                        -Action $(if($m2){$m2.Action}else{''}) `
                        -Note $(if($m2){$m2.Note}else{''}) -User $u
                }
            }
        }
    }

    # AppData\Roaming
    $ar = "$($ud.FullName)\AppData\Roaming"
    if (Test-Path $ar) {
        Get-ChildItem $ar -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $mb = Get-DirSize $_.FullName
            $m = Match-Registry $_.FullName
            Add-Result -Category 'AppData\Roaming' -Path $_.FullName -SizeMB $mb `
                -Software $(if($m){$m.Name}else{''}) `
                -Safety $(if($m){$m.Safety}else{'caution'}) `
                -Action $(if($m){$m.Action}else{''}) `
                -Note $(if($m){$m.Note}else{''}) -User $u
            if ($DeepScan -and $m -eq $null -and $mb -ge 1000) {
                Get-ChildItem $_.FullName -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                    $mb2 = Get-DirSize $_.FullName
                    $m2 = Match-Registry $_.FullName
                    Add-Result -Category 'AppData\Roaming(深)' -Path $_.FullName -SizeMB $mb2 `
                        -Software $(if($m2){$m2.Name}else{'未知'}) `
                        -Safety $(if($m2){$m2.Safety}else{'caution'}) `
                        -Action $(if($m2){$m2.Action}else{''}) `
                        -Note $(if($m2){$m2.Note}else{''}) -User $u
                }
            }
        }
    }

    # AppData\LocalLow
    $all = "$($ud.FullName)\AppData\LocalLow"
    if (Test-Path $all) {
        Get-ChildItem $all -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $mb = Get-DirSize $_.FullName
            $m = Match-Registry $_.FullName
            Add-Result -Category 'AppData\LocalLow' -Path $_.FullName -SizeMB $mb `
                -Software $(if($m){$m.Name}else{''}) `
                -Safety $(if($m){$m.Safety}else{'caution'}) `
                -Action $(if($m){$m.Action}else{''}) `
                -Note $(if($m){$m.Note}else{''}) -User $u
        }
    }

    # Documents 子目录
    $doc = "$($ud.FullName)\Documents"
    if (Test-Path $doc) {
        Get-ChildItem $doc -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $mb = Get-DirSize $_.FullName
            $m = Match-Registry $_.FullName
            Add-Result -Category 'Documents' -Path $_.FullName -SizeMB $mb `
                -Software $(if($m){$m.Name}else{''}) `
                -Safety $(if($m){$m.Safety}else{'caution'}) `
                -Action $(if($m){$m.Action}else{''}) `
                -Note $(if($m){$m.Note}else{''}) -User $u
        }
    }
}

# --- Program Files ---
Write-Host "[扫描] Program Files ..."
@('C:\Program Files','C:\Program Files (x86)') | ForEach-Object {
    Get-ChildItem $_ -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $mb = Get-DirSize $_.FullName
        $m = Match-Registry $_.FullName
        Add-Result -Category 'Program Files' -Path $_.FullName -SizeMB $mb `
            -Software $(if($m){$m.Name}else{''}) `
            -Safety $(if($m){$m.Safety}else{'caution'}) `
            -Action $(if($m){$m.Action}else{'manual'}) `
            -Note $(if($m){$m.Note}else{'不建议手动清理'}) -User ''
    }
}

# --- ProgramData ---
Write-Host "[扫描] ProgramData ..."
Get-ChildItem 'C:\ProgramData' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $mb = Get-DirSize $_.FullName
    $m = Match-Registry $_.FullName
    Add-Result -Category 'ProgramData' -Path $_.FullName -SizeMB $mb `
        -Software $(if($m){$m.Name}else{''}) `
        -Safety $(if($m){$m.Safety}else{'caution'}) `
        -Action $(if($m){$m.Action}else{''}) `
        -Note $(if($m){$m.Note}else{''}) -User ''
}

# --- Windows 关键目录 ---
Write-Host "[扫描] Windows ..."
@(
    'C:\Windows\WinSxS','C:\Windows\System32','C:\Windows\SysWOW64',
    'C:\Windows\SoftwareDistribution','C:\Windows\Temp','C:\Windows\Installer',
    'C:\Windows\Logs','C:\Windows\Prefetch','C:\Windows\assembly',
    'C:\Windows\Microsoft.NET','C:\Windows\Minidump'
) | ForEach-Object {
    if (-not (Test-Path $_)) { return }
    $mb = Get-DirSize $_
    $m = Match-Registry $_
    Add-Result -Category 'Windows' -Path $_ -SizeMB $mb `
        -Software $(if($m){$m.Name}else{''}) `
        -Safety $(if($m){$m.Safety}else{'system'}) `
        -Action $(if($m){$m.Action}else{'manual'}) `
        -Note $(if($m){$m.Note}else{'系统目录'}) -User ''
}

# 特殊系统文件
@('C:\hiberfil.sys','C:\pagefile.sys','C:\swapfile.sys','C:\Windows\memory.dmp') | ForEach-Object {
    $mb = Get-FileSizeMB $_
    if ($mb -eq 0) { return }
    $m = Match-Registry $_
    Add-Result -Category '系统文件' -Path $_ -SizeMB $mb `
        -Software $(if($m){$m.Name}else{''}) `
        -Safety $(if($m){$m.Safety}else{'system'}) `
        -Action $(if($m){$m.Action}else{'manual'}) `
        -Note $(if($m){$m.Note}else{''}) -User ''
}

# ============================================================
# 输出报告
# ============================================================

$dur = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)
$safe   = $results | Where-Object { $_.Safety -eq 'safe' }
$caution = $results | Where-Object { $_.Safety -eq 'caution' }
$system  = $results | Where-Object { $_.Safety -eq 'system' }
$swDetected = ($results | Where-Object { $_.Software -ne '' } | Select-Object -ExpandProperty Software -Unique | Sort-Object)

Write-Host ""
Write-Host "========================================"
Write-Host "  扫描完成 (${dur}s) | $($results.Count)项 | $($swDetected.Count)款软件"
Write-Host "========================================"

Write-Host "`n=== 已识别软件 ==="
$swDetected | ForEach-Object { Write-Host "  - $_" }

Write-Host "`n========== 🟢 安全可清理 =========="
if ($safe.Count) {
    $safe | Sort-Object SizeMB -Descending | Format-Table `
        @{N='软件';E={$_.Software};W=18}, @{N='大小';E={Format-Size $_.SizeMB};A='right';W=10},
        @{N='路径';E={$_.Path};W=70} -AutoSize -Wrap
} else { Write-Host "(无)" }

Write-Host "`n========== 🟡 需确认后操作 =========="
if ($caution.Count) {
    $caution | Sort-Object SizeMB -Descending | Format-Table `
        @{N='软件';E={$_.Software};W=20}, @{N='大小';E={Format-Size $_.SizeMB};A='right';W=10},
        @{N='操作';E={$_.Action};W=12}, @{N='用户';E={$_.UserName};W=10},
        @{N='路径';E={$_.Path};W=65} -AutoSize -Wrap
} else { Write-Host "(无)" }

Write-Host "`n========== 🔴 系统文件 =========="
if ($system.Count) {
    $system | Sort-Object SizeMB -Descending | Format-Table `
        @{N='文件';E={$_.Software};W=18}, @{N='大小';E={Format-Size $_.SizeMB};A='right';W=10},
        @{N='建议';E={$_.Note};W=45}, @{N='路径';E={$_.Path};W=55} -AutoSize -Wrap
} else { Write-Host "(无)" }

$unknown = $results | Where-Object { $_.Software -eq '' -and $_.Safety -ne 'system' }
if ($unknown.Count) {
    Write-Host "`n========== ⚠️ 未识别目录 =========="
    Write-Host "以下目录未被知识库匹配，请确认用途后决定处理方式:`n"
    $unknown | Sort-Object SizeMB -Descending | Format-Table `
        @{N='大小';E={Format-Size $_.SizeMB};A='right';W=10},
        @{N='路径';E={$_.Path};W=85} -AutoSize -Wrap
}

$ts = ($safe | Measure-Object -Property SizeMB -Sum).Sum
$tc = ($caution | Measure-Object -Property SizeMB -Sum).Sum
$ty = ($system | Measure-Object -Property SizeMB -Sum).Sum
Write-Host ""
Write-Host "========================================"
Write-Host "  统计: 🟢$([math]::Round($ts/1024,1))GB | 🟡$([math]::Round($tc/1024,1))GB | 🔴$([math]::Round($ty/1024,1))GB | C盘剩${freeGB}GB"
Write-Host "========================================"
Write-Host "`n下一步: 请从报告中选择要处理的项目，我会逐项确认后执行。"
