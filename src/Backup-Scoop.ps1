<#
.SYNOPSIS
Scoop 备份脚本 - 优化输出版
.DESCRIPTION
自动备份Scoop配置、软件列表和持久化数据，提供更清晰的输出格式
#>

# 配置区
$ScoopRoot = "D:\DevTools\DPM\Scoop"
$BackupRoot = "D:\Backup\ScoopBackups"
$BackupDate = Get-Date -Format "yyyy-MM-dd_HHmmss"
$BackupDir = "$BackupRoot\$BackupDate"
$LogFile = "$BackupRoot\backup_log.txt"

# 美化输出函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$IsSection
    )
    
    if ($IsSection) {
        Write-Host ("`n" + ("=" * 80)) -ForegroundColor Cyan
        Write-Host $Message -ForegroundColor $Color
        Write-Host ("=" * 80 + "`n") -ForegroundColor Cyan
    } else {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] " -NoNewline -ForegroundColor DarkGray
        Write-Host $Message -ForegroundColor $Color
    }
    $Message | Out-File $LogFile -Append
}

try {
    # 初始化
    Write-ColorOutput "开始 Scoop 数据备份" -Color Green -IsSection
    
    # 创建目录结构
    $directories = @{
        "AppLists"    = "软件列表"
        "PersistData" = "持久化配置"
        "GlobalApps"  = "全局软件"
        "Metadata"    = "元数据"
    }
    
    Write-ColorOutput "创建备份目录结构..." -Color Cyan
    New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null
    
    foreach ($dir in $directories.Keys) {
        $fullPath = "$BackupDir\$dir"
        New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
        Write-ColorOutput "  ✓ 创建目录: $fullPath" -Color DarkCyan
    }

    # 1. 备份软件列表
    Write-ColorOutput "`n备份软件清单..." -Color Cyan
    $appListPath = "$BackupDir\AppLists\scoop_apps.json"
    scoop export > $appListPath
    $appCount = (scoop list).Count
    Write-ColorOutput "  ✓ 已备份 $appCount 个软件到: $appListPath" -Color Green

    # 2. 备份持久化配置
    Write-ColorOutput "`n备份持久化配置..." -Color Cyan
    $persistPath = "$ScoopRoot\persist"
    $persistBackup = "$BackupDir\PersistData\persist"
    
    if (Test-Path $persistPath) {
        $persistItems = Get-ChildItem $persistPath -Directory
        Copy-Item -Path $persistPath -Destination $persistBackup -Recurse -Force
        
        Write-ColorOutput "  ✓ 已备份以下持久化应用配置:" -Color Green
        $persistItems | ForEach-Object {
            Write-ColorOutput "    • $($_.Name)" -Color DarkGreen
        }
        Write-ColorOutput "  总计: $($persistItems.Count) 个应用配置" -Color Green
    } else {
        Write-ColorOutput "  ⚠ 未找到持久化目录: $persistPath" -Color Yellow
    }

    # 3. 备份全局软件
    Write-ColorOutput "`n检查全局软件..." -Color Cyan
    $globalPath = "$ScoopRoot\globalapps"
    
    if (Test-Path $globalPath) {
        $globalBackup = "$BackupDir\GlobalApps\globalapps"
        $globalApps = Get-ChildItem $globalPath | Measure-Object
        Copy-Item -Path $globalPath -Destination $globalBackup -Recurse -Force
        Write-ColorOutput "  ✓ 已备份 $($globalApps.Count) 个全局软件" -Color Green
    } else {
        Write-ColorOutput "  ℹ 未启用全局安装功能" -Color Blue
    }

    # 4. 备份元数据
    Write-ColorOutput "`n备份系统元数据..." -Color Cyan
    $scoopConfig = "$BackupDir\Metadata\scoop_config.json"
    scoop config > $scoopConfig
    Get-Date > "$BackupDir\Metadata\backup_time.txt"
    Write-ColorOutput "  ✓ 系统配置和备份时间已保存" -Color Green

    # 生成报告
    $backupSize = (Get-ChildItem $BackupDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    $summary = @"
    ===================== 备份摘要 =====================
    备份时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    备份位置: $BackupDir
    总大小: $($backupSize.ToString("0.00")) MB
    包含内容:
    - 软件列表: $appCount 个应用
    - 持久化配置: $(if($persistItems){$persistItems.Count}else{0}) 个应用
    - 全局软件: $(if($globalApps){$globalApps.Count}else{0}) 个
    ==================================================
"@
    $summary | Out-File "$BackupDir\backup_summary.txt"
    Write-ColorOutput $summary -Color Magenta -IsSection

    # 清理旧备份 (保留最近7天)
    Write-ColorOutput "`n清理旧备份..." -Color Cyan
    $daysToKeep = 7
    $cutoffDate = (Get-Date).AddDays(-$daysToKeep)
    $oldBackups = Get-ChildItem $BackupRoot -Directory | Where-Object { $_.CreationTime -lt $cutoffDate }
    
    if ($oldBackups) {
        $oldBackups | Remove-Item -Recurse -Force
        Write-ColorOutput "  ✓ 已清理 $($oldBackups.Count) 个旧备份" -Color Green
    } else {
        Write-ColorOutput "  ℹ 没有需要清理的旧备份" -Color Blue
    }

    Write-ColorOutput "`n备份操作已完成!" -Color Green -IsSection

} catch {
    $errorMsg = "[ERROR][$(Get-Date)] $_`nStack Trace:`n$($_.ScriptStackTrace)"
    Write-Host $errorMsg -ForegroundColor Red
    $errorMsg | Out-File $LogFile -Append
    exit 1
}