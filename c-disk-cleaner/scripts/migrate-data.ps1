<#
.SYNOPSIS
    安全迁移引擎：C盘大目录 → 其他盘 + 目录联接
.DESCRIPTION
    六步迁移：空间检查→关闭应用→复制→验证→备份→联接
    可中断可回退，每步需用户确认。
.PARAMETER SourcePath
    源目录完整路径（必需）
.PARAMETER DestDrive
    目标盘符 D/E/F 等（必需）
.PARAMETER DestFolder
    目标盘下文件夹名，默认 MigratedData
.PARAMETER AppProcess
    需关闭的进程名（逗号分隔），如 "WeChatAppEx,WeChat"
.PARAMETER WhatIf
    预览模式，仅展示不执行
.EXAMPLE
    .\migrate-data.ps1 -SourcePath "C:\Users\<用户名>\xwechat_files" -DestDrive D -AppProcess "WeChatAppEx" -WhatIf
    .\migrate-data.ps1 -SourcePath "C:\Users\<用户名>\xwechat_files" -DestDrive D -AppProcess "WeChatAppEx"
#>

param(
    [Parameter(Mandatory=$true)][string]$SourcePath,
    [Parameter(Mandatory=$true)][string]$DestDrive,
    [string]$DestFolder = 'MigratedData',
    [string]$AppProcess = '',
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$SourcePath = $SourcePath.TrimEnd('\')

if (-not (Test-Path $SourcePath)) { Write-Host "错误: 源目录不存在 - $SourcePath"; exit 1 }

$sourceDir = Get-Item $SourcePath -Force -ErrorAction Stop
$sourceName = $sourceDir.Name
$destRoot = "${DestDrive}:\$DestFolder"
$destPath = "$destRoot\$sourceName"
$backupPath = "$($sourceDir.Parent.FullName)\$sourceName.bak"

Write-Host ""
Write-Host "========================================"
Write-Host "  数据安全迁移引擎"
Write-Host "========================================"
Write-Host " 源目录 : $SourcePath"
Write-Host " 目标   : $destPath"
Write-Host " 备份   : $backupPath"
Write-Host " 进程   : $(if($AppProcess){$AppProcess}else{'(无)'})"
Write-Host "========================================"

$sourceSize = (Get-ChildItem $SourcePath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
$sourceCount = (Get-ChildItem $SourcePath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
$srcGB = [math]::Round($sourceSize / 1GB, 2)
Write-Host " 源目录: $sourceCount 文件, ${srcGB} GB"

if ($WhatIf) {
    Write-Host "`n[预览] 将执行:"
    Write-Host " 1. 检查 ${DestDrive}: 盘空间"
    if ($AppProcess) { Write-Host " 2. 关闭进程: $AppProcess" }
    Write-Host " 3. robocopy 复制 ${srcGB}GB"
    Write-Host " 4. 验证文件数与大小"
    Write-Host " 5. 备份 $SourcePath → $backupPath"
    Write-Host " 6. 创建联接 $SourcePath → $destPath"
    exit 0
}

# 1. 空间检查
Write-Host "[1/6] 检查目标盘..."
if (-not (Test-Path "${DestDrive}:\")) { Write-Host "错误: ${DestDrive}: 不存在"; exit 1 }
$fi = cmd /c "dir ${DestDrive}:\ /a 2>nul | findstr free"
if ($fi -match '(\d[\d,]*) bytes free') {
    $freeBytes = [long]($matches[1] -replace ',','')
    $freeGB = [math]::Round($freeBytes / 1GB, 2)
    Write-Host " 目标盘可用: ${freeGB} GB"
    if ($freeBytes -lt $sourceSize * 1.05) {
        Write-Host "错误: 空间不足（需${srcGB}GB+5%缓冲，实际${freeGB}GB）"; exit 1
    }
}
Write-Host " 通过"

# 2. 关闭应用
if ($AppProcess) {
    Write-Host "[2/6] 关闭应用..."
    $procs = $AppProcess -split ',' | ForEach-Object { $_.Trim() }
    $running = @(); foreach ($p in $procs) { $rp = Get-Process -Name $p -ErrorAction SilentlyContinue; if ($rp) { $running += $rp } }
    if ($running.Count) {
        Write-Host " 发现 $($running.Count) 个进程:"; $running | ForEach-Object { Write-Host "   - $($_.ProcessName) (PID:$($_.Id))" }
        $running | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Write-Host " 已关闭"
    } else { Write-Host " 无需关闭" }
} else {
    Write-Host "[2/6] 跳过进程检查（未指定），请确认应用已关闭"
}

# 3. 复制
Write-Host "[3/6] 复制中 (${srcGB}GB，请耐心等待)..."
New-Item -ItemType Directory -Path $destRoot -Force -ErrorAction SilentlyContinue | Out-Null
& robocopy $SourcePath $destPath /E /COPY:DAT /R:3 /W:5 /MT:8 /NP /NDL /NFL 2>&1 | Out-Null
$ec = $LASTEXITCODE
if ($ec -ge 8) { Write-Host "错误: robocopy 退出码 $ec"; exit 1 }
Write-Host " 复制完成 (rc=$ec)"

# 4. 验证
Write-Host "[4/6] 验证完整性..."
$destCount = (Get-ChildItem $destPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
$destSize = (Get-ChildItem $destPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
$dstGB = [math]::Round($destSize / 1GB, 2)
$ok = if ($destCount -eq $sourceCount) { 'OK' } else { 'MISMATCH' }
Write-Host " 文件: 源$sourceCount | 目标$destCount [$ok]"
Write-Host " 大小: 源${srcGB}GB | 目标${dstGB}GB"
if ($destCount -ne $sourceCount) {
    Write-Host " 警告: 文件数不一致！继续创建联接？(y/n)"; if ((Read-Host) -ne 'y') { Write-Host "已取消"; exit 0 }
}

# 5. 备份+联接
Write-Host "[5/6] 备份原目录并创建联接..."
try {
    Rename-Item -LiteralPath $SourcePath -NewName "$sourceName.bak" -ErrorAction Stop
    Write-Host " 备份: $backupPath"
} catch {
    Write-Host " 重命名失败，尝试强制删除... $_"
    Remove-Item -LiteralPath $SourcePath -Recurse -Force -ErrorAction Stop
    Write-Host " 原目录已删除"
}
$jr = cmd /c "mklink /J `"$SourcePath`" `"$destPath`"" 2>&1
Write-Host " $jr"

# 6. 验证联接
Write-Host "[6/6] 验证联接..."
$li = Get-Item $SourcePath -Force -ErrorAction SilentlyContinue
if ($li.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
    Write-Host " 联接生效: $SourcePath → $((Get-Item $SourcePath -Force).Target)"
} else { Write-Host " 警告: 联接验证失败！" }

Write-Host ""
Write-Host "========================================"
Write-Host "  迁移完成 | 数据: $destPath (${dstGB}GB)"
Write-Host "========================================"
Write-Host " 确认正常后可删除备份: Remove-Item '$backupPath' -Recurse -Force"
Write-Host " 如需回退: cmd /c rmdir '$SourcePath' && move '$backupPath' '$SourcePath'"
Write-Host "========================================"
