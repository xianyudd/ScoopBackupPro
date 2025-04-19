<div align="right">
  <a href="../README.md">Home</a> |
  <a href="README-CN.md">简体中文</a>
</div>

# ScoopBackupPro Documentation [v2.3]

## Table of Contents
1. [Features](#features)
2. [Installation](#installation)
3. [Usage](#usage)
4. [Configuration](#configuration)
5. [Advanced Features](#advanced-features)

## Features
- Complete Scoop environment backup (apps/persist data/global apps/metadata)
- Smart incremental backup mode (-Incremental parameter)
- Compression support (disable with -NoCompress)
- Intelligent file exclusion (default excludes temp/cache files)
- Color-coded logging system (Info/Warning/Error/Success)
- Automatic backup summary report
- Compliant with PSScriptAnalyzer standards

## Installation
```powershell
# Clone repository
git clone https://github.com/yourusername/ScoopBackupPro.git
cd ScoopBackupPro
```

## Usage
```powershell
# Basic backup (compression enabled by default)
.\src\Backup-Scoop.ps1

# Disable compression
.\src\Backup-Scoop.ps1 -NoCompress

# Incremental backup mode (only changed files)
.\src\Backup-Scoop.ps1 -Incremental

# Custom exclusion patterns
.\src\Backup-Scoop.ps1 -ExcludePatterns "*.tmp","temp"
```

## Configuration
Supported parameters with defaults:
```powershell
param (
    [string]$BackupRoot = "D:\Backup\ScoopBackups", # Backup root path
    [switch]$NoCompress,  # Disable compression
    [switch]$Incremental, # Incremental mode
    [string[]]$ExcludePatterns = @("*.tmp", "*.log") # Exclusion patterns
)
```

## Advanced Features
- **Incremental Backup**: Only sync changed files based on last backup time
- **Smart Compression**: Auto-calculate compression ratio and space saved
- **Error Recovery**: Comprehensive exception handling and logging
- **Cross-Platform**: Supports Windows PowerShell 5.1+ environments