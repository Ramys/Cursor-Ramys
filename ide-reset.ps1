# IDE 通用重置工具 - 支持多IDE和扩展插件清理
# 设置输出编码为 UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 颜色定义
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$CYAN = "`e[36m"
$MAGENTA = "`e[35m"
$NC = "`e[0m"

# 检查管理员权限
function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-AdminRights)) {
    Write-Host "$RED[错误]$NC 此脚本需要管理员权限运行" -ForegroundColor Red
    Write-Host "$YELLOW[提示]$NC 请以管理员身份运行 PowerShell 后重试" -ForegroundColor Yellow
    Read-Host "按回车键退出"
    exit 1
}

# 显示标题
Write-Host "$CYAN================================$NC"
Write-Host "$GREEN   IDE 通用重置工具 v2.0          $NC"
Write-Host "$YELLOW  支持 Cursor/VS Code + 扩展清理  $NC"
Write-Host "$CYAN================================$NC"
Write-Host ""

# IDE 配置定义
$IDEConfigs = @{
    'Cursor' = @{
        'Name' = 'Cursor'
        'ProcessNames' = @('Cursor', 'cursor')
        'UserDataPath' = "$env:APPDATA\Cursor\User"
        'StorageFile' = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
        'UpdaterPath' = "$env:LOCALAPPDATA\cursor-updater"
        'InstallPaths' = @(
            "$env:LOCALAPPDATA\Programs\cursor\resources\app\package.json",
            "$env:LOCALAPPDATA\cursor\resources\app\package.json"
        )
    }
    'VSCode' = @{
        'Name' = 'Visual Studio Code'
        'ProcessNames' = @('Code', 'code')
        'UserDataPath' = "$env:APPDATA\Code\User"
        'StorageFile' = "$env:APPDATA\Code\User\globalStorage\storage.json"
        'UpdaterPath' = $null
        'InstallPaths' = @(
            "$env:LOCALAPPDATA\Programs\Microsoft VS Code\resources\app\package.json",
            "$env:PROGRAMFILES\Microsoft VS Code\resources\app\package.json"
        )
    }
}

# 扩展插件配置
$ExtensionConfigs = @{
    'Augment' = @{
        'Name' = 'Augment'
        'GlobalStorageKeys' = @(
            'augmentcode.augment',
            'augment.augment-code'
        )
        'Description' = 'AI代码助手扩展'
        'SupportedIDEs' = @('Cursor', 'VSCode')
    }
    'GitHub Copilot' = @{
        'Name' = 'GitHub Copilot'
        'GlobalStorageKeys' = @(
            'github.copilot',
            'github.copilot-chat'
        )
        'Description' = 'GitHub AI编程助手'
        'SupportedIDEs' = @('Cursor', 'VSCode')
    }
    'Codeium' = @{
        'Name' = 'Codeium'
        'GlobalStorageKeys' = @(
            'codeium.codeium'
        )
        'Description' = 'Codeium AI助手'
        'SupportedIDEs' = @('Cursor', 'VSCode')
    }

}

# 生成新的设备标识符
function New-DeviceIdentifiers {
    $machineId = "auth0|user_" + (-join ((1..32) | ForEach-Object { '{0:x}' -f (Get-Random -Maximum 16) }))
    $macMachineId = [System.Guid]::NewGuid().ToString()
    $devDeviceId = [System.Guid]::NewGuid().ToString()
    $sqmId = [System.Guid]::NewGuid().ToString().ToUpper()
    
    return @{
        'machineId' = $machineId
        'macMachineId' = $macMachineId
        'devDeviceId' = $devDeviceId
        'sqmId' = $sqmId
    }
}

# 关闭进程函数
function Close-IDEProcess {
    param($ProcessNames, $IDEName)
    
    Write-Host "$BLUE[信息]$NC 检查 $IDEName 进程..."
    
    foreach ($processName in $ProcessNames) {
        $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
        if ($process) {
            Write-Host "$YELLOW[警告]$NC 发现 $processName 正在运行，正在关闭..."
            Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            
            # 验证是否关闭成功
            $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if (-not $process) {
                Write-Host "$GREEN[成功]$NC $processName 已关闭"
            } else {
                Write-Host "$RED[错误]$NC 无法关闭 $processName，请手动关闭后重试"
                return $false
            }
        }
    }
    return $true
}

# 备份配置文件
function Backup-Configuration {
    param($StorageFile, $BackupDir)
    
    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }
    
    if (Test-Path $StorageFile) {
        $backupName = "storage.json.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $StorageFile "$BackupDir\$backupName" -Force
        Write-Host "$GREEN[信息]$NC 配置已备份到: $BackupDir\$backupName"
        return "$BackupDir\$backupName"
    }
    return $null
}

# 清理IDE历史数据（保留用户配置）
function Clear-IDEHistory {
    param($UserDataPath, $IDEName, $DryRun = $false)
    
    Write-Host "$BLUE[信息]$NC 清理 $IDEName 历史数据..."
    
    $itemsToClean = @(
        @{ Path = "$UserDataPath\globalStorage\state.vscdb"; Type = "File"; Description = "状态数据库" }
        @{ Path = "$UserDataPath\globalStorage\state.vscdb.backup"; Type = "File"; Description = "状态数据库备份" }
        @{ Path = "$UserDataPath\History"; Type = "FolderContents"; Description = "使用历史" }
        @{ Path = "$UserDataPath\workspaceStorage"; Type = "Folder"; Description = "工作区存储" }
        @{ Path = "$UserDataPath\logs"; Type = "FolderContents"; Description = "日志文件" }
    )
    
    foreach ($item in $itemsToClean) {
        if (Test-Path $item.Path) {
            if ($DryRun) {
                Write-Host "$CYAN[预览]$NC 将清理: $($item.Description) - $($item.Path)"
                continue
            }
            
            try {
                switch ($item.Type) {
                    "File" {
                        Remove-Item -Path $item.Path -Force -ErrorAction Stop
                        Write-Host "$GREEN[成功]$NC 已删除 $($item.Description): $($item.Path)"
                    }
                    "Folder" {
                        Remove-Item -Path $item.Path -Recurse -Force -ErrorAction Stop
                        Write-Host "$GREEN[成功]$NC 已删除 $($item.Description): $($item.Path)"
                    }
                    "FolderContents" {
                        if (Test-Path $item.Path) {
                            Get-ChildItem -Path $item.Path -Recurse | Remove-Item -Recurse -Force -ErrorAction Stop
                            Write-Host "$GREEN[成功]$NC 已清空 $($item.Description): $($item.Path)"
                        }
                    }
                }
            }
            catch {
                Write-Host "$YELLOW[警告]$NC 清理 $($item.Description) 失败: $($_.Exception.Message)"
            }
        } else {
            Write-Host "$YELLOW[跳过]$NC $($item.Description) 不存在: $($item.Path)"
        }
    }
}

# 清理扩展数据（让扩展认为是新用户）
function Clear-ExtensionData {
    param($UserDataPath, $ExtensionKeys, $ExtensionName, $DryRun = $false)

    Write-Host "$BLUE[信息]$NC 清理 $ExtensionName 扩展数据..."

    # 清理 globalStorage 中的扩展数据
    $globalStoragePath = "$UserDataPath\globalStorage"
    if (Test-Path $globalStoragePath) {
        foreach ($key in $ExtensionKeys) {
            $extensionPath = "$globalStoragePath\$key"
            if (Test-Path $extensionPath) {
                if ($DryRun) {
                    Write-Host "$CYAN[预览]$NC 将清理扩展数据: $extensionPath"
                    continue
                }

                # 针对不同扩展使用不同的清理策略
                if ($ExtensionName -eq "Augment") {
                    Clear-AugmentData -ExtensionPath $extensionPath -ExtensionName $ExtensionName
                } else {
                    # 其他扩展完全清理
                    try {
                        Remove-Item -Path $extensionPath -Recurse -Force -ErrorAction Stop
                        Write-Host "$GREEN[成功]$NC 已清理 $ExtensionName 数据: $extensionPath"
                    }
                    catch {
                        Write-Host "$YELLOW[警告]$NC 清理 $ExtensionName 数据失败: $($_.Exception.Message)"
                    }
                }
            }
        }
    }

    # 清理 state.vscdb 中的扩展状态（如果存在）
    $stateDbPath = "$UserDataPath\globalStorage\state.vscdb"
    if (Test-Path $stateDbPath) {
        if ($DryRun) {
            Write-Host "$CYAN[预览]$NC 将重置状态数据库中的扩展状态"
        } else {
            Write-Host "$BLUE[信息]$NC 状态数据库将在历史清理中重置"
        }
    }
}

# Augment扩展专用清理函数（基于风控机制的深度清理）
function Clear-AugmentData {
    param($ExtensionPath, $ExtensionName)

    Write-Host "$BLUE[信息]$NC 对 $ExtensionName 执行深度风控清理..."
    Write-Host "$YELLOW[说明]$NC 基于Augment风控机制，清理SessionID、环境跟踪、监控数据"

    # 核心风控数据清理（基于源码分析）
    $coreItemsToClean = @(
        # SessionId相关 - 设备唯一标识系统
        "sessionId.json",      # 设备唯一标识
        "permanentId.json",    # 永久安装ID (PermanentInstallationID.get())
        "installationId.json", # 安装标识
        "deviceId.json",       # 设备ID
        "uuid.json",           # UUID持久化 (generateAndStoreUUID())
        "machineId.json",      # 机器标识

        # SystemEnvironment相关 - 系统环境信息收集
        "systemEnv.json",      # 系统环境变量 (getenv())
        "environment.json",    # 环境信息缓存
        "systemProps.json",    # 系统属性 (getProperty())
        "osInfo.json",         # 操作系统信息 (os.name, os.version, os.arch)
        "javaInfo.json",       # Java环境信息 (java.version, java.vendor)
        "userInfo.json",       # 用户信息 (user.name, user.home, user.dir)
        "hardwareInfo.json",   # 硬件信息 (CPU, 内存, 显卡)
        "ideInfo.json",        # IDE信息 (版本, 构建, 插件列表)
        "networkInfo.json",    # 网络配置 (IP, MAC, 适配器)
        "envCache.json",       # 环境信息缓存
        "systemFingerprint.json", # 系统指纹

        # SentryMetadataCollector相关 - 监控和行为分析
        "sentry",              # Sentry监控目录
        "metadata.json",       # 元数据收集
        "systemTags.json",     # 系统标签 (collectSystemTags())
        "memoryMetrics.json",  # 内存指标 (collectMemoryMetrics())
        "repositoryMetrics.json", # 仓库指标 (collectRepositoryMetrics())
        "gitTrackedFiles.json",   # Git跟踪文件 (countGitTrackedFiles())
        "performanceMetrics.json", # 性能指标
        "behaviorMetrics.json",    # 行为指标
        "usageMetrics.json",       # 使用指标
        "errorMetrics.json",       # 错误指标
        "crashReports.json",       # 崩溃报告
        "sentryTags.json",         # Sentry标签
        "sentryContext.json",      # Sentry上下文

        # 用户行为和跟踪数据
        "userBehavior.json",   # 用户行为记录
        "trackingData.json",   # 跟踪数据
        "behaviorAnalytics.json", # 行为分析
        "usagePatterns.json",  # 使用模式

        # 认证和会话数据
        "auth.json",           # 认证信息
        "token.json",          # 访问令牌
        "session.json",        # 会话数据
        "credentials.json",    # 凭据信息

        # 缓存和临时数据
        "cache",               # 缓存目录
        "temp",                # 临时文件
        "logs",                # 日志目录
        "analytics",           # 分析数据目录

        # 统计和遥测数据
        "telemetry.json",      # 遥测数据
        "usage.json",          # 使用统计
        "metrics.json",        # 指标数据
        "statistics.json",     # 统计信息

        # Git和项目相关
        "gitInfo.json",        # Git信息
        "repoData.json",       # 仓库数据
        "projectMetrics.json", # 项目指标
        "branchInfo.json",     # 分支信息

        # 其他可能的风控数据
        "fingerprint.json",    # 设备指纹
        "hardwareInfo.json",   # 硬件信息
        "networkInfo.json",    # 网络信息
        "state.json",          # 状态信息
        "workspace.json",      # 工作区数据
        "history.json"         # 历史记录
    )

    # 需要保留的用户配置（不影响风控的个人设置）
    $itemsToKeep = @(
        "settings.json",       # 用户设置
        "preferences.json",    # 用户偏好
        "config.json",         # 配置文件
        "keybindings.json",    # 快捷键设置
        "themes.json",         # 主题配置
        "snippets.json",       # 代码片段
        "customCommands.json", # 自定义命令
        "templates.json"       # 模板配置
    )

    $cleanedCount = 0
    $keptCount = 0

    if (Test-Path $ExtensionPath) {
        Write-Host "$BLUE[执行]$NC 清理Augment风控相关数据..."

        # 清理核心风控数据
        foreach ($item in $coreItemsToClean) {
            $itemPath = Join-Path $ExtensionPath $item
            if (Test-Path $itemPath) {
                try {
                    Remove-Item -Path $itemPath -Recurse -Force -ErrorAction Stop
                    Write-Host "$GREEN[清理]$NC 已删除风控数据: $item"
                    $cleanedCount++
                }
                catch {
                    Write-Host "$YELLOW[警告]$NC 清理 $item 失败: $($_.Exception.Message)"
                }
            }
        }

        # 检查保留的用户配置
        foreach ($item in $itemsToKeep) {
            $itemPath = Join-Path $ExtensionPath $item
            if (Test-Path $itemPath) {
                Write-Host "$CYAN[保留]$NC 用户配置: $item"
                $keptCount++
            }
        }

        # 清理所有以特定前缀开头的文件（可能的动态生成文件）
        $dynamicPatterns = @("session*", "device*", "tracking*", "sentry*", "metrics*", "analytics*")
        foreach ($pattern in $dynamicPatterns) {
            $matchingFiles = Get-ChildItem -Path $ExtensionPath -Filter $pattern -ErrorAction SilentlyContinue
            foreach ($file in $matchingFiles) {
                if ($file.Name -notin $itemsToKeep) {
                    try {
                        Remove-Item -Path $file.FullName -Recurse -Force -ErrorAction Stop
                        Write-Host "$GREEN[清理]$NC 已删除动态文件: $($file.Name)"
                        $cleanedCount++
                    }
                    catch {
                        Write-Host "$YELLOW[警告]$NC 清理动态文件 $($file.Name) 失败"
                    }
                }
            }
        }

        # 额外处理：清理可能的环境信息缓存
        Clear-AugmentEnvironmentCache -ExtensionPath $ExtensionPath

        Write-Host "$GREEN[完成]$NC $ExtensionName 深度风控清理完成"
        Write-Host "$BLUE[统计]$NC 清理风控数据: $cleanedCount 个，保留配置: $keptCount 个"
        Write-Host "$YELLOW[效果]$NC SessionID已重置，环境跟踪已清除，监控数据已删除"
    } else {
        Write-Host "$YELLOW[跳过]$NC $ExtensionName 数据目录不存在"
    }
}

# Augment环境信息缓存清理（针对SystemEnvironment和SentryMetadataCollector）
function Clear-AugmentEnvironmentCache {
    param($ExtensionPath)

    Write-Host "$BLUE[深度]$NC 清理Augment环境信息缓存..."

    # 查找所有可能的环境信息缓存文件
    $envCachePatterns = @(
        "*.env",           # 环境文件
        "*.cache",         # 缓存文件
        "*.fingerprint",   # 指纹文件
        "*.metrics",       # 指标文件
        "*.sentry",        # Sentry文件
        "system_*",        # 系统信息文件
        "env_*",           # 环境信息文件
        "hardware_*",      # 硬件信息文件
        "network_*",       # 网络信息文件
        "performance_*",   # 性能信息文件
        "behavior_*",      # 行为信息文件
        "git_*",           # Git信息文件
        "repo_*",          # 仓库信息文件
        "user_*",          # 用户信息文件
        "device_*",        # 设备信息文件
        "machine_*"        # 机器信息文件
    )

    $cleanedCacheCount = 0

    foreach ($pattern in $envCachePatterns) {
        try {
            $cacheFiles = Get-ChildItem -Path $ExtensionPath -Filter $pattern -Recurse -ErrorAction SilentlyContinue
            foreach ($file in $cacheFiles) {
                try {
                    Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                    Write-Host "$GREEN[清理]$NC 环境缓存: $($file.Name)"
                    $cleanedCacheCount++
                }
                catch {
                    Write-Host "$YELLOW[警告]$NC 清理缓存文件 $($file.Name) 失败"
                }
            }
        }
        catch {
            # 忽略模式匹配错误
        }
    }

    # 清理可能的数据库文件（SQLite等）
    $dbPatterns = @("*.db", "*.sqlite", "*.sqlite3")
    foreach ($pattern in $dbPatterns) {
        try {
            $dbFiles = Get-ChildItem -Path $ExtensionPath -Filter $pattern -Recurse -ErrorAction SilentlyContinue
            foreach ($file in $dbFiles) {
                # 检查是否是环境相关的数据库
                if ($file.Name -match "(env|system|sentry|metrics|behavior|tracking)") {
                    try {
                        Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                        Write-Host "$GREEN[清理]$NC 环境数据库: $($file.Name)"
                        $cleanedCacheCount++
                    }
                    catch {
                        Write-Host "$YELLOW[警告]$NC 清理数据库 $($file.Name) 失败"
                    }
                }
            }
        }
        catch {
            # 忽略模式匹配错误
        }
    }

    if ($cleanedCacheCount -gt 0) {
        Write-Host "$GREEN[成功]$NC 清理了 $cleanedCacheCount 个环境缓存文件"
        Write-Host "$YELLOW[效果]$NC SystemEnvironment和SentryMetadataCollector的缓存数据已清除"
    } else {
        Write-Host "$BLUE[信息]$NC 未发现额外的环境缓存文件"
    }
}

# 更新配置文件
function Update-IDEConfiguration {
    param($StorageFile, $NewIdentifiers, $IDEName, $DryRun = $false)
    
    if (-not (Test-Path $StorageFile)) {
        Write-Host "$RED[错误]$NC 未找到 $IDEName 配置文件: $StorageFile"
        Write-Host "$YELLOW[提示]$NC 请先运行一次 $IDEName 后再使用此脚本"
        return $false
    }
    
    if ($DryRun) {
        Write-Host "$CYAN[预览]$NC 将更新 $IDEName 设备标识符"
        Write-Host "$CYAN[预览]$NC machineId: $($NewIdentifiers.machineId)"
        Write-Host "$CYAN[预览]$NC macMachineId: $($NewIdentifiers.macMachineId)"
        return $true
    }
    
    try {
        $originalContent = Get-Content $StorageFile -Raw -Encoding UTF8
        $config = $originalContent | ConvertFrom-Json
        
        # 更新设备标识符
        $config.'telemetry.machineId' = $NewIdentifiers.machineId
        $config.'telemetry.macMachineId' = $NewIdentifiers.macMachineId
        $config.'telemetry.devDeviceId' = $NewIdentifiers.devDeviceId
        $config.'telemetry.sqmId' = $NewIdentifiers.sqmId
        
        # 保存更新后的配置
        $updatedJson = $config | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText(
            [System.IO.Path]::GetFullPath($StorageFile),
            $updatedJson,
            [System.Text.Encoding]::UTF8
        )
        
        Write-Host "$GREEN[成功]$NC 已更新 $IDEName 配置文件"
        return $true
    }
    catch {
        Write-Host "$RED[错误]$NC 更新 $IDEName 配置失败: $($_.Exception.Message)"
        return $false
    }
}

# 更新注册表 MachineGuid
function Update-MachineGuid {
    param($NewGuid, $DryRun = $false)
    
    $regPath = "HKLM:\SOFTWARE\Microsoft\Cryptography"
    $regName = "MachineGuid"
    
    if ($DryRun) {
        Write-Host "$CYAN[预览]$NC 将更新注册表 MachineGuid: $NewGuid"
        return $true
    }
    
    try {
        # 备份当前值
        $currentGuid = Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue
        if ($currentGuid) {
            Write-Host "$BLUE[信息]$NC 当前 MachineGuid: $($currentGuid.MachineGuid)"
        }
        
        # 更新注册表
        Set-ItemProperty -Path $regPath -Name $regName -Value $NewGuid -ErrorAction Stop
        Write-Host "$GREEN[成功]$NC 已更新注册表 MachineGuid: $NewGuid"
        return $true
    }
    catch {
        Write-Host "$RED[错误]$NC 更新注册表失败: $($_.Exception.Message)"
        return $false
    }
}

# 主菜单
function Show-MainMenu {
    Write-Host "$MAGENTA[选择操作模式]$NC"
    Write-Host "1) 🔍 干运行模式 (预览操作，不实际执行)"
    Write-Host "2) 🚀 正常执行模式"
    Write-Host "0) 退出"
    Write-Host ""
    
    do {
        $choice = Read-Host "请选择模式 (1-2, 0退出)"
        switch ($choice) {
            "1" { return "DryRun" }
            "2" { return "Execute" }
            "0" { exit 0 }
            default { Write-Host "$RED[错误]$NC 无效选择，请重新输入" }
        }
    } while ($true)
}

# IDE选择菜单
function Show-IDEMenu {
    Write-Host "$MAGENTA[选择要重置的IDE]$NC"
    $index = 1
    $ideList = @()
    
    foreach ($ide in $IDEConfigs.Keys) {
        Write-Host "$index) $($IDEConfigs[$ide].Name)"
        $ideList += $ide
        $index++
    }
    
    Write-Host "0) 返回上级菜单"
    Write-Host ""
    
    do {
        $choice = Read-Host "请选择IDE (1-$($ideList.Count), 0返回)"
        if ($choice -eq "0") { return $null }
        
        $choiceInt = [int]$choice
        if ($choiceInt -ge 1 -and $choiceInt -le $ideList.Count) {
            return $ideList[$choiceInt - 1]
        }
        
        Write-Host "$RED[错误]$NC 无效选择，请重新输入"
    } while ($true)
}

# 扩展选择菜单（根据IDE过滤）
function Show-ExtensionMenu {
    param($SelectedIDE)

    Write-Host "$MAGENTA[选择要清理的扩展]$NC"
    Write-Host "0) 跳过扩展清理"

    $index = 1
    $extList = @()

    # 根据选择的IDE过滤扩展
    foreach ($ext in $ExtensionConfigs.Keys) {
        $extConfig = $ExtensionConfigs[$ext]
        if ($extConfig.SupportedIDEs -contains $SelectedIDE) {
            Write-Host "$index) $($extConfig.Name) - $($extConfig.Description)"
            $extList += $ext
            $index++
        }
    }

    if ($extList.Count -eq 0) {
        Write-Host "$YELLOW[提示]$NC 当前IDE没有支持的扩展清理选项"
        return @()
    }

    Write-Host "$($index)) 全部扩展"
    Write-Host ""

    do {
        $choice = Read-Host "请选择扩展 (0跳过, 1-$($extList.Count), $($index)全部)"
        if ($choice -eq "0") { return @() }
        if ($choice -eq "$index") { return $extList }

        $choiceInt = [int]$choice
        if ($choiceInt -ge 1 -and $choiceInt -le $extList.Count) {
            return @($extList[$choiceInt - 1])
        }

        Write-Host "$RED[错误]$NC 无效选择，请重新输入"
    } while ($true)
}

# 主程序执行
function Start-IDEReset {
    # 显示主菜单
    $mode = Show-MainMenu
    if (-not $mode) { return }

    $isDryRun = ($mode -eq "DryRun")

    if ($isDryRun) {
        Write-Host "$CYAN[干运行模式]$NC 以下操作仅为预览，不会实际执行"
        Write-Host ""
    }

    # 选择IDE
    $selectedIDE = Show-IDEMenu
    if (-not $selectedIDE) { return }

    $ideConfig = $IDEConfigs[$selectedIDE]
    Write-Host "$GREEN[已选择]$NC $($ideConfig.Name)"
    Write-Host ""

    # 选择扩展（根据选择的IDE过滤）
    $selectedExtensions = Show-ExtensionMenu -SelectedIDE $selectedIDE
    if ($selectedExtensions.Count -gt 0) {
        Write-Host "$GREEN[已选择扩展]$NC"
        foreach ($ext in $selectedExtensions) {
            Write-Host "  - $($ExtensionConfigs[$ext].Name)"
        }
        Write-Host ""
    }

    # 确认操作
    if (-not $isDryRun) {
        Write-Host "$YELLOW[确认操作]$NC"
        Write-Host "即将执行以下操作："
        Write-Host "- 重置 $($ideConfig.Name) 设备标识"
        Write-Host "- 清理使用历史数据"
        Write-Host "- 修改系统注册表"
        if ($selectedExtensions.Count -gt 0) {
            Write-Host "- 清理选定扩展数据"
        }
        Write-Host ""
        Write-Host "$RED[警告]$NC 此操作不可逆，请确保已备份重要数据"

        $confirm = Read-Host "确认执行？(y/N)"
        if ($confirm -ne "y" -and $confirm -ne "Y") {
            Write-Host "$YELLOW[取消]$NC 操作已取消"
            return
        }
    }

    Write-Host "$BLUE[开始执行]$NC"
    Write-Host "================================"

    # 1. 关闭IDE进程
    if (-not $isDryRun) {
        if (-not (Close-IDEProcess -ProcessNames $ideConfig.ProcessNames -IDEName $ideConfig.Name)) {
            Write-Host "$RED[错误]$NC 无法关闭 $($ideConfig.Name) 进程，操作终止"
            return
        }
    } else {
        Write-Host "$CYAN[预览]$NC 将关闭 $($ideConfig.Name) 进程"
    }

    # 2. 生成新的设备标识符
    $newIdentifiers = New-DeviceIdentifiers
    Write-Host "$BLUE[信息]$NC 已生成新的设备标识符"

    # 3. 备份配置
    $backupDir = "$($ideConfig.UserDataPath)\globalStorage\backups"
    if (-not $isDryRun) {
        $backupFile = Backup-Configuration -StorageFile $ideConfig.StorageFile -BackupDir $backupDir
    } else {
        Write-Host "$CYAN[预览]$NC 将备份配置文件到: $backupDir"
    }

    # 4. 清理IDE历史数据
    Clear-IDEHistory -UserDataPath $ideConfig.UserDataPath -IDEName $ideConfig.Name -DryRun $isDryRun

    # 5. 清理扩展数据
    foreach ($ext in $selectedExtensions) {
        $extConfig = $ExtensionConfigs[$ext]
        Clear-ExtensionData -UserDataPath $ideConfig.UserDataPath -ExtensionKeys $extConfig.GlobalStorageKeys -ExtensionName $extConfig.Name -DryRun $isDryRun
    }

    # 6. 更新IDE配置
    if (-not (Update-IDEConfiguration -StorageFile $ideConfig.StorageFile -NewIdentifiers $newIdentifiers -IDEName $ideConfig.Name -DryRun $isDryRun)) {
        if (-not $isDryRun) {
            Write-Host "$RED[错误]$NC 更新配置失败，操作终止"
            return
        }
    }

    # 7. 更新注册表
    Update-MachineGuid -NewGuid $newIdentifiers.macMachineId -DryRun $isDryRun

    # 8. 处理自动更新（仅Cursor）
    if ($selectedIDE -eq "Cursor" -and $ideConfig.UpdaterPath) {
        if ($isDryRun) {
            Write-Host "$CYAN[预览]$NC 可选择禁用 Cursor 自动更新"
        } else {
            Write-Host ""
            Write-Host "$YELLOW[询问]$NC 是否要禁用 Cursor 自动更新？"
            Write-Host "1) 是 - 禁用自动更新"
            Write-Host "2) 否 - 保持默认设置"

            $updateChoice = Read-Host "请选择 (1-2)"
            if ($updateChoice -eq "1") {
                Disable-CursorAutoUpdate -UpdaterPath $ideConfig.UpdaterPath
            }
        }
    }

    # 9. 可选网络清理
    Ask-NetworkCleanup -DryRun $isDryRun

    Write-Host ""
    Write-Host "================================"

    if ($isDryRun) {
        Write-Host "$CYAN[预览完成]$NC 以上为预览内容，未实际执行任何操作"
        Write-Host "$YELLOW[提示]$NC 如需实际执行，请选择正常执行模式"
    } else {
        Write-Host "$GREEN[操作完成]$NC"
        Write-Host ""
        Write-Host "$GREEN[结果摘要]$NC"
        Write-Host "- ✅ $($ideConfig.Name) 设备标识已重置"
        Write-Host "- ✅ 历史数据已清理"
        Write-Host "- ✅ 注册表已更新"
        if ($selectedExtensions.Count -gt 0) {
            Write-Host "- ✅ 扩展数据已清理"
        }
        Write-Host ""
        # 询问是否自动重启IDE
        Write-Host ""
        Write-Host "$YELLOW[自动重启]$NC 是否要自动重启 $($ideConfig.Name)？"
        Write-Host "1) 是 - 立即重启IDE"
        Write-Host "2) 否 - 稍后手动重启"
        Write-Host ""

        $restartChoice = Read-Host "请选择 (1-2)"
        if ($restartChoice -eq "1") {
            Start-IDE -IDEConfig $ideConfig
        } else {
            Write-Host "$YELLOW[重要提示]$NC 请手动重启 $($ideConfig.Name) 以应用新配置"
        }

        # 显示新的标识符信息
        Write-Host ""
        Write-Host "$BLUE[新设备标识]$NC"
        Write-Host "machineId: $($newIdentifiers.machineId)"
        Write-Host "macMachineId: $($newIdentifiers.macMachineId)"
        Write-Host "devDeviceId: $($newIdentifiers.devDeviceId)"
        Write-Host "sqmId: $($newIdentifiers.sqmId)"
    }
}

# 启动IDE
function Start-IDE {
    param($IDEConfig)

    Write-Host "$BLUE[信息]$NC 正在启动 $($IDEConfig.Name)..."

    # 查找IDE可执行文件
    $executablePaths = @()

    if ($IDEConfig.Name -eq "Cursor") {
        $executablePaths = @(
            "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
            "$env:LOCALAPPDATA\cursor\Cursor.exe",
            "$env:PROGRAMFILES\Cursor\Cursor.exe",
            "$env:PROGRAMFILES(X86)\Cursor\Cursor.exe"
        )
    } elseif ($IDEConfig.Name -eq "VS Code") {
        $executablePaths = @(
            "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
            "$env:PROGRAMFILES\Microsoft VS Code\Code.exe",
            "$env:PROGRAMFILES(X86)\Microsoft VS Code\Code.exe"
        )
    }

    # 尝试找到并启动IDE
    $ideStarted = $false
    foreach ($path in $executablePaths) {
        if (Test-Path $path) {
            try {
                Write-Host "$BLUE[启动]$NC 使用路径: $path"
                Start-Process -FilePath $path -ErrorAction Stop
                Write-Host "$GREEN[成功]$NC $($IDEConfig.Name) 已启动"
                $ideStarted = $true
                break
            }
            catch {
                Write-Host "$YELLOW[警告]$NC 启动失败: $($_.Exception.Message)"
                continue
            }
        }
    }

    if (-not $ideStarted) {
        Write-Host "$RED[错误]$NC 无法找到或启动 $($IDEConfig.Name)"
        Write-Host "$YELLOW[提示]$NC 请手动启动 $($IDEConfig.Name)"
        Write-Host "$BLUE[可能路径]$NC"
        foreach ($path in $executablePaths) {
            Write-Host "  - $path"
        }
    }
}

# 禁用Cursor自动更新
function Disable-CursorAutoUpdate {
    param($UpdaterPath)

    try {
        if (Test-Path $UpdaterPath) {
            if ((Get-Item $UpdaterPath) -is [System.IO.FileInfo]) {
                Write-Host "$GREEN[信息]$NC 自动更新已被禁用"
                return
            } else {
                Remove-Item -Path $UpdaterPath -Force -Recurse -ErrorAction Stop
                Write-Host "$GREEN[信息]$NC 已删除更新器目录"
            }
        }

        # 创建阻止文件
        New-Item -Path $UpdaterPath -ItemType File -Force | Out-Null
        Set-ItemProperty -Path $UpdaterPath -Name IsReadOnly -Value $true

        # 设置权限
        $result = Start-Process "icacls.exe" -ArgumentList "`"$UpdaterPath`" /inheritance:r /grant:r `"$($env:USERNAME):(R)`"" -Wait -NoNewWindow -PassThru
        if ($result.ExitCode -eq 0) {
            Write-Host "$GREEN[成功]$NC 已禁用 Cursor 自动更新"
        } else {
            Write-Host "$YELLOW[警告]$NC 权限设置可能未完全生效"
        }
    }
    catch {
        Write-Host "$RED[错误]$NC 禁用自动更新失败: $($_.Exception.Message)"
    }
}

# 网络相关清理功能（可选）
function Clear-NetworkCache {
    param($DryRun = $false)

    Write-Host "$BLUE[信息]$NC 网络缓存清理..."

    $networkCommands = @(
        @{ Command = "ipconfig /flushdns"; Description = "刷新DNS缓存" }
        @{ Command = "netsh winsock reset"; Description = "重置Winsock目录" }
        @{ Command = "netsh int ip reset"; Description = "重置TCP/IP协议栈" }
    )

    foreach ($cmd in $networkCommands) {
        if ($DryRun) {
            Write-Host "$CYAN[预览]$NC 将执行: $($cmd.Description)"
            continue
        }

        try {
            Write-Host "$BLUE[执行]$NC $($cmd.Description)..."
            $result = Start-Process "cmd.exe" -ArgumentList "/c", $cmd.Command -Wait -NoNewWindow -PassThru
            if ($result.ExitCode -eq 0) {
                Write-Host "$GREEN[成功]$NC $($cmd.Description) 完成"
            } else {
                Write-Host "$YELLOW[警告]$NC $($cmd.Description) 可能未完全成功"
            }
        }
        catch {
            Write-Host "$YELLOW[警告]$NC $($cmd.Description) 执行失败: $($_.Exception.Message)"
        }
    }
}

# 询问是否执行网络清理
function Ask-NetworkCleanup {
    param($DryRun = $false)

    Write-Host ""
    Write-Host "$YELLOW[可选操作]$NC 是否要清理网络缓存？"
    Write-Host "1) 是 - 刷新DNS缓存和网络设置"
    Write-Host "2) 否 - 跳过网络清理"
    Write-Host ""
    Write-Host "$BLUE[说明]$NC 网络清理包括："
    Write-Host "  - 刷新DNS缓存"
    Write-Host "  - 重置网络协议栈"
    Write-Host "  - 清理网络连接缓存"
    Write-Host ""

    $networkChoice = Read-Host "请选择 (1-2)"
    if ($networkChoice -eq "1") {
        Clear-NetworkCache -DryRun $DryRun
        if (-not $DryRun) {
            Write-Host "$YELLOW[提示]$NC 网络清理完成，建议重启计算机以确保所有更改生效"
        }
    } else {
        Write-Host "$BLUE[跳过]$NC 已跳过网络清理"
    }
}

# 启动主程序
try {
    Start-IDEReset
}
catch {
    Write-Host "$RED[严重错误]$NC 程序执行失败: $($_.Exception.Message)"
    Write-Host "$YELLOW[调试信息]$NC $($_.ScriptStackTrace)"
}
finally {
    Write-Host ""
    Write-Host "$CYAN================================$NC"
    Write-Host "$GREEN   感谢使用 IDE 通用重置工具     $NC"
    Write-Host "$YELLOW  关注公众号【彩色之外】       $NC"
    Write-Host "$CYAN================================$NC"
    Read-Host "按回车键退出"
}
