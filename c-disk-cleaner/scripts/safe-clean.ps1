<#
.SYNOPSIS
    安全清理工具：清理常见缓存和临时文件
.DESCRIPTION
    仅清理已知安全的缓存/临时目录，不触碰用户数据。
    每个操作前预览将删除的内容和大小。
#>

param(
    [ValidateSet('npm','pip','temp','edge-cache','weixin-dev','all')]
    [string]$Target = 'all',
    [switch]$WhatIf
)

$ErrorActionPreference = 'Continue'
$results = @()

function Clear-IfExists {
    param([string]$Name, [string]$Path, [string]$Command, [string]$Note)
    
    $size = 0
    if (Test-Path $Path) {
        $size = (Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    }
    
    $sizeMB = [int]($size / 1MB)
    $sizeGB = [math]::Round($size / 1GB, 2)
    
    if ($sizeMB -eq 0 -and $Command -eq 'delete') {
        Write-Host "[跳过] $Name - 目录为空"
        return
    }
    
    Write-Host "[$Name] $Note"
    Write-Host "  路径: $Path"
    Write-Host "  大小: ${sizeGB} GB (${sizeMB} MB)"
    
    if ($WhatIf) {
        Write-Host "  [DRY RUN] 预览模式，未执行删除"
        return
    }
    
    try {
        switch ($Command) {
            'delete' {
                if (Test-Path $Path) {
                    Remove-Item $Path -Recurse -Force -ErrorAction Stop
                    Write-Host "  [已删除] 释放 ${sizeGB} GB"
                }
            }
            'npm-clean' {
                npm cache clean --force 2>&1 | Out-Null
                Write-Host "  [已清理] npm cache"
            }
            'pip-clean' {
                pip cache purge 2>&1 | Out-Null
                Write-Host "  [已清理] pip cache"
            }
        }
        $results += [PSCustomObject]@{ Name=$Name; SizeMB=$sizeMB; Status='成功' }
    } catch {
        Write-Host "  [失败] $_"
        $results += [PSCustomObject]@{ Name=$Name; SizeMB=$sizeMB; Status='失败' }
    }
}

Write-Host "`n=== 安全清理工具 ==="
Write-Host "模式: $(if($WhatIf){'预览'}else{'执行'})"
Write-Host ""

$user = $env:USERNAME

switch ($Target) {
    'npm' {
        Clear-IfExists -Name 'npm缓存' -Path "C:\Users\$user\AppData\Local\npm-cache" -Command 'delete' -Note 'Node.js 包管理器缓存'
    }
    'pip' {
        Clear-IfExists -Name 'pip缓存' -Path "C:\Users\$user\AppData\Local\pip" -Command 'delete' -Note 'Python 包管理器缓存'
    }
    'temp' {
        $tempPath = "C:\Users\$user\AppData\Local\Temp"
        Clear-IfExists -Name '临时文件' -Path $tempPath -Command 'delete' -Note '系统和应用临时文件（部分可能被锁定）'
    }
    'edge-cache' {
        $cachePath = "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\Default\Cache"
        Clear-IfExists -Name 'Edge缓存' -Path $cachePath -Command 'delete' -Note 'Edge浏览器缓存'
    }
    'weixin-dev' {
        $wxPath = "C:\Users\$user\AppData\Local\微信开发者工具"
        Clear-IfExists -Name '微信开发者工具' -Path $wxPath -Command 'delete' -Note '微信开发者工具缓存数据'
    }
    'all' {
        Clear-IfExists -Name 'npm缓存' -Path "C:\Users\$user\AppData\Local\npm-cache" -Command 'delete' -Note 'Node.js 包管理器缓存'
        Clear-IfExists -Name '临时文件' -Path "C:\Users\$user\AppData\Local\Temp" -Command 'delete' -Note '系统和应用临时文件'
    }
}

# 汇总
Write-Host "`n=== 清理汇总 ==="
$totalFreed = ($results | Where-Object { $_.Status -eq '成功' } | Measure-Object -Property SizeMB -Sum).Sum
Write-Host "共释放: $([math]::Round($totalFreed/1024,2)) GB"
$results | Format-Table Name, @{N='Size(MB)';E={$_.SizeMB}}, Status -AutoSize
