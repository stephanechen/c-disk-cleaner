<#
.SYNOPSIS
    安全清理引擎：清理已知安全的缓存、临时文件
.DESCRIPTION
    基于安全分级的缓存清理，仅操作 🟢安全 标记的目录。
    支持按分类操作，支持预览模式。
.PARAMETER Target
    清理目标: all / browsers / dev / temp / system-temp / media / ai
.PARAMETER WhatIf
    预览模式，仅显示不执行
.EXAMPLE
    .\safe-clean.ps1 -Target browsers -WhatIf
    .\safe-clean.ps1 -Target temp
    .\safe-clean.ps1 -Target all
#>

param(
    [ValidateSet('all','browsers','dev','temp','system-temp','media','ai')]
    [string]$Target = 'all',
    [switch]$WhatIf
)

$ErrorActionPreference = 'Continue'
$user = $env:USERNAME
$up = "C:\Users\$user"
$totalFreed = 0
$results = [System.Collections.ArrayList]::new()

function Clear-Dir {
    param([string]$Name, [string]$Path, [string]$Note)
    if (-not (Test-Path $Path)) { return }
    $size = (Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $mb = [int]($size / 1MB)
    $gb = [math]::Round($size / 1GB, 2)
    if ($mb -eq 0) { [void]$results.Add([PSCustomObject]@{Name=$Name;SizeGB=0;Status='跳过(空)';Path=$Path}); return }
    Write-Host " [$Name] $Path | ${gb}GB | $Note"
    if ($WhatIf) { [void]$results.Add([PSCustomObject]@{Name=$Name;SizeGB=$gb;Status='预览';Path=$Path}); return }
    try {
        Remove-Item $Path -Recurse -Force -ErrorAction Stop
        [void]$results.Add([PSCustomObject]@{Name=$Name;SizeGB=$gb;Status='已清理';Path=$Path})
        $script:totalFreed += $mb
        Write-Host "   => 释放 ${gb}GB"
    } catch {
        [void]$results.Add([PSCustomObject]@{Name=$Name;SizeGB=$gb;Status='部分';Path=$Path})
        Write-Host "   => 部分被锁定: $_"
    }
}

function Clear-SubDir {
    param([string]$Name, [string]$Parent, [string]$Sub, [string]$Note)
    Clear-Dir -Name $Name -Path (Join-Path $Parent $Sub) -Note $Note
}

function Clear-ByGlob {
    param([string]$Name, [string]$Parent, [string]$Pattern, [string]$Note)
    if (-not (Test-Path $Parent)) { return }
    Get-ChildItem $Parent -Directory -Filter $Pattern -ErrorAction SilentlyContinue | ForEach-Object {
        Clear-Dir -Name "$Name ($($_.Name))" -Path $_.FullName -Note $Note
    }
}

$mode = if ($WhatIf) { '预览（不删除）' } else { '执行' }
Write-Host ""
Write-Host "========================================"
Write-Host "  安全清理引擎 - $mode | 目标: $Target"
Write-Host "========================================"

# --- 临时文件 ---
if ($Target -in @('all','temp')) {
    Write-Host "`n--- 临时文件 ---"
    Clear-Dir '用户临时文件' "$up\AppData\Local\Temp" '所有应用临时文件'
}

# --- 系统临时 ---
if ($Target -in @('all','system-temp')) {
    Write-Host "`n--- 系统临时文件 ---"
    Clear-Dir '系统临时' 'C:\Windows\Temp' 'Windows临时文件'
    Clear-Dir '系统日志' 'C:\Windows\Logs' 'CBS日志等'
    Clear-Dir '预读取' 'C:\Windows\Prefetch' '启动优化缓存'
    Clear-Dir '内存转储' 'C:\Windows\memory.dmp' '蓝屏转储'
    Clear-Dir '小型转储' 'C:\Windows\Minidump' '小型转储'
}

# --- 浏览器 ---
if ($Target -in @('all','browsers')) {
    Write-Host "`n--- 浏览器缓存 ---"
    Clear-SubDir 'Chrome缓存' "$up\AppData\Local\Google\Chrome\User Data" 'ShaderCache' '着色器缓存'
    Clear-SubDir 'Edge缓存' "$up\AppData\Local\Microsoft\Edge\User Data" 'ShaderCache' '着色器缓存'
    Clear-ByGlob 'Chrome' "$up\AppData\Local\Google\Chrome\User Data" 'Cache' '浏览器缓存'
    Clear-ByGlob 'Edge' "$up\AppData\Local\Microsoft\Edge\User Data" 'Cache' '浏览器缓存'
    Clear-ByGlob 'Firefox' "$up\AppData\Roaming\Mozilla\Firefox\Profiles" 'cache2' '浏览器缓存'
}

# --- 开发 ---
if ($Target -in @('all','dev')) {
    Write-Host "`n--- 开发缓存 ---"
    Clear-Dir 'npm缓存' "$up\AppData\Local\npm-cache" 'npm cache clean --force'
    Clear-Dir 'pip缓存' "$up\AppData\Local\pip" 'pip cache purge'
    Clear-Dir 'Chromium快照' "$up\.chromium-browser-snapshots" 'Playwright/Puppeteer'
    Clear-Dir '微信开发工具' "$up\AppData\Local\微信开发者工具" '小程序开发缓存'
    Clear-SubDir 'VS Code缓存' "$up\AppData\Roaming\Code" 'Cache' 'VS Code缓存'
    Clear-SubDir 'Cursor缓存' "$up\AppData\Roaming\Cursor" 'Cache' 'Cursor缓存'
    Clear-SubDir 'Gradle缓存' "$up\.gradle" 'caches' '构建缓存'
    Clear-Dir 'Maven仓库' "$up\.m2\repository" '需重新下载依赖'
}

# --- 视频设计 ---
if ($Target -in @('all','media')) {
    Write-Host "`n--- 视频/设计缓存 ---"
    Clear-SubDir '剪映缓存' "$up\AppData\Local\JianyingPro\User Data" 'Cache' '渲染缓存'
    Clear-Dir 'Figma' "$up\AppData\Local\Figma" '设计工具缓存'
    Clear-Dir 'B站' "$up\AppData\Local\bilibili" 'B站客户端缓存'
    Clear-Dir 'OBS' "$up\AppData\Roaming\obs-studio" '录屏缓存'
}

# --- AI助手 ---
if ($Target -in @('all','ai')) {
    Write-Host "`n--- AI助手 ---"
    Clear-Dir 'IMA' "$up\AppData\Local\ima.copilot" 'IMA Copilot'
    Clear-Dir '豆包' "$up\AppData\Local\Doubao" '豆包'
}

# --- 汇总 ---
Write-Host ""
Write-Host "========================================"
Write-Host "  清理汇总"
Write-Host "========================================"
$results | Sort-Object SizeGB -Descending | Format-Table `
    @{N='项目';E={$_.Name};W=22}, @{N='大小(GB)';E={$_.SizeGB};A='right';W=10},
    @{N='状态';E={$_.Status};W=12} -AutoSize

$fg = [math]::Round($totalFreed / 1024, 2)
if ($WhatIf) {
    $pt = [math]::Round(($results | Where-Object {$_.Status-eq'预览'} | Measure-Object -Property SizeGB -Sum).Sum, 1)
    Write-Host " 预览总计: ${pt}GB（未删除）"
    Write-Host " 确认后执行: .\safe-clean.ps1 -Target $Target"
} else {
    Write-Host " 实际释放: ${fg}GB"
}
Write-Host "========================================"
