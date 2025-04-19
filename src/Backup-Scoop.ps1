<#
.SYNOPSIS
Scoop 智能备份脚本 - 符合 PSScriptAnalyzer 标准版
.DESCRIPTION
自动备份Scoop配置、软件列表和持久化数据，支持压缩/增量备份
.VERSION 2.3
#>

#region 配置参数
param (
    [Parameter(HelpMessage = "备份文件存储根路径")]
    [string]
    $BackupRoot = "D:\Backup\ScoopBackups",

    [Parameter(HelpMessage = "启用压缩备份")]
    [switch]
    $NoCompress,

    [Parameter(HelpMessage = "启用增量备份模式")]
    [switch]
    $Incremental,

    [Parameter(HelpMessage = "要排除的文件模式")]
    [string[]]
    $ExcludePatterns = @("*.tmp", "*.log", "*.cache", "*.bak", "temp", "cache")
)

# 内部默认值处理（符合 PSScriptAnalyzer）
$EnableCompression = -not $NoCompress  # 使用否定式参数更符合PS习惯
$EnableIncremental = $Incremental
$ScoopRoot = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $env:USERPROFILE "scoop" }
$BackupDate = Get-Date -Format "yyyy-MM-dd_HHmmss"
$BackupDir = "$BackupRoot\$BackupDate"
$LogFile = "$BackupRoot\backup_log_$(Get-Date -Format 'yyyyMM').txt"
#endregion

#region 辅助函数
<#
.SYNOPSIS
带颜色和格式化的日志输出
#>
function Write-ColorOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info','Warning','Error','Success')]
        [string]$Level = "Info",
        
        [switch]$IsSection
    )
    
    $colorMap = @{
        Info = "Cyan"
        Warning = "Yellow"
        Error = "Red"
        Success = "Green"
    }
    
    $logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')][$Level] $Message"
    
    if ($IsSection) {
        $border = "=" * 80
        Write-Host ("`n$border`n$Message`n$border`n") -ForegroundColor $colorMap[$Level]
    } else {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] " -NoNewline -ForegroundColor DarkGray
        Write-Host $Message -ForegroundColor $colorMap[$Level]
    }
    
    $logEntry | Out-File $LogFile -Append -Encoding UTF8
}

<#
.SYNOPSIS
安全创建目录
#>
function New-BackupDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [string]$Description
    )
    
    try {
        if (-not (Test-Path $Path)) {
            $null = New-Item -Path $Path -ItemType Directory -Force -ErrorAction Stop
            Write-ColorOutput "创建目录: $Path" -Level Info
        }
        return $true
    } catch {
        Write-ColorOutput "目录创建失败: $($_.Exception.Message)" -Level Error
        return $false
    }
}
#endregion

#region 主流程
try {
    # 初始化检查
    if (-not (Test-Path $ScoopRoot)) {
        throw "Scoop根目录不存在: $ScoopRoot"
    }
    
    Write-ColorOutput "开始 Scoop 智能备份 (v2.3)" -Level Success -IsSection
    Write-ColorOutput "模式: $(if($EnableIncremental){'增量'}else{'完整'})备份" -Level Info
    Write-ColorOutput "压缩: $(if($EnableCompression){'启用'}else{'禁用'})" -Level Info
    
    # 创建备份目录结构
    $directoryMap = @{
        "AppLists"    = "软件列表"
        "PersistData" = "持久化配置"
        "GlobalApps"  = "全局软件"
        "Metadata"    = "元数据"
    }
    
    foreach ($dir in $directoryMap.Keys) {
        $fullPath = "$BackupDir\$dir"
        if (-not (New-BackupDirectory -Path $fullPath -Description $directoryMap[$dir])) {
            exit 1
        }
    }

    # 1. 备份软件列表
    Write-ColorOutput "备份软件清单..." -Level Info -IsSection
    $appListPath = "$BackupDir\AppLists\scoop_apps.json"
    scoop export | Out-File $appListPath -Encoding UTF8
    $appCount = (scoop list | Measure-Object).Count
    Write-ColorOutput "已备份 $appCount 个软件清单" -Level Success

    # 2. 备份持久化配置
    $persistPath = "$ScoopRoot\persist"
    $persistBackup = "$BackupDir\PersistData\persist"
    
    if (Test-Path $persistPath) {
        Write-ColorOutput "备份持久化配置..." -Level Info -IsSection
        
        if ($EnableIncremental -and (Test-Path "$BackupRoot\last_backup.txt")) {
            $lastBackupTime = (Get-Item "$BackupRoot\last_backup.txt").LastWriteTime
            Write-ColorOutput "增量模式：只备份变更文件（基于 $lastBackupTime）" -Level Warning
            
            $files = Get-ChildItem $persistPath -Exclude $ExcludePatterns -Recurse | 
                     Where-Object { $_.LastWriteTime -gt $lastBackupTime }
            
            if ($null -eq $files -or $files.Count -eq 0) {
                Write-ColorOutput "未检测到变更文件，跳过持久化备份" -Level Warning
                $persistCount = 0
            } else {
                foreach ($file in $files) {
                    $relativePath = $file.FullName.Substring($persistPath.Length)
                    $destPath = $persistBackup + $relativePath
                    $destDir = [System.IO.Path]::GetDirectoryName($destPath)
                    
                    if (-not (Test-Path $destDir)) {
                        $null = New-Item -Path $destDir -ItemType Directory -Force
                    }
                    Copy-Item $file.FullName -Destination $destPath -Force
                }
                $persistCount = $files.Count
                Write-ColorOutput "已备份 $persistCount 个变更文件" -Level Success
            }
        } else {
            Write-ColorOutput "完整备份模式" -Level Info
            Get-ChildItem $persistPath -Exclude $ExcludePatterns | 
                Copy-Item -Destination $persistBackup -Recurse -Force
            $persistCount = (Get-ChildItem $persistBackup -Recurse | Measure-Object).Count
            Write-ColorOutput "已备份 $persistCount 个持久化项目" -Level Success
        }
    }

    # 3. 备份全局软件
    $globalPath = "$ScoopRoot\globalapps"
    if (Test-Path $globalPath) {
        Write-ColorOutput "备份全局软件..." -Level Info -IsSection
        $globalBackup = "$BackupDir\GlobalApps\globalapps"
        Copy-Item $globalPath -Destination $globalBackup -Recurse -Exclude $ExcludePatterns -Force
        $globalCount = (Get-ChildItem $globalBackup | Measure-Object).Count
        Write-ColorOutput "已备份 $globalCount 个全局软件" -Level Success
    }

    # 4. 备份元数据
    Write-ColorOutput "备份系统元数据..." -Level Info -IsSection
    scoop config | Out-File "$BackupDir\Metadata\scoop_config.json" -Encoding UTF8
    Get-Date | Out-File "$BackupDir\Metadata\backup_time.txt"
    Write-ColorOutput "系统配置已备份" -Level Success

    # 压缩处理
    if ($EnableCompression) {
        # 先生成摘要报告
        $report | Out-File "$BackupDir\backup_summary.txt" -Encoding UTF8
        
        Write-ColorOutput "正在压缩备份文件..." -Level Info -IsSection
        $zipPath = "$BackupRoot\$BackupDate.zip"
        
        try {
            if (Test-Path $zipPath) {
                Remove-Item $zipPath -Force
            }
            
            $originalSize = (Get-ChildItem $BackupDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
            Compress-Archive -Path "$BackupDir\*" -DestinationPath $zipPath -CompressionLevel Optimal
            
            if (Test-Path $zipPath) {
                $compressedSize = (Get-Item $zipPath).Length / 1MB
                
                # 将摘要文件移入压缩包
                Add-Content -Path $zipPath -Value (Get-Content "$BackupDir\backup_summary.txt") -Force
                
                Remove-Item $BackupDir -Recurse -Force
                
                Write-ColorOutput "压缩完成 - 原始大小: ${originalSize}MB → 压缩后: ${compressedSize}MB" -Level Success
                Write-ColorOutput "节省空间: $(100 - [math]::Round($compressedSize/$originalSize*100))%" -Level Success
                Write-ColorOutput "备份摘要已包含在压缩包内" -Level Info
            }
        } catch {
            Write-ColorOutput "压缩失败: $($_.Exception.Message)" -Level Error
        }
    }

    # 记录本次备份时间
    Get-Date | Out-File "$BackupRoot\last_backup.txt" -Force

    # 生成报告
    $report = @"
===================== 备份摘要 =====================
备份时间:   $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
备份模式:   $(if($EnableIncremental){'增量'}else{'完整'}) $(if($EnableCompression){'+压缩'})
存储位置:   $(if($EnableCompression){$zipPath}else{$BackupDir})
包含内容:
  - 软件列表:     $appCount 个应用
  - 持久化配置:   $(if($persistCount){$persistCount}else{0}) 个
  - 全局软件:     $(if($globalCount){$globalCount}else{0}) 个
排除文件类型:    $($ExcludePatterns -join ', ')
==================================================
"@
    
    # 非压缩模式生成摘要
    if (-not $EnableCompression) {
        $report | Out-File "$BackupDir\backup_summary.txt" -Encoding UTF8
        Write-ColorOutput $report -Level Success -IsSection
    }

} catch {
    $errorMsg = "[ERROR][$(Get-Date)] $_`nStack Trace:`n$($_.ScriptStackTrace)"
    Write-ColorOutput $errorMsg -Level Error
    $errorMsg | Out-File $LogFile -Append -Encoding UTF8
    exit 1
}
#endregion
