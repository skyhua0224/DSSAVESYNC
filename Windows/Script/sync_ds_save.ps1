# 设置脚本编码和错误处理
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 首先定义基本路径变量
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath
$syncFolder = Split-Path -Parent (Split-Path -Parent $scriptDir)
$logFile = Join-Path $syncFolder "Windows\sync_log.txt"
$defaultSavePath = Join-Path $env:LOCALAPPDATA "KojimaProductions\DeathStrandingDC"
$syncSavesFolder = Join-Path $syncFolder "Windows\Saves"
$backupFolder = Join-Path $syncSavesFolder "backups"
$saveTypes = @("manualsave", "autosave", "quicksave")

# 初始化基本函数
function Write-Log {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -Append -FilePath $logFile -Encoding UTF8

    switch ($Type) {
        "Success" { Write-Host -ForegroundColor Green $Message }
        "Warning" { Write-Host -ForegroundColor Yellow $Message }
        "Error" { Write-Host -ForegroundColor Red $Message }
        Default { Write-Host $Message }
    }
}

function Get-Confirmation {
    param([string]$Prompt)
    Write-Host -ForegroundColor Yellow "$Prompt" -NoNewline
    $response = Read-Host
    return $response -match "^[Yy]"
}

# 配置文件路径和获取配置
$configPath = Join-Path $syncFolder "config.json"

function Get-UserConfig {
    if (Test-Path $configPath) {
        try {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            return $config
        }
        catch {
            Write-Host "配置文件损坏，将创建新配置" -ForegroundColor Red
        }
    }
    
    return @{
        steamID            = ""
        gameExecutablePath = ""
        language           = ""
    }
}

# 保存配置
function Save-UserConfig {
    param($config)
    $config | ConvertTo-Json | Out-File -FilePath $configPath -Encoding UTF8
    Write-Log "配置已更新并保存" "Info"
}

# 初始化配置
$config = Get-UserConfig

# 检测并选择SteamID文件夹
function Find-SteamIDFolder {
    # 如果配置中已有steamID，且文件夹存在，直接使用
    if ($config.steamID -and (Test-Path (Join-Path $defaultSavePath $config.steamID))) {
        Write-Log "使用配置中的SteamID: $($config.steamID)" "Info"
        return $config.steamID
    }
    
    # 查找所有可能的SteamID文件夹
    if (Test-Path $defaultSavePath) {
        $steamFolders = Get-ChildItem -Path $defaultSavePath -Directory
        
        if ($steamFolders.Count -eq 0) {
            Write-Host -ForegroundColor Red (Get-Translation "NoSteamFoldersFound")
            return $null
        }
        elseif ($steamFolders.Count -eq 1) {
            # 只有一个文件夹，直接使用
            $steamID = $steamFolders[0].Name
            $config.steamID = $steamID
            Save-UserConfig $config
            return $steamID
        }
        else {
            # 多个文件夹，让用户选择
            Write-Host "`n" -ForegroundColor Yellow (Get-Translation "MultipleSteamFolders")
            for ($i = 0; $i -lt $steamFolders.Count; $i++) {
                Write-Host "$($i+1)) $($steamFolders[$i].Name)"
            }
            
            $choice = Read-Host (Get-Translation "SelectChoice")
            $index = [int]$choice - 1
            
            if ($index -ge 0 -and $index -lt $steamFolders.Count) {
                $steamID = $steamFolders[$index].Name
                $config.steamID = $steamID
                Save-UserConfig $config
                return $steamID
            }
            else {
                Write-Host -ForegroundColor Red (Get-Translation "InvalidChoice")
                return $null
            }
        }
    }
    else {
        Write-Host -ForegroundColor Red (Get-Translation "SavePathNotFound" -f $defaultSavePath)
        return $null
    }
}

# 界面颜色主题

$theme = @{

    Title       = @{ ForegroundColor = 'Cyan' }

    Prompt      = @{ ForegroundColor = 'Yellow' }

    Info        = @{ ForegroundColor = 'White' }

    Success     = @{ ForegroundColor = 'Green' }

    Warning     = @{ ForegroundColor = 'Yellow' }

    Error       = @{ ForegroundColor = 'Red' }

    TableHeader = @{ ForegroundColor = 'Cyan' }

    NewerSave   = @{ ForegroundColor = 'Green' }

    OlderSave   = @{ ForegroundColor = 'Red' }

    Missing     = @{ ForegroundColor = 'Red' }

}



# 启用ANSI转义码支持（兼容PowerShell 5.1和7+版本）

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if ($PSVersionTable.PSVersion.Major -ge 7) {

    $PSStyle.OutputRendering = 'PlainText'

}
else {

    # 为旧版本启用虚拟终端支持

    $nativeUtilities = @'

[DllImport("kernel32.dll")]

public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);

[DllImport("kernel32.dll")]

public static extern IntPtr GetStdHandle(int nStdHandle);

'@

    $consoleType = Add-Type -MemberDefinition $nativeUtilities -Name 'ConsoleUtils' -Namespace 'Win32' -PassThru

    $handle = $consoleType::GetStdHandle(-11) # STD_OUTPUT_HANDLE

    $consoleType::SetConsoleMode($handle, 0x0004) # ENABLE_VIRTUAL_TERMINAL_PROCESSING

}



# 颜色和样式定义（兼容旧版本）

$ESC = [char]27

$CYAN = "$ESC[0;36m"

$YELLOW = "$ESC[1;33m"

$BRIGHT_GREEN = "$ESC[1;32m"

$GREEN = "$ESC[0;32m"

$RED = "$ESC[0;31m"

$WHITE = "$ESC[0;37m"

$GRAY = "$ESC[0;90m"

$BLUE = "$ESC[0;34m"

$NC = "$ESC[0m"

$BOLD = "$ESC[1m"

$ARROW = "→"


# 检查配置文件中是否已有语言选择
$language = $config.language
if (-not $language) {
    Write-Host "Please select your language / 请选择您的语言:"
    Write-Host "1) English"
    Write-Host "2) 中文 (Chinese)"
    $langChoice = Read-Host "Enter your choice (1 or 2)"
    
    $language = switch ($langChoice) {
        "1" { "en" }
        "2" { "zh" }
        Default {
            Write-Host "Invalid choice. Defaulting to English." -ForegroundColor Red
            "en" # Default to English
        }
    }
    
    # 保存语言选择到配置
    $config.language = $language
    Save-UserConfig $config
}

# 根据语言选择设置翻译 (Set translations based on language selection)
$translations = @{
    "en" = @{
        Title                   = "Death Stranding Save Sync Tool"
        Device                  = "Current Device: Windows"
        SaveType                = "Save Type"
        LocalSave               = "Local Save"
        WinSync                 = "Windows Sync"
        MacSync                 = "Mac Sync"
        None                    = "NONE"
        NoSave                  = "No Save"
        FileName                = "└─File Name"
        ManualSave              = "Manual Save"
        AutoSave                = "Auto Save"
        QuickSave               = "Quick Save"
        ImportMacTitle          = "Select Mac save type to import:"
        ImportManual            = "1) Import Manual Save"
        ImportAuto              = "2) Import Auto Save"
        ImportQuick             = "3) Import Quick Save"
        ImportAll               = "4) Import All Mac Saves"
        ReturnToMenu            = "5) Return to Main Menu"
        InvalidChoice           = "Invalid choice"
        ImportAllMacPrep        = "Preparing to import all types of Mac saves..."
        ImportSteps             = "Import Steps:"
        ImportManualStep        = "1. Import Manual Save"
        ImportAutoStep          = "2. Import Auto Save"
        ImportQuickStep         = "3. Import Quick Save"
        Processing              = "====== Processing {0} ({1}/{2}) ======"
        CheckLocalDir           = "Checking and creating local save directory"
        SourceNotFound          = "✗ {0} import failed - Source file not found"
        BackupOriginal          = "Backing up original save"
        CopySave                = "Copying save"
        ImportSuccess           = "✓ {0} import successful"
        BatchImportComplete     = "Batch import complete: Successfully imported {0}/{1} save types"
        ImportMacSavePrep       = "Preparing to import Mac {0} save..."
        CheckMacSave            = "1. Check Mac Save"
        BackupExisting          = "2. Back up existing save"
        CreateNewSave           = "3. Create new save package"
        ImportSaveFile          = "4. Import save file"
        VerifyImport            = "5. Verify import result"
        CheckSource             = "[Step 1/5] Checking Mac save..."
        BackupExistingPrep      = "[Step 2/5] Preparing to back up existing save..."
        LocalNewer              = "Warning: Local {0} save is newer than Mac save!"
        LocalTime               = "Local save time:"
        MacTime                 = "Mac save time:"
        ConfirmOverwrite        = "Are you sure you want to overwrite the newer local save with the older Mac save? (Y/N): "
        OperationCanceled       = "Operation canceled"
        CreateNewSaveDir        = "[Step 3/5] Creating new save package..."
        ImportingSaveFile       = "[Step 4/5] Importing save file..."
        VerifyingImport         = "[Step 5/5] Verifying import result..."
        ImportFailed            = "✗ Import failed - File copy error"
        ImportFailedSource      = "✗ Import failed - Source file not found"
        PressEnter              = "Press Enter to continue..."
        ExportWinTitle          = "Select Windows save type to export:"
        ExportManual            = "1) Export Manual Save"
        ExportAuto              = "2) Export Auto Save"
        ExportQuick             = "3) Export Quick Save"
        ExportAll               = "4) Export All Windows Saves"
        ExportAllWinPrep        = "Preparing to export all types of Windows saves..."
        ExportSteps             = "Export Steps:"
        ExportManualStep        = "1. Export Manual Save"
        ExportAutoStep          = "2. Export Auto Save"
        ExportQuickStep         = "3. Export Quick Save"
        CheckLocalSave          = "Checking local save"
        ExportingSave           = "Exporting save"
        CreateMetadata          = "Creating metadata"
        ExportSuccess           = "✓ {0} export successful"
        ExportFailedLocal       = "✗ {0} export failed - Local save not found"
        BatchExportComplete     = "Batch export complete: Successfully exported {0}/{1} save types"
        ExportWinSavePrep       = "Preparing to export Windows {0} save..."
        CheckLocalSaveStep      = "1. Check local save"
        ExportSaveFile          = "2. Export save file"
        CreateMetadataStep      = "3. Create metadata"
        VerifyExport            = "4. Verify export result"
        ExportFailed            = "✗ Export failed - Local save not found"
        SyncLatestTitle         = "Warning: One-click sync may result in save loss, are you sure you want to continue? (Y/N): "
        SyncLatestStart         = "Starting one-click sync of latest saves..."
        LocalNewerExporting     = "Local {0} save is newer, exporting..."
        SyncNewerImporting      = "{0} save in sync folder is newer, importing..."
        SaveIsLatest            = "{0} save is already up to date"
        SyncComplete            = "One-click sync complete"
        MenuTitle               = "Available Operations:"
        MenuImport              = "1) Import Mac Save"
        MenuExport              = "2) Export Windows Save"
        MenuSync                = "3) One-Click Sync Latest Save (Not Recommended)"
        MenuExit                = "4) Exit Program"
        MenuPrompt              = "Select an operation (1-4): "
        ProgramExit             = "Program exited"
        ProgressTitle           = "Import Progress:"
        # 新增翻译
        NoSteamFoldersFound     = "No Death Stranding save folders found. Please make sure the game is installed and has been run at least once."
        MultipleSteamFolders    = "Found multiple possible save folders. Please select the correct Steam ID:"
        SelectChoice            = "Enter your choice"
        SavePathNotFound        = "Death Stranding save path not found: {0}"
        GameExecutablePath      = "Please enter the Death Stranding game executable path"
        GamePathHint1           = "Tip: In Steam, right-click on the game -> Properties -> Local Files -> Browse..."
        GamePathHint2           = "Typical path: C:\\Program Files (x86)\\Steam\\steamapps\\common\\DEATH STRANDING DIRECTORS CUT\\ds.exe"
        EnterGamePath           = "Enter the game executable path"
        InvalidPathUsingDefault = "Invalid path, will use default settings"
        CannotDeterminePath     = "Cannot determine save folder path, some functions may not work properly"
        GameExecutableNotFound  = "Game executable not found"
        GameExeRestored         = "Game executable restored successfully"
        GameExeRestoreFailed    = "Failed to restore game executable"
        BackupNotFound          = "Backup not found"
        BackingUpGameExe        = "Backing up game executable"
        BackupFailed            = "Failed to backup game executable"
        ReadingGameExe          = "Reading game executable"
        ReadExeFailed           = "Failed to read game executable"
        PatternFound            = "Pattern found at offset"
        GameExePatched          = "Game executable patched successfully"
        PatchFailed             = "Failed to patch game executable"
        PatternNotFound         = "Pattern not found in game executable"
        AlreadyPatched          = "Game executable is already patched"
        WaitingGameStart        = "Waiting for game to start"
        GameStarted             = "Game started"
        WaitingGameEnd          = "Waiting for game to end"
        GameClosed              = "Game closed"
        PatchGamePrompt         = "Do you want to patch the game executable to bypass save corruption verification? (Y/N): "
        GamePathRequired        = "Game executable path is required to patch the game"
        PatchSuccess            = "Game executable patched successfully"
        StartGamePrompt         = "Do you want to start the game now? (Y/N): "
        StartingGame            = "Starting game..."
        RestoreOptions          = "Game has closed. Do you want to restore the original game executable?"
        RestoreOption1          = "Yes, restore the original game executable"
        RestoreOption2          = "No, keep the modified game executable"
        EnterChoice             = "Enter your choice (1 or 2): "
        RestoreComplete         = "Original game executable restored successfully"
        KeepingModified         = "Keeping the modified game executable"
        StartGameFailed         = "Failed to start the game"
    }
    "zh" = @{
        Title                   = "Death Stranding 存档同步工具"
        Device                  = "当前设备: Windows"
        SaveType                = "存档类型"
        LocalSave               = "本地存档"
        WinSync                 = "Windows同步"
        MacSync                 = "Mac同步"
        None                    = "无"
        NoSave                  = "无存档"
        FileName                = "└─文件名"
        ManualSave              = "手动存档"
        AutoSave                = "自动存档"
        QuickSave               = "快速存档"
        ImportMacTitle          = "请选择要导入的Mac存档类型："
        ImportManual            = "1) 导入手动存档"
        ImportAuto              = "2) 导入自动存档"
        ImportQuick             = "3) 导入快速存档"
        ImportAll               = "4) 导入全部Mac存档"
        ReturnToMenu            = "5) 返回主菜单"
        InvalidChoice           = "无效的选择"
        ImportAllMacPrep        = "准备导入所有类型的Mac存档..."
        ImportSteps             = "导入步骤："
        ImportManualStep        = "1. 导入手动存档"
        ImportAutoStep          = "2. 导入自动存档"
        ImportQuickStep         = "3. 导入快速存档"
        Processing              = "====== 正在处理{0} ({1}/{2}) ======"
        CheckLocalDir           = "检查并创建本地存档目录"
        SourceNotFound          = "✗ {0}导入失败 - 未找到源文件"
        BackupOriginal          = "备份原有存档"
        CopySave                = "复制存档"
        ImportSuccess           = "✓ {0}导入成功"
        BatchImportComplete     = "批量导入完成：成功导入 {0}/{1} 种类型的存档"
        ImportMacSavePrep       = "准备导入Mac {0} 存档..."
        CheckMacSave            = "1. 检查Mac存档"
        BackupExisting          = "2. 备份现有存档"
        CreateNewSave           = "3. 创建新存档包"
        ImportSaveFile          = "4. 导入存档文件"
        VerifyImport            = "5. 验证导入结果"
        CheckSource             = "[步骤 1/5] 检查Mac存档..."
        BackupExistingPrep      = "[步骤 2/5] 准备备份现有存档..."
        LocalNewer              = "警告：本地{0}存档比Mac存档新！"
        LocalTime               = "本地存档时间："
        MacTime                 = "Mac存档时间："
        ConfirmOverwrite        = "确定要用旧的Mac存档覆盖较新的本地存档吗？(Y/N): "
        OperationCanceled       = "操作已取消"
        CreateNewSaveDir        = "[步骤 3/5] 创建新存档包..."
        ImportingSaveFile       = "[步骤 4/5] 导入存档文件..."
        VerifyingImport         = "[步骤 5/5] 验证导入结果..."
        ImportFailed            = "✗ 导入失败 - 文件复制错误"
        ImportFailedSource      = "✗ 导入失败 - 未找到源文件"
        PressEnter              = "按Enter键继续..."
        ExportWinTitle          = "请选择要导出的Windows存档类型："
        ExportManual            = "1) 导出手动存档"
        ExportAuto              = "2) 导出自动存档"
        ExportQuick             = "3) 导出快速存档"
        ExportAll               = "4) 导出全部Windows存档"
        ExportAllWinPrep        = "准备导出所有类型的Windows存档..."
        ExportSteps             = "导出步骤："
        ExportManualStep        = "1. 导出手动存档"
        ExportAutoStep          = "2. 导出自动存档"
        ExportQuickStep         = "3. 导出快速存档"
        CheckLocalSave          = "检查本地存档"
        ExportingSave           = "导出存档"
        CreateMetadata          = "创建元数据"
        ExportSuccess           = "✓ {0}导出成功"
        ExportFailedLocal       = "✗ {0}导出失败 - 未找到本地存档"
        BatchExportComplete     = "批量导出完成：成功导出 {0}/{1} 种类型的存档"
        ExportWinSavePrep       = "准备导出Windows {0} 存档..."
        CheckLocalSaveStep      = "1. 检查本地存档"
        ExportSaveFile          = "2. 导出存档文件"
        CreateMetadataStep      = "3. 创建元数据"
        VerifyExport            = "4. 验证导出结果"
        ExportFailed            = "✗ 导出失败 - 未找到本地存档"
        SyncLatestTitle         = "警告：一键同步可能导致存档丢失，确定要继续吗？(Y/N): "
        SyncLatestStart         = "开始一键同步最新存档..."
        LocalNewerExporting     = "本地{0}存档较新，正在导出..."
        SyncNewerImporting      = "同步文件夹中{0}存档较新，正在导入..."
        SaveIsLatest            = "{0}存档已是最新"
        SyncComplete            = "一键同步完成"
        MenuTitle               = "可用操作："
        MenuImport              = "1) 导入Mac存档"
        MenuExport              = "2) 导出Windows存档"
        MenuSync                = "3) 一键同步最新存档（不推荐）"
        MenuExit                = "4) 退出程序"
        MenuPrompt              = "请选择操作 (1-4): "
        ProgramExit             = "程序退出"
        ProgressTitle           = "导入进度:"
        # 新增翻译
        NoSteamFoldersFound     = "未找到Death Stranding存档文件夹，请确认游戏是否已安装并运行过"
        MultipleSteamFolders    = "找到多个可能的存档文件夹，请选择正确的SteamID："
        SelectChoice            = "请输入选择"
        SavePathNotFound        = "未找到Death Stranding存档路径：{0}"
        GameExecutablePath      = "请输入Death Stranding游戏可执行文件的路径"
        GamePathHint1           = "提示：在Steam中右键点击游戏 -> 属性 -> 本地文件 -> 浏览..."
        GamePathHint2           = "通常路径类似：C:\\Program Files (x86)\\Steam\\steamapps\\common\\DEATH STRANDING DIRECTORS CUT\\ds.exe"
        EnterGamePath           = "请输入游戏可执行文件路径"
        InvalidPathUsingDefault = "路径无效，将使用默认设置"
        CannotDeterminePath     = "无法确定存档文件夹路径，部分功能可能无法正常工作"
        GameExecutableNotFound  = "未找到游戏可执行文件"
        GameExeRestored         = "游戏可执行文件已成功恢复"
        GameExeRestoreFailed    = "恢复游戏可执行文件失败"
        BackupNotFound          = "未找到备份"
        BackingUpGameExe        = "正在备份游戏可执行文件"
        BackupFailed            = "备份游戏可执行文件失败"
        ReadingGameExe          = "正在读取游戏可执行文件"
        ReadExeFailed           = "读取游戏可执行文件失败"
        PatternFound            = "在偏移量找到模式"
        GameExePatched          = "游戏可执行文件已成功修补"
        PatchFailed             = "修补游戏可执行文件失败"
        PatternNotFound         = "在游戏可执行文件中未找到模式"
        AlreadyPatched          = "游戏可执行文件已修补"
        WaitingGameStart        = "等待游戏启动"
        GameStarted             = "游戏已启动"
        WaitingGameEnd          = "等待游戏结束"
        GameClosed              = "游戏已关闭"
        PatchGamePrompt         = "是否要修补游戏可执行文件以绕过存档损坏验证？(Y/N): "
        GamePathRequired        = "需要游戏可执行文件路径以修补游戏"
        PatchSuccess            = "游戏可执行文件已成功修补"
        StartGamePrompt         = "是否要立即启动游戏？(Y/N): "
        StartingGame            = "正在启动游戏..."
        RestoreOptions          = "游戏已关闭。是否要恢复原始游戏可执行文件？"
        RestoreOption1          = "是，恢复原始游戏可执行文件"
        RestoreOption2          = "否，保留修改后的游戏可执行文件"
        EnterChoice             = "请输入选择 (1 或 2): "
        RestoreComplete         = "原始游戏可执行文件已成功恢复"
        KeepingModified         = "保留修改后的游戏可执行文件"
        StartGameFailed         = "启动游戏失败"
    }
}

# 获取翻译后的字符串 (Function to get translated strings)
function Get-Translation {
    param(
        [string]$Key,
        [string[]]$FormatArgs = $null
    )
    
    $translatedString = $translations[$language][$Key]
    
    if ($FormatArgs) {
        return [string]::Format($translatedString, $FormatArgs)
    }
    
    return $translatedString
}

# 获取游戏可执行文件路径
function Get-GameExecutablePath {
    if ($config.gameExecutablePath -and (Test-Path $config.gameExecutablePath)) {
        return $config.gameExecutablePath
    }
    
    Write-Host "`n" -ForegroundColor Yellow (Get-Translation "GameExecutablePath")
    Write-Host -ForegroundColor Cyan (Get-Translation "GamePathHint1")
    Write-Host -ForegroundColor Cyan (Get-Translation "GamePathHint2")
    
    $gamePath = Read-Host (Get-Translation "EnterGamePath")
    
    if (Test-Path $gamePath) {
        $config.gameExecutablePath = $gamePath
        Save-UserConfig $config
        return $gamePath
    }
    else {
        Write-Host -ForegroundColor Red (Get-Translation "InvalidPathUsingDefault")
        return ""
    }
}

# 初始化路径（放在语言选择之后）
$steamID = Find-SteamIDFolder
if ($steamID) {
    $windowsSavePath = Join-Path $defaultSavePath $steamID
    $gameExecutablePath = Get-GameExecutablePath
}
else {
    Write-Host -ForegroundColor Red (Get-Translation "CannotDeterminePath")
    $windowsSavePath = ""
    $gameExecutablePath = ""
}

# 显示进度条函数

function Show-Progress {

    param(

        [int]$Current,

        [int]$Total

    )

    $percent = [math]::Floor(($Current * 100) / $Total)

    $completed = [math]::Floor($percent / 2)

    $remaining = 50 - $completed



    Write-Host -NoNewline "${GREEN}$(Get-Translation ProgressTitle) ["

    Write-Host -NoNewline ("=" * $completed)


    if ($Current -lt $Total) {

        Write-Host -NoNewline ">"

        $remaining--

    }


    Write-Host -NoNewline (" " * $remaining)

    Write-Host -NoNewline "] ${percent}%${NC}"



    if ($Current -eq $Total) {

        Write-Host

    }

}



# 辅助函数

function Write-Log {

    param(

        [string]$Message,

        [string]$Type = "Info"

    )



    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    "$timestamp - $Message" | Out-File -Append -FilePath $logFile



    switch ($Type) {

        "Success" { Write-Host -ForegroundColor Green $Message }

        "Warning" { Write-Host -ForegroundColor Yellow $Message }

        "Error" { Write-Host -ForegroundColor Red $Message }

        Default { Write-Host $Message }

    }

}



function Get-Confirmation {

    param([string]$Prompt)



    Write-Host -ForegroundColor Yellow "$Prompt" -NoNewline

    $response = Read-Host

    if ($response -match "^[Yy]") {

        return $true

    }

    return $false

}

# 游戏EXE文件修改功能
function Patch-GameExecutable {
    param(
        [string]$ExecutablePath,
        [switch]$RestoreOriginal,
        [switch]$Force
    )

    if (-not (Test-Path $ExecutablePath)) {
        Write-Host -ForegroundColor Red (Get-Translation "GameExecutableNotFound")
        return $false
    }

    # 备份目录
    $gameBackupFolder = Join-Path $syncFolder "Windows\Saves\backups\game_exe"
    if (-not (Test-Path $gameBackupFolder)) {
        New-Item -ItemType Directory -Path $gameBackupFolder -Force | Out-Null
    }

    # 备份文件路径（添加时间戳避免覆盖）
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupExePath = Join-Path $gameBackupFolder "ds_$timestamp.exe.bak"
    
    if ($RestoreOriginal) {
        # 恢复原始文件
        if (Test-Path $backupExePath) {
            try {
                Copy-Item -Path $backupExePath -Destination $ExecutablePath -Force
                Write-Host -ForegroundColor Green (Get-Translation "GameExeRestored")
                return $true
            }
            catch {
                Write-Host -ForegroundColor Red (Get-Translation "GameExeRestoreFailed")
                Write-Host -ForegroundColor Red $_
                return $false
            }
        }
        else {
            Write-Host -ForegroundColor Red (Get-Translation "BackupNotFound")
            return $false
        }
    }

    # 检查是否已经被修补
    try {
        $currentBytes = [System.IO.File]::ReadAllBytes($ExecutablePath)
        $alreadyPatched = $false
        
        # 使用兼容的方式检查文件字节
        $bytes = New-Object byte[] 1MB
        $stream = [System.IO.File]::OpenRead($ExecutablePath)
        $bytesRead = $stream.Read($bytes, 0, 1MB)
        $stream.Close()
        
        # 检查前两个字节是否为修补后的值
        if ($bytes[0] -eq 0xEB -and $bytes[1] -eq 0x05) {
            Write-Host -ForegroundColor Yellow (Get-Translation "AlreadyPatched")
            return $true
        }
    }
    catch {
        Write-Host -ForegroundColor Red "Error checking patch status"
        Write-Host -ForegroundColor Red $_
        return $false
    }

    # 修改EXE文件前先备份
    try {
        Write-Host -ForegroundColor Cyan (Get-Translation "BackingUpGameExe")
        Copy-Item -Path $ExecutablePath -Destination $backupExePath -Force
    }
    catch {
        Write-Host -ForegroundColor Red (Get-Translation "BackupFailed")
        Write-Host -ForegroundColor Red $_
        return $false
    }

    # 读取文件字节
    try {
        Write-Host -ForegroundColor Cyan (Get-Translation "ReadingGameExe")
        $bytes = [System.IO.File]::ReadAllBytes($ExecutablePath)
        $totalSize = $bytes.Length
        Write-Host "Total file size: $($totalSize/1MB) MB"
    }
    catch {
        Write-Host -ForegroundColor Red (Get-Translation "ReadExeFailed")
        Write-Host -ForegroundColor Red $_
        return $false
    }

    # 定义多个可能的字节序列模式及其对应的替换值
    $patterns = @(
        @{
            Pattern     = [byte[]]@(0x75, 0x05, 0x41, 0xC6, 0x46, 0x3A, 0x11, 0x48, 0x8D, 0x8D)
            Replacement = [byte[]]@(0xEB, 0x05, 0x41, 0xC6, 0x46, 0x3A, 0x11, 0x48, 0x8D, 0x8D)
        }
    )

    $foundOffsets = @()
    $successfulPatches = 0
    $timeout = [System.Diagnostics.Stopwatch]::StartNew()

    # 搜索匹配
    Write-Host "Searching for pattern..." -NoNewline
    $lastProgress = 0

    # 简单的单字节搜索
    :patternLoop foreach ($patternSet in $patterns) {
        $pattern = $patternSet.Pattern
        $replacement = $patternSet.Replacement
        
        for ($i = 0; $i -lt ($bytes.Length - $pattern.Length); $i++) {
            # 显示进度
            $progress = [math]::Floor(($i / $bytes.Length) * 100)
            if ($progress -gt $lastProgress) {
                Write-Host "`rSearching... $progress%" -NoNewline
                $lastProgress = $progress
            }

            # 超时检查（90秒）
            if ($timeout.Elapsed.TotalSeconds -gt 90) {
                Write-Host "`nSearch timeout after 90 seconds"
                return $false
            }

            # 检查第一个字节是否匹配，如果不匹配直接跳过
            if ($bytes[$i] -eq $pattern[0]) {
                $match = $true
                # 检查剩余字节
                for ($j = 1; $j -lt $pattern.Length; $j++) {
                    if ($bytes[$i + $j] -ne $pattern[$j]) {
                        $match = $false
                        break
                    }
                }
                
                if ($match) {
                    Write-Host "`rFound pattern at offset: 0x$($i.ToString('X8'))"
                    $foundOffsets += @{
                        Offset      = $i
                        Pattern     = $pattern
                        Replacement = $replacement
                    }
                    break patternLoop  # 找到第一个匹配就退出
                }
            }
        }
    }

    Write-Host "`rSearch complete! Found $($foundOffsets.Count) matches."


    if ($foundOffsets.Count -gt 0) {
        Write-Host -ForegroundColor Yellow "Found $($foundOffsets.Count) potential patch locations"
    
        foreach ($offset in $foundOffsets) {
            Write-Host -ForegroundColor Green "Applying patch at offset: $($offset.Offset)"
        
            # 应用补丁
            for ($j = 0; $j -lt $offset.Replacement.Length; $j++) {
                $bytes[$offset.Offset + $j] = $offset.Replacement[$j]
            }
        
            $successfulPatches++
        }

        # 保存修改后的文件
        try {
            [System.IO.File]::WriteAllBytes($ExecutablePath, $bytes)
            Write-Host -ForegroundColor Green "Successfully patched $successfulPatches locations"
            return $true
        }
        catch {
            Write-Host -ForegroundColor Red "Failed to save patched file"
            Write-Host -ForegroundColor Red $_
            if (Get-Confirmation "Would you like to restore from backup? (Y/N): ") {
                Copy-Item -Path $backupExePath -Destination $ExecutablePath -Force
                Write-Host -ForegroundColor Green "Restored from backup"
            }
            return $false
        }
    }
    else {
        Write-Host -ForegroundColor Red (Get-Translation "PatternNotFound")
        return $false
    }
}

# 监控游戏进程
function Wait-GameProcess {
    param(
        [string]$ExecutablePath
    )

    $exeName = Split-Path $ExecutablePath -Leaf

    # 等待游戏进程启动
    Write-Host -ForegroundColor Cyan (Get-Translation "WaitingGameStart")
    $gameStarted = $false
    $gameProcess = $null

    while (-not $gameStarted) {
        $gameProcess = Get-Process | Where-Object { $_.Name -eq $exeName.Replace('.exe', '') -or $_.Name -eq "ds" } -ErrorAction SilentlyContinue
        if ($gameProcess) {
            $gameStarted = $true
            Write-Host -ForegroundColor Green (Get-Translation "GameStarted")
        }
        else {
            Start-Sleep -Seconds 1
            Write-Host "." -NoNewline
        }
    }

    # 等待游戏进程结束
    Write-Host -ForegroundColor Cyan (Get-Translation "WaitingGameEnd")
    while ($gameProcess -and -not $gameProcess.HasExited) {
        Start-Sleep -Seconds 2
        $gameProcess.Refresh()
    }

    Write-Host -ForegroundColor Green (Get-Translation "GameClosed")
    return $true
}

# 导入 Mac 存档并提供修改游戏选项
function Import-MacSaveWithPatch {
    param(
        [string]$SaveType
    )

    $translatedSaveType = switch ($SaveType) {
        "manualsave" { Get-Translation "ManualSave" }
        "autosave" { Get-Translation "AutoSave" }
        "quicksave" { Get-Translation "QuickSave" }
    }

    # 初始化步骤
    Write-Host "`n${CYAN}$(Get-Translation ImportMacSavePrep -f $translatedSaveType)${NC}"

    Write-Host "`n${WHITE}$(Get-Translation ImportSteps)${NC}"
    Write-Host "${GREEN}$(Get-Translation CheckMacSave)${NC}"
    Write-Host "${GREEN}$(Get-Translation BackupExisting)${NC}"
    Write-Host "${GREEN}$(Get-Translation CreateNewSave)${NC}"
    Write-Host "${GREEN}$(Get-Translation ImportSaveFile)${NC}"
    Write-Host "${GREEN}$(Get-Translation VerifyImport)${NC}`n"

    # 检查并创建本地存档目录
    $localSaveDir = Join-Path $windowsSavePath ($SaveType + "0")
    if (-not (Test-Path $localSaveDir)) {
        Write-Host "${GRAY}$(Get-Translation CheckLocalDir)...${NC}"
        New-Item -ItemType Directory -Path $localSaveDir -Force | Out-Null
    }

    # 步骤1：检查源文件
    Write-Host "${CYAN}$(Get-Translation CheckSource)${NC}"
    Show-Progress 1 5

    $macSavesFolder = Join-Path $syncFolder "macOS\Saves"
    # 查找匹配的Mac存档文件(支持不同编号)
    $sourceDat = Get-ChildItem -Path $macSavesFolder -Filter "$SaveType*_mac.dat" -File | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1 -ExpandProperty FullName

    if ($sourceDat -and (Test-Path $sourceDat)) {
        Start-Sleep -Milliseconds 500

        # 步骤2：检查并备份现有存档
        Write-Host "`n${CYAN}$(Get-Translation BackupExistingPrep)${NC}"
        Show-Progress 2 5
    
        $targetFile = Join-Path $localSaveDir "checkpoint.dat"

        # 比较版本
        if (Test-Path $targetFile) {
            $localTime = (Get-Item $targetFile).LastWriteTime
            $sourceTime = (Get-Item $sourceDat).LastWriteTime

            if ($localTime -gt $sourceTime) {
                Write-Host "`n${YELLOW}$(Get-Translation LocalNewer -f $translatedSaveType)${NC}"
                Write-Host "${WHITE}$(Get-Translation LocalTime)${NC}$($localTime.ToString('yyyy-MM-dd HH:mm:ss'))"
                Write-Host "${WHITE}$(Get-Translation MacTime)${NC}$($sourceTime.ToString('yyyy-MM-dd HH:mm:ss'))"

                if (-not (Get-Confirmation "$(Get-Translation ConfirmOverwrite)")) {
                    Write-Host "`n${YELLOW}$(Get-Translation OperationCanceled)${NC}"
                    return
                }
            }

            Write-Host "${GRAY}$(Get-Translation BackupOriginal)...${NC}"
            $backupDir = Join-Path $backupFolder (Get-Date -Format "yyyyMMdd_HHmmss")
            if (-not (Test-Path $backupDir)) {
                New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            }
            Copy-Item $targetFile -Destination (Join-Path $backupDir ($saveType + "_checkpoint.dat")) -Force
        }
    
        Start-Sleep -Milliseconds 500

        # 步骤3：创建新存档目录
        Write-Host "`n${CYAN}$(Get-Translation CreateNewSaveDir)${NC}"
        Show-Progress 3 5
    
        if (-not (Test-Path $localSaveDir)) {
            New-Item -ItemType Directory -Path $localSaveDir -Force | Out-Null
        }
    
        Start-Sleep -Milliseconds 500

        # 步骤4：导入存档
        Write-Host "`n${CYAN}$(Get-Translation ImportingSaveFile)${NC}"
        Show-Progress 4 5
    
        Write-Host "${GRAY}$(Get-Translation CopySave)...${NC}"
        Copy-Item $sourceDat -Destination $targetFile -Force
    
        Start-Sleep -Milliseconds 500

        # 步骤5：验证结果
        Write-Host "`n${CYAN}$(Get-Translation VerifyingImport)${NC}"
        Show-Progress 5 5
    
        if (Test-Path $targetFile) {
            Write-Host "`n${BRIGHT_GREEN}$(Get-Translation ImportSuccess -f $translatedSaveType)${NC}"
        
            # 询问用户是否要修补游戏
            if (Get-Confirmation (Get-Translation "PatchGamePrompt")) {
                if (-not $config.gameExecutablePath -or -not (Test-Path $config.gameExecutablePath)) {
                    $config.gameExecutablePath = Get-GameExecutablePath
                    if (-not $config.gameExecutablePath -or -not (Test-Path $config.gameExecutablePath)) {
                        Write-Host -ForegroundColor Red (Get-Translation "GamePathRequired")
                        return
                    }
                }
            
                # 修改游戏EXE
                if (Patch-GameExecutable -ExecutablePath $config.gameExecutablePath) {
                    Write-Host -ForegroundColor Green (Get-Translation "PatchSuccess")
                
                    # 询问用户是否立即启动游戏
                    if (Get-Confirmation (Get-Translation "StartGamePrompt")) {
                        Write-Host -ForegroundColor Cyan (Get-Translation "StartingGame")
                    
                        # 启动游戏
                        try {
                            Start-Process $config.gameExecutablePath
                        
                            # 等待游戏进程结束
                            $gameEnded = Wait-GameProcess -ExecutablePath $config.gameExecutablePath
                        
                            if ($gameEnded) {
                                Write-Host -ForegroundColor Yellow (Get-Translation "RestoreOptions")
                                Write-Host -ForegroundColor White "1) $(Get-Translation RestoreOption1)"
                                Write-Host -ForegroundColor White "2) $(Get-Translation RestoreOption2)"
                            
                                $restoreChoice = Read-Host (Get-Translation "EnterChoice")
                            
                                if ($restoreChoice -eq "1") {
                                    if (Patch-GameExecutable -ExecutablePath $config.gameExecutablePath -RestoreOriginal) {
                                        Write-Host -ForegroundColor Green (Get-Translation "RestoreComplete")
                                    }
                                }
                                else {
                                    Write-Host -ForegroundColor Yellow (Get-Translation "KeepingModified")
                                }
                            }
                        }
                        catch {
                            Write-Host -ForegroundColor Red (Get-Translation "StartGameFailed")
                            Write-Host -ForegroundColor Red $_
                        }
                    }
                }
                else {
                    Write-Host -ForegroundColor Red (Get-Translation "PatchFailed")
                }
            }
        }
        else {
            Write-Host "`n${RED}$(Get-Translation ImportFailed)${NC}"
        }
    }
    else {
        Write-Host "`n${RED}$(Get-Translation ImportFailedSource)${NC}"
    }

    Write-Host "`n${YELLOW}$(Get-Translation PressEnter)${NC}"
    Read-Host
}



# 存档操作

function Get-SaveInfo {
    param(
        [string]$SaveType,
        [string]$SavePath,
        [switch]$IsSyncFolder
    )

    if ($IsSyncFolder) {
        # 如果是同步文件夹，直接查找.dat文件
        $pattern = $SaveType + "1_win.dat"
        $saveFile = Get-ChildItem -Path $SavePath -Filter $pattern -File -ErrorAction SilentlyContinue | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 1

        if ($saveFile) {
            return [PSCustomObject]@{
                Name          = $saveFile.Name
                LastWriteTime = $saveFile.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            }
        }
    }
    else {
        # 检查SavePath是否存在
        if (-not (Test-Path $SavePath)) {
            Write-Log "路径不存在: $SavePath" "Warning"
            return [PSCustomObject]@{
                Name          = "NONE"
                LastWriteTime = "0"
            }
        }
    
        # 如果是游戏存档文件夹，直接检查指定的保存文件夹（确保存在时）
        $saveDir = Join-Path $SavePath ($SaveType + "0")
        $checkpointPath = Join-Path $saveDir "checkpoint.dat"

        if (Test-Path $checkpointPath) {
            $checkpointFile = Get-Item $checkpointPath
            return [PSCustomObject]@{
                Name          = (Split-Path -Leaf (Split-Path -Parent $checkpointPath))
                LastWriteTime = $checkpointFile.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            }
        }
    
        # 如果没有找到默认编号的存档文件夹，搜索所有可能的存档文件夹
        $folderPatterns = @(
            "$SaveType[0-9]*" # 带数字的文件夹
        )
    
        $allSaves = @()
    
        foreach ($pattern in $folderPatterns) {
            $folders = Get-ChildItem -Path $SavePath -Directory -Filter $pattern -ErrorAction SilentlyContinue
        
            foreach ($folder in $folders) {
                $checkpointPath = Join-Path $folder.FullName "checkpoint.dat"
                if (Test-Path $checkpointPath) {
                    $checkpointFile = Get-Item $checkpointPath
                    $allSaves += [PSCustomObject]@{
                        Name          = $folder.Name
                        LastWriteTime = $checkpointFile.LastWriteTime
                        FullPath      = $checkpointPath
                    }
                }
            }
        }
    
        # 获取最新的存档
        $latestSave = $allSaves | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
        if ($latestSave) {
            return [PSCustomObject]@{
                Name          = $latestSave.Name
                LastWriteTime = $latestSave.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            }
        }
    }

    return [PSCustomObject]@{
        Name          = "NONE"
        LastWriteTime = "0"
    }
}

function Get-MacSaveInfo {

    param([string]$SaveType)



    $pattern = switch ($SaveType) {

        "manualsave" { "manualsave*_mac.dat" }

        "autosave" { "autosave*_mac.dat" }

        "quicksave" { "quicksave*_mac.dat" }

    }

    $macSavesFolder = Join-Path $syncFolder "macOS\Saves"

    $latestMacSave = Get-ChildItem -Path $macSavesFolder -Filter $pattern -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1



    if ($latestMacSave) {

        return [PSCustomObject]@{

            Name          = $latestMacSave.Name

            LastWriteTime = $latestMacSave.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")

        }

    }



    return [PSCustomObject]@{

        Name          = "NONE"

        LastWriteTime = "0"

    }

}



# 界面显示

function Show-SaveStatus {

    Clear-Host

    Write-Host "${CYAN}$($BOLD)╔═════════ $(Get-Translation Title) ═════════╗${NC}"

    Write-Host "${CYAN}$($BOLD)║ $(Get-Translation Device) ║${NC}"

    Write-Host "${CYAN}$($BOLD)╚══════════════════════════════════════════════════╝${NC}"

    Write-Host ""



    # 表格头部（调整宽度以对齐框架）

    $headerFormat = "{0,-15} {1,-25} {2,-3} {3,-25} {4,-3} {5,-25}"

    $header = $headerFormat -f (Get-Translation SaveType), (Get-Translation LocalSave), " ", (Get-Translation WinSync), " ", (Get-Translation MacSync)

    $padding = " " * [Math]::Max(0, (95 - $header.Length) / 2)

    Write-Host ($padding + $header) -ForegroundColor Cyan

    Draw-Line "═"



    # 遍历存档类型

    $saveTypes = @((Get-Translation ManualSave), (Get-Translation AutoSave), (Get-Translation QuickSave))

    $savePrefixes = @("manualsave", "autosave", "quicksave")



    for ($i = 0; $i -lt $saveTypes.Count; $i++) {

        # 获取存档信息

        $winLocalInfo = Get-SaveInfo -SaveType $savePrefixes[$i] -SavePath $windowsSavePath

        $winSyncInfo = Get-SaveInfo -SaveType $savePrefixes[$i] -SavePath "$syncSavesFolder" -IsSyncFolder

        $macSyncInfo = Get-MacSaveInfo -SaveType ($savePrefixes[$i])



        # 提取时间戳

        $winLocalTime = if ($winLocalInfo.LastWriteTime -ne "0") { $winLocalInfo.LastWriteTime } else { "0" }

        $winSyncTime = if ($winSyncInfo.LastWriteTime -ne "0") { $winSyncInfo.LastWriteTime } else { "0" }

        $macSyncTime = if ($macSyncInfo.LastWriteTime -ne "0") { $macSyncInfo.LastWriteTime } else { "0" }



        # 找出最新时间

        $maxTime = @($winLocalTime, $winSyncTime, $macSyncTime) | Where-Object { $_ -ne "0" } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum



        # 显示箭头

        $arrow1 = Show-SyncArrow $winLocalTime $winSyncTime "right"

        $arrow2 = Show-SyncArrow $macSyncTime $winSyncTime "left"



        # 显示时间

        Write-Host -NoNewline ("{0,-15}" -f $saveTypes[$i]) -ForegroundColor White

        Write-Host -NoNewline ("{0,-25} {1,3} " -f (Format-TimeColored $winLocalTime $maxTime), $arrow1)

        Write-Host -NoNewline ("{0,-25} {1,3} " -f (Format-TimeColored $winSyncTime $maxTime), $arrow2)

        Write-Host ("{0,-25}" -f (Format-TimeColored $macSyncTime $maxTime))



        # 显示文件名（如果存在）

        if ($winLocalInfo.Name -ne "NONE" -or $winSyncInfo.Name -ne "NONE" -or $macSyncInfo.Name -ne "NONE") {

            Write-Host -NoNewline ("{0,-15}" -f (Get-Translation FileName)) -ForegroundColor Gray

            Write-Host ("{0,-25} {1,3} {2,-25} {3,3} {4,-25}" -f $winLocalInfo.Name, " ", $winSyncInfo.Name, " ", $macSyncInfo.Name)

        }



        # 在最后一行之前添加分隔线

        if ($i -lt ($saveTypes.Count - 1)) {

            Draw-Line "─"

        }

    }



    Draw-Line "═"

}



function Draw-Line {

    param(

        [string]$Char = "─"

    )



    $line = $Char * 95

    Write-Host $line -ForegroundColor Blue

}



function Format-TimeColored {

    param(

        [string]$Timestamp,

        [string]$MaxTime

    )



    if ($Timestamp -eq "0") {

        return ("{0}$(Get-Translation NoSave){1}" -f $RED, $NC)

    }

    elseif ($Timestamp -eq $MaxTime) {

        return ("{0}{1}{2}" -f $BRIGHT_GREEN, $Timestamp, $NC)

    }

    else {

        return ("{0}{1}{2}" -f $YELLOW, $Timestamp, $NC)

    }

}



function Show-SyncArrow {
    param(
        [string]$Time1,
        [string]$Time2,
        [string]$Direction
    )

    if ($Time1 -eq "0" -or $Time2 -eq "0") {
        return " "
    }

    if ($Time1 -gt $Time2) {
        if ($Direction -eq "right") {
            return ("{0} {1} {2}" -f $YELLOW, $ARROW, $NC)
        }
        else {
            return " "
        }
    }
    elseif ($Time1 -lt $Time2) {
        if ($Direction -eq "left") {
            return ("{0} {1} {2}" -f $YELLOW, $ARROW, $NC)
        }
        else {
            return " "
        }
    }
    else {
        return " "
    }
}

# 导入 Mac 存档
function Import-MacSave {
    Write-Host "`n${YELLOW}$(Get-Translation ImportMacTitle)${NC}" -ForegroundColor Yellow
    Write-Host "$(Get-Translation ImportManual)" -ForegroundColor White
    Write-Host "$(Get-Translation ImportAuto)" -ForegroundColor White
    Write-Host "$(Get-Translation ImportQuick)" -ForegroundColor White
    Write-Host "$(Get-Translation ImportAll)" -ForegroundColor White
    Write-Host "$(Get-Translation ReturnToMenu)" -ForegroundColor White
    $choice = Read-Host "`n$(Get-Translation MenuPrompt)"
    switch ($choice) {
        "1" { 
            Import-MacSaveWithPatch -SaveType "manualsave"
        }
        "2" { 
            Import-MacSaveWithPatch -SaveType "autosave" 
        }
        "3" { 
            Import-MacSaveWithPatch -SaveType "quicksave"
        }
        "4" { 
            Write-Host "`n${CYAN}$(Get-Translation ImportAllMacPrep)${NC}"
            Write-Host "`n${WHITE}$(Get-Translation ImportSteps)${NC}"
            Write-Host "${GREEN}$(Get-Translation ImportManualStep)${NC}"
            Write-Host "${GREEN}$(Get-Translation ImportAutoStep)${NC}"
            Write-Host "${GREEN}$(Get-Translation ImportQuickStep)${NC}`n"
        
            $saveTypes = @("manualsave", "autosave", "quicksave")
            $saveNames = @((Get-Translation "ManualSave"), (Get-Translation "AutoSave"), (Get-Translation "QuickSave"))
            $successCount = 0
            $totalCount = $saveTypes.Count
        
            for ($i = 0; $i -lt $saveTypes.Count; $i++) {
                $currentSaveType = $saveTypes[$i]
                $translatedName = $saveNames[$i]
            
                Write-Host "`n${CYAN}$(Get-Translation Processing -f $translatedName, ($i + 1), $totalCount)${NC}"
                Import-MacSaveWithPatch -SaveType $currentSaveType
                $successCount++
            }
        
            Write-Host "`n${BRIGHT_GREEN}$(Get-Translation BatchImportComplete -f $successCount, $totalCount)${NC}"
        }
        "5" { return }
        default {
            Write-Log (Get-Translation InvalidChoice) "Error"
            return
        }
    }
}



# 在脚本末尾添加主循环
function Show-MainMenu {
    while ($true) {
        Clear-Host
        Show-SaveStatus
    
        Write-Host "`n${YELLOW}$(Get-Translation MenuTitle)${NC}"
        Write-Host "$(Get-Translation MenuImport)"
        Write-Host "$(Get-Translation MenuExport)"
        Write-Host "$(Get-Translation MenuSync)"
        Write-Host "$(Get-Translation MenuExit)"
    
        $choice = Read-Host "`n$(Get-Translation MenuPrompt)"
        switch ($choice) {
            "1" { Import-MacSave }
            "2" { Export-WindowsSave }
            "3" { Sync-LatestSave }
            "4" { 
                Write-Host "`n${GREEN}$(Get-Translation ProgramExit)${NC}"
                return 
            }
            default {
                Write-Log (Get-Translation InvalidChoice) "Error"
                Start-Sleep -Seconds 2
            }
        }
    }
}

# 启动主程序
Show-MainMenu

