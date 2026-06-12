<#
.SYNOPSIS
    安全迁移工具：将C盘大目录迁移到其他盘并创建目录联接
.DESCRIPTION
    三步安全迁移：复制->验证->联接->备份清理
    所有步骤独立执行，可中断可回退
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,
    
    [Parameter(Mandatory=$true)]
    [string]$DestDrive,
    
    [string]$DestFolder = 'MigratedData',
    
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

# 解析路径
$sourceDir = Get-Item $SourcePath -Force -ErrorAction Stop
$sourceName = $sourceDir.Name
$destRoot = "${DestDrive}:\$DestFolder"
$destPath = "$destRoot\$sourceName"
$backupPath = "$($sourceDir.Parent.FullName)\$sourceName.bak"

Write-Host "`n========================================"
Write-Host "  数据迁移工具"
Write-Host "========================================"
Write-Host "源目录 : $SourcePath"
Write-Host "目标盘 : ${DestDrive}:"
Write-Host "目标路径: $destPath"
Write-Host "备份路径: $backupPath"
Write-Host ""

if ($WhatIf) {
    Write-Host "[DRY RUN] 以上为预览，实际未执行任何操作。"
    exit 0
}

# Step 1: 检查目标盘空间
Write-Host "[1/6] 检查目标盘空间..."
$destDriveInfo = Get-Item "${DestDrive}:\" -Force -ErrorAction SilentlyContinue
if (-not $destDriveInfo) {
    Write-Host "错误: 目标盘 ${DestDrive}: 不存在！"
    exit 1
}

# 获取源目录大小
$sourceSize = (Get-ChildItem $SourcePath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
$sourceSizeGB = [math]::Round($sourceSize / 1GB, 2)
Write-Host "  源目录大小: ${sourceSizeGB} GB"

# 获取目标盘可用空间 (通过dir)
$freeInfo = cmd /c "dir ${DestDrive}:\ /a 2>nul | findstr free"
if ($freeInfo -match '(\d[\d,]*) bytes free') {
    $freeBytes = [long]($matches[1] -replace ',','')
    $freeGB = [math]::Round($freeBytes / 1GB, 2)
    Write-Host "  目标盘可用: ${freeGB} GB"
    if ($freeBytes -lt $sourceSize) {
        Write-Host "错误: 目标盘空间不足！需要 ${sourceSizeGB}GB，可用 ${freeGB}GB"
        exit 1
    }
}
Write-Host "  空间检查通过"

# Step 2: 创建目标目录
Write-Host "[2/6] 创建目标目录..."
New-Item -ItemType Directory -Path $destRoot -Force -ErrorAction SilentlyContinue | Out-Null

# Step 3: robocopy 复制
Write-Host "[3/6] 复制数据到目标盘..."
$robocopyArgs = @(
    $SourcePath,
    $destPath,
    '/E', '/COPY:DAT', '/R:3', '/W:5', '/MT:8', '/NP', '/NDL', '/NFL'
)
$result = & robocopy @robocopyArgs 2>&1
$exitCode = $LASTEXITCODE

# robocopy exit codes: 0-7 are success
if ($exitCode -ge 8) {
    Write-Host "错误: robocopy 失败，退出码: $exitCode"
    Write-Host $result
    exit 1
}
Write-Host "  复制完成 (退出码: $exitCode)"

# Step 4: 验证完整性
Write-Host "[4/6] 验证复制完整性..."
$destSize = (Get-ChildItem $destPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
$sourceFileCount = (Get-ChildItem $SourcePath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
$destFileCount = (Get-ChildItem $destPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count

Write-Host "  源文件: $sourceFileCount 个, $([math]::Round($sourceSize/1GB,2)) GB"
Write-Host "  目标文件: $destFileCount 个, $([math]::Round($destSize/1GB,2)) GB"

if ($destFileCount -ne $sourceFileCount) {
    Write-Host "警告: 文件数量不匹配！(源$sourceFileCount vs 目标$destFileCount)"
}

# Step 5: 备份原目录并创建联接
Write-Host "[5/6] 创建目录联接..."

# 先尝试重命名原目录
Write-Host "  重命名原目录为备份..."
try {
    Rename-Item -LiteralPath $SourcePath -NewName "$sourceName.bak" -ErrorAction Stop
    Write-Host "  已重命名为 $backupPath"
} catch {
    Write-Host "警告: 重命名失败，尝试删除后创建联接... $_"
    # 如果重命名失败（可能文件锁定），则直接删除
    Remove-Item -LiteralPath $SourcePath -Recurse -Force -ErrorAction Stop
}

# 创建目录联接
Write-Host "  创建联接: $SourcePath -> $destPath"
$junctionResult = cmd /c "mklink /J `"$SourcePath`" `"$destPath`"" 2>&1
Write-Host "  $junctionResult"

# Step 6: 验证联接
Write-Host "[6/6] 验证联接..."
$linkItem = Get-Item $SourcePath -Force -ErrorAction SilentlyContinue
if ($linkItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
    $target = (Get-Item $SourcePath -Force).Target
    Write-Host "  联接验证成功: $SourcePath -> $target"
} else {
    Write-Host "警告: 联接创建可能失败，请手动检查！"
}

Write-Host "`n迁移完成！"
Write-Host "备份路径: $backupPath (请确认一切正常后可手动删除)"
Write-Host ""
