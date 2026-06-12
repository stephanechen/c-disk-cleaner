<#
.SYNOPSIS
    C盘存储扫描分析工具
.DESCRIPTION
    扫描C盘各目录占用，生成结构化报告。兼容ConstrainedLanguage模式。
    所有操作只读，不修改任何文件。
#>

param(
    [string]$TargetUser = $env:USERNAME,
    [int]$MinSizeMB = 50
)

$ErrorActionPreference = 'SilentlyContinue'
$results = @()

function Get-DirSize {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return 0 }
    $size = (Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    return [int]($size / 1MB)
}

function Add-Result {
    param([string]$Category, [string]$Path, [int]$SizeMB, [string]$Safety, [string]$Note)
    if ($SizeMB -lt $MinSizeMB) { return }
    $results += [PSCustomObject]@{
        Category = $Category
        Path     = $Path
        SizeMB   = $SizeMB
        SizeGB   = [math]::Round($SizeMB / 1024, 2)
        Safety   = $Safety
        Note     = $Note
    }
}

Write-Host "`n=== C盘存储扫描报告 ==="
Write-Host "扫描时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "目标用户: $TargetUser"
Write-Host ""

# 1. 根目录系统文件
$rootDir = Get-ChildItem C:\ -Force -File -ErrorAction SilentlyContinue
foreach ($f in $rootDir) {
    $mb = [int]($f.Length / 1MB)
    if ($mb -gt 10) {
        $safety = if ($f.Name -match 'hiberfil|pagefile|swapfile') { 'system' } else { 'safe' }
        $note = if ($f.Name -eq 'hiberfil.sys') { '休眠文件，powercfg /h off 可关闭' }
                elseif ($f.Name -eq 'pagefile.sys') { '虚拟内存，可调小但不可删' }
                elseif ($f.Name -eq 'swapfile.sys') { 'UWP应用交换文件' }
                else { '' }
        Add-Result -Category 'C盘根目录' -Path "C:\$($f.Name)" -SizeMB $mb -Safety $safety -Note $note
    }
}

# 2. 用户目录顶层
$userPath = "C:\Users\$TargetUser"
$excludeAppData = @('AppData')
Get-ChildItem $userPath -Directory -Exclude $excludeAppData -ErrorAction SilentlyContinue | ForEach-Object {
    $mb = Get-DirSize $_.FullName
    $note = ''
    if ($_.Name -eq 'xwechat_files') { $note = '微信工作版数据，可迁移到D盘' }
    elseif ($_.Name -eq 'Documents') { $note = '含WeChat Files等，可迁移' }
    elseif ($_.Name -eq 'WPSDrive') { $note = 'WPS云盘本地同步，可迁移' }
    elseif ($_.Name -eq 'Desktop') { $note = '桌面文件，建议整理' }
    Add-Result -Category '用户目录' -Path $_.FullName -SizeMB $mb -Safety 'caution' -Note $note
}

# 3. AppData 子目录
$appdata = "$userPath\AppData"
if (Test-Path $appdata) {
    Get-ChildItem $appdata -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $mb = Get-DirSize $_.FullName
        Add-Result -Category 'AppData' -Path $_.FullName -SizeMB $mb -Safety 'caution' -Note '含Local/Roaming/LocalLow'
    }

    # Local 大项
    $localPath = "$appdata\Local"
    Get-ChildItem $localPath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $mb = Get-DirSize $_.FullName
        $safety = 'caution'
        $note = ''
        if ($_.Name -eq 'npm-cache') { $safety = 'safe'; $note = 'npm缓存，npm cache clean --force' }
        elseif ($_.Name -eq 'pip') { $safety = 'safe'; $note = 'pip缓存，pip cache purge' }
        elseif ($_.Name -eq 'Temp') { $safety = 'safe'; $note = '临时文件，可安全清理' }
        elseif ($_.Name -eq 'JianyingPro') { $note = '剪映缓存，可清理Cache子目录' }
        elseif ($_.Name -eq 'Microsoft') { $note = '含Edge浏览器缓存' }
        elseif ($_.Name -eq 'Doubao') { $note = '豆包应用数据' }
        Add-Result -Category 'AppData\Local' -Path $_.FullName -SizeMB $mb -Safety $safety -Note $note
    }

    # Roaming 大项
    $roamPath = "$appdata\Roaming"
    Get-ChildItem $roamPath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $mb = Get-DirSize $_.FullName
        $note = ''
        $safety = 'caution'
        if ($_.Name -eq 'kingsoft') { $note = 'WPS办公云数据，可清理云备份' }
        elseif ($_.Name -eq 'Tencent') { $note = 'QQ/腾讯应用数据' }
        elseif ($_.Name -eq 'npm') { $safety = 'safe'; $note = 'npm全局缓存' }
        Add-Result -Category 'AppData\Roaming' -Path $_.FullName -SizeMB $mb -Safety $safety -Note $note
    }
}

# 4. Program Files
Get-ChildItem 'C:\Program Files' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $mb = Get-DirSize $_.FullName
    Add-Result -Category 'Program Files' -Path $_.FullName -SizeMB $mb -Safety 'caution' -Note '不建议手动清理'
}
Get-ChildItem 'C:\Program Files (x86)' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $mb = Get-DirSize $_.FullName
    Add-Result -Category 'Program Files (x86)' -Path $_.FullName -SizeMB $mb -Safety 'caution' -Note '不建议手动清理'
}

# 5. ProgramData
Get-ChildItem 'C:\ProgramData' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $mb = Get-DirSize $_.FullName
    $note = if ($_.Name -eq 'Lenovo') { '联想预装软件备份' } else { '' }
    Add-Result -Category 'ProgramData' -Path $_.FullName -SizeMB $mb -Safety 'caution' -Note $note
}

# 6. Windows 关键子目录
$winDirs = @{
    'WinSxS' = 'Windows组件库，用磁盘清理工具处理'
    'System32' = '系统核心，不可删'
    'SysWOW64' = '32位系统组件'
    'SoftwareDistribution' = 'Windows更新缓存'
    'Temp' = '系统临时文件'
    'Installer' = '程序安装包缓存'
    'Logs' = '系统日志'
    'Prefetch' = '预读取文件'
    'assembly' = '.NET程序集'
    'Microsoft.NET' = '.NET框架'
}
foreach ($dir in $winDirs.Keys) {
    $fullPath = "C:\Windows\$dir"
    if (Test-Path $fullPath) {
        $mb = Get-DirSize $fullPath
        $safety = if ($dir -in @('WinSxS', 'System32', 'SysWOW64', 'assembly', 'Microsoft.NET')) { 'system' } else { 'caution' }
        Add-Result -Category 'Windows' -Path $fullPath -SizeMB $mb -Safety $safety -Note $winDirs[$dir]
    }
}

# 输出报告
Write-Host "```"
$results | Sort-Object SizeMB -Descending | Format-Table Category, @{N='Size(GB)';E={$_.SizeGB};Align='right'}, Safety, Path -AutoSize -Wrap
Write-Host "```"

# 汇总
$totalScanned = ($results | Measure-Object -Property SizeMB -Sum).Sum
$freeBytes = (Get-Item 'C:\' -Force).EnumerateFileSystemInfos() | Out-Null
# 用cmd获取空闲空间
$freeInfo = cmd /c 'dir C:\ /a 2>nul | findstr free'
if ($freeInfo -match '(\d[\d,]*) bytes free') {
    $freeGB = [math]::Round([long]($matches[1] -replace ',','') / 1GB, 2)
    Write-Host "`nC盘可用空间: ${freeGB} GB"
}
Write-Host "以上扫描项合计: $totalScanned MB = $([math]::Round($totalScanned/1024,1)) GB"

# 输出摘要
Write-Host "`n=== 清理建议优先级 ==="
$safe = $results | Where-Object { $_.Safety -eq 'safe' }
$caution = $results | Where-Object { $_.Safety -eq 'caution' }
$system = $results | Where-Object { $_.Safety -eq 'system' }

if ($safe) {
    Write-Host "`n[安全可清理]"
    $safe | ForEach-Object { Write-Host "  $($_.Path) ($($_.SizeGB)GB) - $($_.Note)" }
}
if ($caution) {
    Write-Host "`n[需确认后操作]"
    $caution | ForEach-Object { Write-Host "  $($_.Path) ($($_.SizeGB)GB) - $($_.Note)" }
}
if ($system) {
    Write-Host "`n[系统文件-不建议手动删除]"
    $system | ForEach-Object { Write-Host "  $($_.Path) ($($_.SizeGB)GB) - $($_.Note)" }
}
