# Ferramenta Universal de Reset para IDEs - Versão Ultimate

```powershell
# Ferramenta de reset para IDEs - Versão Ultimate
# Suporta múltiplas IDEs e limpeza profunda de extensões, resolve problemas de exibição de cores e inclui reinício automático
# Configura codificação de saída para UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Verifica privilégios de administrador
function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-AdminRights)) {
    Write-Host "[ERRO] Este script requer privilégios de administrador" -ForegroundColor Red
    Write-Host "[DICA] Execute o PowerShell como administrador e tente novamente" -ForegroundColor Yellow
    Read-Host "Pressione Enter para sair"
    exit 1
}

# Exibe título
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Ferramenta Universal de Reset para IDEs v3.0" -ForegroundColor Green
Write-Host "   Suporta Cursor/VS Code + Limpeza profunda" -ForegroundColor Yellow
Write-Host "   Compatível com cores + Reinício automático" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Configurações das IDEs
$IDEConfigs = @{
    'Cursor' = @{
        'Name' = 'Cursor'
        'ProcessNames' = @('Cursor', 'cursor')
        'UserDataPath' = "$env:APPDATA\Cursor\User"
        'StorageFile' = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
        'AugmentPath' = "$env:APPDATA\Cursor\User\globalStorage\augmentcode.augment"
        'ExePaths' = @(
            "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
            "$env:LOCALAPPDATA\cursor\Cursor.exe",
            "$env:PROGRAMFILES\Cursor\Cursor.exe"
        )
    }
    'VSCode' = @{
        'Name' = 'Visual Studio Code'
        'ProcessNames' = @('Code', 'code')
        'UserDataPath' = "$env:APPDATA\Code\User"
        'StorageFile' = "$env:APPDATA\Code\User\globalStorage\storage.json"
        'AugmentPath' = "$env:APPDATA\Code\User\globalStorage\augmentcode.augment"
        'ExePaths' = @(
            "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
            "$env:PROGRAMFILES\Microsoft VS Code\Code.exe",
            "$env:PROGRAMFILES(X86)\Microsoft VS Code\Code.exe"
        )
    }
}

# Configurações das extensões
$ExtensionConfigs = @{
    'Augment' = @{
        'Name' = 'Augment - Extensão de IA'
        'GlobalStorageKeys' = @('augmentcode.augment')
        'DeepClean' = $true  # Requer limpeza profunda
    }
    'Codeium' = @{
        'Name' = 'Codeium - Assistente de IA'
        'GlobalStorageKeys' = @('codeium.codeium')
        'DeepClean' = $false
    }
    'Copilot' = @{
        'Name' = 'GitHub Copilot - Assistente de IA'
        'GlobalStorageKeys' = @('github.copilot', 'github.copilot-chat')
        'DeepClean' = $false
    }
}

# Menu de seleção de modo
Write-Host "[Selecione o modo]" -ForegroundColor Magenta
Write-Host "1) 🔍 Modo simulação (apenas visualização)"
Write-Host "2) 🚀 Modo de execução normal"
Write-Host "0) Sair"
Write-Host ""

do {
    $modeChoice = Read-Host "Escolha o modo (1-2, 0 para sair)"
    switch ($modeChoice) {
        "1" { $isDryRun = $true; break }
        "2" { $isDryRun = $false; break }
        "0" { exit 0 }
        default { Write-Host "[ERRO] Opção inválida" -ForegroundColor Red }
    }
} while (-not $modeChoice -or $modeChoice -notin @("1", "2"))

if ($isDryRun) {
    Write-Host "[MODO SIMULAÇÃO] Nenhuma ação será executada" -ForegroundColor Cyan
    Write-Host ""
}

# Menu de seleção de IDE
Write-Host "[Selecione a IDE]" -ForegroundColor Magenta
Write-Host "1) Cursor"
Write-Host "2) Visual Studio Code"
Write-Host "0) Voltar"
Write-Host ""

do {
    $ideChoice = Read-Host "Escolha a IDE (1-2, 0 para voltar)"
    switch ($ideChoice) {
        "1" { $selectedIDE = "Cursor"; break }
        "2" { $selectedIDE = "VSCode"; break }
        "0" { exit 0 }
        default { Write-Host "[ERRO] Opção inválida" -ForegroundColor Red }
    }
} while (-not $selectedIDE)

$ideConfig = $IDEConfigs[$selectedIDE]
Write-Host "[Selecionado] $($ideConfig.Name)" -ForegroundColor Green
Write-Host ""

# Menu de seleção de extensões
Write-Host "[Selecione extensões]" -ForegroundColor Magenta
Write-Host "0) Pular limpeza"
Write-Host "1) Augment (limpeza profunda)"
Write-Host "2) Codeium"
Write-Host "3) GitHub Copilot"
Write-Host "4) Todas as extensões"
Write-Host ""

do {
    $extChoice = Read-Host "Escolha (0-4)"
    $selectedExtensions = @()
    switch ($extChoice) {
        "0" { break }
        "1" { $selectedExtensions = @('Augment'); break }
        "2" { $selectedExtensions = @('Codeium'); break }
        "3" { $selectedExtensions = @('Copilot'); break }
        "4" { $selectedExtensions = @('Augment', 'Codeium', 'Copilot'); break }
        default { Write-Host "[ERRO] Opção inválida" -ForegroundColor Red }
    }
} while ($extChoice -notin @("0", "1", "2", "3", "4"))

if ($selectedExtensions.Count -gt 0) {
    Write-Host "[Extensões selecionadas]" -ForegroundColor Green
    foreach ($ext in $selectedExtensions) {
        $extConfig = $ExtensionConfigs[$ext]
        if ($extConfig.DeepClean) {
            Write-Host "  - $($extConfig.Name) (limpeza profunda)" -ForegroundColor Yellow
        } else {
            Write-Host "  - $($extConfig.Name)"
        }
    }
    Write-Host ""
}

# Confirmação
if (-not $isDryRun) {
    Write-Host "[Confirmação]" -ForegroundColor Yellow
    Write-Host "Ações que serão executadas:"
    Write-Host "- Fechar $($ideConfig.Name)"
    Write-Host "- Resetar identificadores"
    Write-Host "- Limpar histórico"
    Write-Host "- Modificar registro"
    if ($selectedExtensions.Count -gt 0) {
        Write-Host "- Limpar extensões"
        if ('Augment' -in $selectedExtensions) {
            Write-Host "  * Limpeza profunda do Augment"
        }
    }
    Write-Host ""
    Write-Host "[AVISO] Esta ação não pode ser desfeita" -ForegroundColor Red

    $confirm = Read-Host "Confirmar? (s/N)"
    if ($confirm -ne "s" -and $confirm -ne "S") {
        Write-Host "[Cancelado] Operação abortada" -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "[Iniciando] Reset da IDE" -ForegroundColor Blue
Write-Host "============================================"

# 1. Fechar IDE
if ($isDryRun) {
    Write-Host "[Simulação] Fechando $($ideConfig.Name)" -ForegroundColor Cyan
} else {
    Write-Host "[Passo 1] Fechando $($ideConfig.Name)..." -ForegroundColor Blue
    foreach ($processName in $ideConfig.ProcessNames) {
        $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
        if ($process) {
            Write-Host "[AVISO] Fechando $processName..." -ForegroundColor Yellow
            Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
            Write-Host "[OK] $processName fechado" -ForegroundColor Green
        }
    }
}

# 2. Gerar novos IDs
Write-Host ""
if ($isDryRun) {
    Write-Host "[Simulação] Gerando novos IDs" -ForegroundColor Cyan
} else {
    Write-Host "[Passo 2] Gerando identificadores..." -ForegroundColor Blue
}

$newIdentifiers = @{
    'machineId' = "auth0|user_" + (-join ((1..32) | ForEach-Object { '{0:x}' -f (Get-Random -Maximum 16) }))
    'macMachineId' = [System.Guid]::NewGuid().ToString()
    'devDeviceId' = [System.Guid]::NewGuid().ToString()
    'sqmId' = [System.Guid]::NewGuid().ToString().ToUpper()
    'sessionId' = [System.Guid]::NewGuid().ToString()
    'permanentId' = [System.Guid]::NewGuid().ToString()
}

if (-not $isDryRun) {
    Write-Host "[OK] Novos IDs gerados" -ForegroundColor Green
}

# 3. Limpar histórico
Write-Host ""
if ($isDryRun) {
    Write-Host "[Simulação] Limpando histórico" -ForegroundColor Cyan
} else {
    Write-Host "[Passo 3] Limpando dados..." -ForegroundColor Blue
}

$itemsToClean = @(
    @{ Path = "$($ideConfig.UserDataPath)\globalStorage\state.vscdb"; Description = "Banco de dados" }
    @{ Path = "$($ideConfig.UserDataPath)\globalStorage\state.vscdb.backup"; Description = "Backup" }
    @{ Path = "$($ideConfig.UserDataPath)\History"; Description = "Histórico" }
    @{ Path = "$($ideConfig.UserDataPath)\workspaceStorage"; Description = "Workspaces" }
    @{ Path = "$($ideConfig.UserDataPath)\logs"; Description = "Logs" }
)

foreach ($item in $itemsToClean) {
    if ($isDryRun) {
        if (Test-Path $item.Path) {
            Write-Host "[Simulação] Limpando: $($item.Description)" -ForegroundColor Cyan
        }
    } else {
        if (Test-Path $item.Path) {
            try {
                Remove-Item -Path $item.Path -Recurse -Force -ErrorAction Stop
                Write-Host "[OK] Limpo: $($item.Description)" -ForegroundColor Green
            }
            catch {
                Write-Host "[AVISO] Falha ao limpar: $($item.Description)" -ForegroundColor Yellow
            }
        }
    }
}

# 4. Limpar extensões
if ($selectedExtensions.Count -gt 0) {
    Write-Host ""
    if ($isDryRun) {
        Write-Host "[Simulação] Limpando extensões" -ForegroundColor Cyan
    } else {
        Write-Host "[Passo 4] Limpando extensões..." -ForegroundColor Blue
    }

    foreach ($ext in $selectedExtensions) {
        $extConfig = $ExtensionConfigs[$ext]

        if ($ext -eq 'Augment' -and $extConfig.DeepClean) {
            # Limpeza profunda do Augment
            if ($isDryRun) {
                Write-Host "[Simulação] Limpeza profunda do Augment" -ForegroundColor Cyan
            } else {
                Write-Host "[Limpeza profunda] Augment..." -ForegroundColor Yellow

                if (Test-Path $ideConfig.AugmentPath) {
                    $augmentRiskFiles = @(
                        # Arquivos de controle
                        "sessionId.json", "permanentId.json", "installationId.json", "deviceId.json",
                        "uuid.json", "machineId.json", "uniqueId.json", "clientId.json",
                        # Arquivos de sistema
                        "systemEnv.json", "environment.json", "systemProps.json", "osInfo.json",
                        "javaInfo.json", "userInfo.json", "hardwareInfo.json", "ideInfo.json",
                        "networkInfo.json", "envCache.json", "systemFingerprint.json",
                        # Arquivos de monitoramento
                        "sentry", "systemTags.json", "memoryMetrics.json", "repositoryMetrics.json",
                        "gitTrackedFiles.json", "performanceData.json", "errorMetrics.json",
                        "usageStats.json", "behaviorAnalytics.json", "crashReports.json",
                        # Arquivos Git
                        "gitInfo.json", "repoData.json", "projectMetrics.json", "branchInfo.json",
                        "commitHistory.json", "remoteUrls.json", "repoFingerprint.json",
                        # Arquivos de autenticação
                        "auth.json", "token.json", "session.json", "credentials.json",
                        "loginState.json", "userSession.json", "authCache.json",
                        # Arquivos temporários
                        "cache", "temp", "logs", "analytics", "telemetry.json",
                        "usage.json", "metrics.json", "statistics.json",
                        # Arquivos de identificação
                        "fingerprint.json", "deviceFingerprint.json", "browserFingerprint.json",
                        "canvasFingerprint.json", "audioFingerprint.json", "screenFingerprint.json",
                        # Arquivos de rede
                        "networkFingerprint.json", "ipInfo.json", "connectionMetrics.json",
                        "dnsCache.json", "proxyInfo.json", "networkAdapter.json",
                        # Outros
                        "state.json", "workspace.json", "history.json", "tracking.json",
                        "monitoring.json", "surveillance.json", "detection.json"
                    )

                    $cleanedCount = 0
                    foreach ($riskFile in $augmentRiskFiles) {
                        $riskPath = Join-Path $ideConfig.AugmentPath $riskFile
                        if (Test-Path $riskPath) {
                            try {
                                if ((Get-Item $riskPath) -is [System.IO.DirectoryInfo]) {
                                    Remove-Item -Path $riskPath -Recurse -Force -ErrorAction Stop
                                } else {
                                    Remove-Item -Path $riskPath -Force -ErrorAction Stop
                                }
                                $cleanedCount++
                            }
                            catch {
                                # Ignora erros
                            }
                        }
                    }

                    # Limpeza por padrão
                    $patterns = @("*.env", "*.cache", "*.fingerprint", "*.metrics", "*.tracking", "*.sentry", "*session*", "*device*", "*system*", "*hardware*", "*network*")
                    foreach ($pattern in $patterns) {
                        try {
                            $files = Get-ChildItem -Path $ideConfig.AugmentPath -Filter $pattern -Recurse -ErrorAction SilentlyContinue
                            foreach ($file in $files) {
                                if ($file.Name -notmatch "(settings|config|preferences|keybindings|snippets|themes)") {
                                    try {
                                        Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                                        $cleanedCount++
                                    }
                                    catch { }
                                }
                            }
                        }
                        catch { }
                    }

                    Write-Host "[OK] Augment limpo ($cleanedCount arquivos)" -ForegroundColor Green
                    Write-Host "[Efeito] IDs resetados, rastreamento removido" -ForegroundColor Yellow
                } else {
                    Write-Host "[Pulado] Diretório do Augment não encontrado" -ForegroundColor Yellow
                }
            }
        } else {
            # Limpeza normal de extensões
            foreach ($key in $extConfig.GlobalStorageKeys) {
                $extensionPath = "$($ideConfig.UserDataPath)\globalStorage\$key"
                if ($isDryRun) {
                    if (Test-Path $extensionPath) {
                        Write-Host "[Simulação] Limpando $($extConfig.Name)" -ForegroundColor Cyan
                    }
                } else {
                    if (Test-Path $extensionPath) {
                        try {
                            Remove-Item -Path $extensionPath -Recurse -Force -ErrorAction Stop
                            Write-Host "[OK] $($extConfig.Name) limpo" -ForegroundColor Green
                        }
                        catch {
                            Write-Host "[AVISO] Falha ao limpar $($extConfig.Name)" -ForegroundColor Yellow
                        }
                    } else {
                        Write-Host "[Pulado] $($extConfig.Name) não encontrado" -ForegroundColor Yellow
                    }
                }
            }
        }
    }
}

# 5. Atualizar configurações
Write-Host ""
if ($isDryRun) {
    Write-Host "[Simulação] Atualizando IDs" -ForegroundColor Cyan
    Write-Host "[Simulação] machineId: $($newIdentifiers.machineId)" -ForegroundColor Cyan
    Write-Host "[Simulação] macMachineId: $($newIdentifiers.macMachineId)" -ForegroundColor Cyan
}
