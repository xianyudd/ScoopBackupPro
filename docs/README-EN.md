<div align="right">
  <a href="../README.md">Home</a> |
  <a href="README-CN.md">简体中文</a>
</div>

# ScoopBackupPro Documentation

## Table of Contents
1. [Features](#features)
2. [Installation](#installation)
3. [Usage](#usage)
4. [Configuration](#configuration)

## Features
- Cross-platform backup for Scoop packages
- Incremental backup support
- Compression options (zip/7z)
- Automated scheduling
- Detailed logging

## Installation
```powershell
# Clone the repository
git clone https://github.com/yourusername/ScoopBackupPro.git
cd ScoopBackupPro
```

## Usage
```powershell
# Basic backup
.\src\Backup-Scoop.ps1

# Backup with compression
.\src\Backup-Scoop.ps1 -Compress zip

# Schedule daily backup (Windows Task Scheduler)
Register-ScheduledTask -Action {.\src\Backup-Scoop.ps1} -Trigger (New-ScheduledTaskTrigger -Daily -At 2am)
```

## Configuration
Create `config.json` in the project root:
```json
{
  "backupPath": "D:\\ScoopBackups",
  "compression": "zip",
  "retentionDays": 30
}