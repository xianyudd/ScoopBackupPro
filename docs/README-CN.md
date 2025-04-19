<div align="right">
  <a href="../README.md">首页</a> |
  <a href="README-EN.md">English</a>
</div>

# Scoop备份专家 文档 [v2.3]

## 目录
1. [功能特性](#功能特性)
2. [安装指南](#安装指南)
3. [使用方法](#使用方法)
4. [配置选项](#配置选项)
5. [高级功能](#高级功能)

## 功能特性
- 完整的Scoop环境备份(软件列表/持久化数据/全局软件/元数据)
- 智能增量备份模式(-Incremental参数)
- 压缩备份支持(-NoCompress禁用)
- 智能文件排除模式(默认排除临时/缓存文件)
- 彩色分级日志系统(Info/Warning/Error/Success)
- 自动生成备份摘要报告
- 符合PSScriptAnalyzer规范

## 安装指南
```powershell
# 克隆仓库
git clone https://github.com/yourusername/ScoopBackupPro.git
cd ScoopBackupPro
```

## 使用方法
```powershell
# 基础备份(默认启用压缩)
.\src\Backup-Scoop.ps1

# 禁用压缩备份
.\src\Backup-Scoop.ps1 -NoCompress

# 增量备份模式(仅备份变更文件)
.\src\Backup-Scoop.ps1 -Incremental

# 自定义排除模式
.\src\Backup-Scoop.ps1 -ExcludePatterns "*.tmp","temp"
```

## 配置选项
支持命令行参数和默认值：
```powershell
param (
    [string]$BackupRoot = "D:\Backup\ScoopBackups", # 备份根路径
    [switch]$NoCompress,  # 禁用压缩
    [switch]$Incremental, # 增量模式
    [string[]]$ExcludePatterns = @("*.tmp", "*.log") # 排除模式
)
```

## 高级功能
- **增量备份**：基于上次备份时间只同步变更文件
- **智能压缩**：自动计算压缩率，显示空间节省百分比
- **错误恢复**：完善的异常处理和日志记录
- **跨平台**：支持Windows PowerShell 5.1+环境