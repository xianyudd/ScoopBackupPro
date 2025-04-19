<div align="right">
  <a href="../README.md">首页</a> |
  <a href="README-EN.md">English</a>
</div>

# Scoop备份专家 文档

## 目录
1. [功能特性](#功能特性)
2. [安装指南](#安装指南)
3. [使用方法](#使用方法)
4. [配置选项](#配置选项)

## 功能特性
- Scoop包的跨平台备份
- 增量备份支持
- 压缩选项(zip/7z格式)
- 自动定时备份
- 详细日志记录

## 安装指南
```powershell
# 克隆仓库
git clone https://github.com/yourusername/ScoopBackupPro.git
cd ScoopBackupPro
```

## 使用方法
```powershell
# 基础备份
.\src\Backup-Scoop.ps1

# 带压缩的备份
.\src\Backup-Scoop.ps1 -Compress zip

# 设置每日自动备份(使用Windows任务计划)
Register-ScheduledTask -Action {.\src\Backup-Scoop.ps1} -Trigger (New-ScheduledTaskTrigger -Daily -At 2am)
```

## 配置选项
在项目根目录创建`config.json`:
```json
{
  "backupPath": "D:\\ScoopBackups",
  "compression": "zip",
  "retentionDays": 30
}